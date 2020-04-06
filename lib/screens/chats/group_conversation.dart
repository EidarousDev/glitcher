import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/models/group_model.dart';
import 'package:glitcher/models/message_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/services/permissions_service.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:glitcher/widgets/chat_bubble.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:glitcher/widgets/image_overlay.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math' show Random;
import 'package:random_string/random_string.dart';

class GroupConversation extends StatefulWidget {
  final String groupId;

  GroupConversation({this.groupId});

  @override
  _GroupConversationState createState() =>
      _GroupConversationState(groupId: groupId);
}

class _GroupConversationState extends State<GroupConversation>
    with WidgetsBindingObserver {
  Timestamp firstVisibleGameSnapShot;
  String messageText;

  List<Message> _messages;

  TextEditingController messageController = TextEditingController();

  var seen = false;
  var _url;

  StreamSubscription<QuerySnapshot> messagesSubscription;

  ScrollController _scrollController = ScrollController();

  String groupId;
  Group group;

  Map<String, User> usersMap = {};

  var choices = ['Group Details', 'Members'];

  FocusScopeNode _focusNode = FocusScopeNode();

  bool _typing = false;

  FlutterAudioRecorder recorder;

  String recordTime;
  final formatter = new NumberFormat("##");

  _GroupConversationState({this.groupId});

  Future<String> _localPath() async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> _localFile() async {
//    final bytes = await _loadFileBytes(_url,
//        onError: (Exception exception) =>
//            print('_loadFile => exception $exception'));
    final path = await _localPath();
    print('path $path');
    var file = File('$path/glitcher_record.wav');

    //await file.writeAsBytes(bytes);
    return file;
  }

  void loadGroupData(String groupId) async {
    Group group;
    group = await DatabaseService.getGroupWithId(groupId);
    setState(() {
      this.group = group;
    });

    await getGroupUsersData();
  }

  void getGroupMessages() async {
    var messages = await DatabaseService.getGroupMessages(groupId);
    setState(() {
      this._messages = messages;

      if (messages.length >
          0) //TODO comment this line if prevMessages malfunction
        this.firstVisibleGameSnapShot = messages.last.timestamp;
    });
  }

  void getPrevGroupMessages() async {
    var messages;
    messages = await DatabaseService.getPrevGroupMessages(
        firstVisibleGameSnapShot, groupId);

    if (messages.length > 0) {
      setState(() {
        messages.forEach((element) => this._messages.add(element));
        this.firstVisibleGameSnapShot = messages.last.timestamp;
      });
    }
  }

  void listenToMessagesChanges() async {
    messagesSubscription = chatGroupsRef
        .document(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((querySnapshot) {
      querySnapshot.documentChanges.forEach((change) {
        if (change.type == DocumentChangeType.added) {
          if (_messages != null) {
            if (this.mounted) {
              setState(() {
                _messages.insert(0, Message.fromDoc(change.document));
              });
            }
          }
        }
      });
    });
  }

  String formatTimestamp(Timestamp timestamp) {
    var now = Timestamp.now().toDate();
    var date = new DateTime.fromMillisecondsSinceEpoch(
        timestamp.millisecondsSinceEpoch);
    var diff = now.difference(date);
    var time = '';

    if (diff.inSeconds <= 60) {
      time = 'now';
    } else if (diff.inMinutes > 0 && diff.inMinutes < 60) {
      if (diff.inMinutes == 1) {
        time = 'A minute ago';
      } else {
        time = diff.inMinutes.toString() + ' minutes ago';
      }
    } else if (diff.inHours > 0 && diff.inHours < 24) {
      if (diff.inHours == 1) {
        time = 'An hour ago';
      } else {
        time = diff.inHours.toString() + ' hours ago';
      }
    } else if (diff.inDays > 0 && diff.inDays < 7) {
      if (diff.inDays == 1) {
        time = 'Yesterday';
      } else {
        time = diff.inDays.toString() + ' DAYS AGO';
      }
    } else {
      if (diff.inDays == 7) {
        time = 'A WEEK AGO';
      } else {
        time = timestamp.toDate().toString();
      }
    }

    return time;
  }

  getGroupUsersData() async {
    List<Map<String, dynamic>> users = [];
    List<String> usersIds = [];
    QuerySnapshot usersSnapshot = await chatGroupsRef
        .document(groupId)
        .collection('users')
        .getDocuments();
    usersSnapshot.documents.forEach((doc) {
      users.add(doc.data);
      usersIds.add(doc.documentID);
    });

    for (String userId in usersIds) {
      User user = await DatabaseService.getUserWithId(userId);
      setState(() {
        this.usersMap.putIfAbsent(userId, () => user);
      });
    }
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // user returned to our app
      messagesSubscription.resume();
    } else if (state == AppLifecycleState.paused) {
      // app is inactive
      messagesSubscription.pause();
    } else if (state == AppLifecycleState.detached) {
      // app suspended (not used in iOS)
    }
  }

  RecordingStatus _currentStatus = RecordingStatus.Unset;
  Recording _current;

  static const tick = const Duration(milliseconds: 1000);

  initRecorder() async {
    File file = await _localFile();

    if (await file.exists()) {
      file.delete();
    }
    print('MyFile : ${file.path}');

    recorder = FlutterAudioRecorder(file.path); // .wav .aac .m4a
    await recorder.initialized;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getGroupMessages();
    listenToMessagesChanges();
    loadGroupData(groupId);

    initRecorder();

    _focusNode.addListener(_onFocusChange);

    ///Set up listener here
    _scrollController
      ..addListener(() {
        if (_scrollController.offset >=
                _scrollController.position.maxScrollExtent &&
            !_scrollController.position.outOfRange) {
          print('reached the bottom');
          getPrevGroupMessages();
        } else if (_scrollController.offset <=
                _scrollController.position.minScrollExtent &&
            !_scrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    messagesSubscription.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _focusNode.unfocus();
          _typing = false;
        });

        // if (!_focusNode.hasPrimaryFocus) {
        //   _focusNode.unfocus();
        // }
      },
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Constants.darkCardBG, Constants.darkBG])),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.keyboard_backspace,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: InkWell(
            child: Row(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(left: 0.0, right: 10.0),
                  child: group?.image != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(
                            group.image,
                          ),
                        )
                      : Container(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: 15.0),
                      Text(
                        group.name ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {},
          ),
          actions: <Widget>[
            PopupMenuButton<String>(
              elevation: 0,
              initialValue: choices[0],
              onCanceled: () {
                print('You have not chossed anything');
              },
              tooltip: 'This is tooltip',
              onSelected: _select,
              itemBuilder: (BuildContext context) {
                return choices.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            )
          ],
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: <Widget>[
              SizedBox(height: 10),
              _messages != null
                  ? Flexible(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        itemCount: _messages.length,
                        reverse: true,
                        itemBuilder: (BuildContext context, int index) {
                          Message msg = _messages[index];
                          return ChatBubble(
                            message: msg.message,
                            username: usersMap[msg.sender].username,
                            time: msg.timestamp != null
                                ? formatTimestamp(msg.timestamp)
                                : 'now',
                            type: msg.type,
                            replyText: null,
                            isMe: msg.sender == Constants.currentUserID,
                            isGroup: true,
                            isReply: false,
                            replyName: null,
                          );
                        },
                      ),
                    )
                  : Container(),
              Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0, bottom: 8),
                    child: Text(
                      seen ? 'seen' : '',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  //                height: 140,
                  decoration: BoxDecoration(
                    color: Constants.darkBG,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey[500],
                        offset: Offset(0.0, 1.5),
                        blurRadius: 4.0,
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    maxHeight: 190,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: ListTile(
                          leading: IconButton(
                            icon: Icon(
                              Icons.add,
                              color: Colors.white70,
                            ),
                            onPressed: () async{
                              File image = await AppUtil.chooseImage();

                              showDialog(
                                  barrierDismissible: true,
                                  child: Container(
                                    width: Sizes.sm_profile_image_w,
                                    height: Sizes.sm_profile_image_h,
                                    child: ImageOverlay(
                                      imageFile: image,
                                      btnText: 'Send',
                                      btnFunction: () async {
                                        _url = await AppUtil.uploadFile(image, context, 'image_messages/$groupId/' + randomAlphaNumeric(20));

                                        messageController.clear();
                                        await DatabaseService.sendGroupMessage(groupId, 'image', _url);

                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ),
                                  context: context);

                            },
                          ),
                          contentPadding: EdgeInsets.all(0),
                          title: _currentStatus != RecordingStatus.Recording
                              ? TextField(
                                  focusNode: _focusNode,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  controller: messageController,
                                  onChanged: (value) {
                                    messageText = value;
                                  },
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    color: Colors.white70,
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(10.0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5.0),
                                      borderSide: BorderSide(
                                        color: Constants.darkBG,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Constants.darkBG,
                                      ),
                                      borderRadius: BorderRadius.circular(5.0),
                                    ),
                                    hintText: "Write your message...",
                                    hintStyle: TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  maxLines: null,
                                )
                              : Text(formatter
                                      .format((int.parse(recordTime) ~/ 60))
                                      .toString() +
                                  ' : ' +
                                  (formatter.format(int.parse(recordTime) % 60))
                                      .toString()),
                          trailing: _typing
                              ? IconButton(
                                  icon: Icon(
                                    Icons.send,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () async {
                                    messageController.clear();
                                    await DatabaseService.sendGroupMessage(
                                        groupId, 'text', messageText);
                                  },
                                )
                              : GestureDetector(
                                  onLongPress: () async {
                                    bool isGranted = await PermissionsService()
                                        .requestMicrophonePermission(
                                            onPermissionDenied: () {
                                      print('Permission has been denied');
                                    });

                                    if (isGranted) {
                                      _start();
                                    } else {
                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text('Info'),
                                              content: Text(
                                                  'You must grant this microphone access to be able to use this feature.'),
                                              actions: <Widget>[
                                                MaterialButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text('OK'),
                                                )
                                              ],
                                            );
                                          });
                                    }
                                  },
                                  onLongPressEnd: (longPressDetails) async {
                                    var result = await recorder.stop();
                                    //_currentStatus = RecordingStatus.Stopped;
                                    print(result.path);
                                    File file = await _stop();

                                    AppUtil.uploadFile(file, context, 'group_voice_messages/$groupId/' + randomAlphaNumeric(20));

                                    await DatabaseService.sendGroupMessage(
                                        groupId, 'audio', _url);
                                  },
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.mic,
                                      color: Colors.white70,
                                    ),
                                    onPressed: null,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _select(String value) {
    switch (value) {
      case 'Members':
        Navigator.of(context)
            .pushNamed('group-members', arguments: {'groupId': groupId});
        break;

      case 'Group Details':
        Navigator.of(context)
            .pushNamed('group-details', arguments: {'groupId': groupId});
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _typing = true;
    } else {
      _focusNode.unfocus();
      _typing = false;
    }
  }

  _start() async {
    initRecorder();
    try {
      await recorder.start();
      var recording = await recorder.current(channel: 0);
      setState(() {
        _current = recording;
      });

      new Timer.periodic(tick, (Timer t) async {
        if (_currentStatus == RecordingStatus.Stopped) {
          t.cancel();
        }

        setState(() {
          recordTime = t.tick.toString();
          _currentStatus = RecordingStatus.Recording;
        });
        print('cyrrent ${recording.status}');
      });
    } catch (e) {
      print(e);
    }
  }

  Future<File> _stop() async {
    var result = await recorder.stop();
    print("Stop recording: ${result.path} + ${result.status}");
    print("Stop recording: ${result.duration}");
    File file = File(result.path);
    print("File length: ${await file.length()}");
    setState(() {
      _currentStatus = result.status;
    });

    return file;
  }

  Future<Uint8List> _loadFileBytes(String url, {OnError onError}) async {
    Uint8List bytes;
    try {
      bytes = await readBytes(url);
    } on ClientException {
      rethrow;
    }
    return bytes;
  }
}
