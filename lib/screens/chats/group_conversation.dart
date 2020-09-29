import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/models/group_model.dart';
import 'package:glitcher/models/message_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/audio_recorder.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/permissions_service.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/bottom_sheets/profile_image_edit_bottom_sheet.dart';
import 'package:glitcher/widgets/caching_image.dart';
import 'package:glitcher/widgets/chat_bubble.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';
import 'package:glitcher/widgets/image_overlay.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:random_string/random_string.dart';
import 'package:path/path.dart' as path;

class GroupConversation extends StatefulWidget {
  final String groupId;
  final _GroupConversationState state = _GroupConversationState();
  GroupConversation({this.groupId});

  @override
  _GroupConversationState createState() => state;

  updateRecordTime(String recordTime) {
    print('recordTime: $recordTime');
    state.updateRecordTime(recordTime);
  }
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

  Group group;

  Map<String, User> usersMap = {};

  var choices = ['Group Details', 'Members'];

  FocusScopeNode _focusNode = FocusScopeNode();

  bool _typing = false;

  String recordTime = 'recording...';
  final formatter = new NumberFormat("##");

  var _currentStatus;

  AudioRecorder recorder;

  List<String> groupMembersIds = [];

  bool isMicrophoneGranted = false;

  _GroupConversationState();

  Future<String> _localPath() async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> _localFile() async {
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
    var messages = await DatabaseService.getGroupMessages(widget.groupId);
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
        firstVisibleGameSnapShot, widget.groupId);

    if (messages.length > 0) {
      setState(() {
        messages.forEach((element) => this._messages.add(element));
        this.firstVisibleGameSnapShot = messages.last.timestamp;
      });
    }
  }

  void listenToMessagesChanges() async {
    messagesSubscription = chatGroupsRef
        .document(widget.groupId)
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

  getGroupUsersData() async {
    List<Map<String, dynamic>> users = [];
    List<String> usersIds = [];
    QuerySnapshot usersSnapshot = await chatGroupsRef
        .document(widget.groupId)
        .collection('users')
        .getDocuments();
    usersSnapshot.documents.forEach((doc) {
      users.add(doc.data);
      usersIds.add(doc.documentID);
    });

    print('member: ${usersIds[0]}');
    setState(() {
      groupMembersIds = usersIds;
    });

    for (String userId in usersIds) {
      User user = await DatabaseService.getUserWithId(userId, checkLocal: true);
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

  initRecorder() async {
    recorder = AudioRecorder();
    await recorder.init();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getGroupMessages();
    listenToMessagesChanges();
    loadGroupData(widget.groupId);
    //initRecorder();
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
    return WillPopScope(
      onWillPop: _onBackBtnPressed,
      child: GestureDetector(
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
            flexibleSpace: gradientAppBar(),
            leading: IconButton(
              icon: Icon(
                Icons.keyboard_backspace,
              ),
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('/chats'),
            ),
            titleSpacing: 0,
            title: InkWell(
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(left: 0.0, right: 10.0),
                    child: CacheThisImage(
                      imageUrl: group?.image,
                      imageShape: BoxShape.circle,
                      width: 40.0,
                      height: 40.0,
                      defaultAssetImage: Strings.default_group_image,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          group?.name ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                onCanceled: () {
                  print('You have not chosen anything');
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
                              username: usersMap[msg.sender]?.username,
                              time: msg.timestamp != null
                                  ? Functions.formatTimestamp(msg.timestamp)
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
                        style: TextStyle(
                            color: switchColor(Colors.black87, Colors.white70)),
                      ),
                    )),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    //                height: 140,
                    decoration: BoxDecoration(
                      color: switchColor(MyColors.lightBG, MyColors.darkBG),
                      boxShadow: [
                        BoxShadow(
                          color:
                              switchColor(Colors.grey[500], Colors.grey[500]),
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
                                Icons.image,
                                color: switchColor(
                                    MyColors.lightPrimary, Colors.white70),
                              ),
                              onPressed: () async {
                                ImageEditBottomSheet bottomSheet =
                                    ImageEditBottomSheet();
                                bottomSheet.optionIcon(context);
                                File image = await AppUtil.chooseImage(
                                    source: bottomSheet.choice);

                                showDialog(
                                    barrierDismissible: true,
                                    child: Container(
                                      width: Sizes.sm_profile_image_w,
                                      height: Sizes.sm_profile_image_h,
                                      child: ImageOverlay(
                                          imageFile: image,
                                          btnIcons: [
                                            Icons.send
                                          ],
                                          btnFunctions: [
                                            () async {
                                              _url = await AppUtil.uploadFile(
                                                  image,
                                                  context,
                                                  'group_chat_image_messages/${widget.groupId}/${randomAlphaNumeric(20)}${path.extension(image.path)}',
                                                  groupMembersIds:
                                                      groupMembersIds);

                                              messageController.clear();
                                              await DatabaseService
                                                  .sendGroupMessage(
                                                      widget.groupId,
                                                      'image',
                                                      _url);

                                              Navigator.of(context).pop();
                                            },
                                          ]),
                                    ),
                                    context: context);
                              },
                            ),
                            contentPadding: EdgeInsets.all(0),
                            title: _currentStatus != RecordingStatus.Recording
                                ? TextField(
                                    cursorColor: MyColors.darkPrimary,
                                    focusNode: _focusNode,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    controller: messageController,
                                    onChanged: (value) {
                                      messageText = value;
                                    },
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      color: switchColor(
                                          Colors.black54, Colors.white70),
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.all(10.0),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                        borderSide: BorderSide(
                                          color: MyColors.darkBG,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: MyColors.darkBG,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                      ),
                                      hintText: "Write your message...",
                                      hintStyle: TextStyle(
                                        fontSize: 15.0,
                                        color: switchColor(
                                            Colors.black12, Colors.white70),
                                      ),
                                    ),
                                    maxLines: null,
                                  )
//                              : Text(formatter
//                                      .format((int.parse(recordTime) ~/ 60))
//                                      .toString() +
//                                  ' : ' +
//                                  (formatter.format(int.parse(recordTime) % 60))
//                                      .toString()),
                                : Text(recordTime),
                            trailing: _typing
                                ? IconButton(
                                    icon: Icon(
                                      Icons.send,
                                      color: switchColor(MyColors.lightPrimary,
                                          Colors.white70),
                                    ),
                                    onPressed: () async {
                                      messageController.clear();
                                      await DatabaseService.sendGroupMessage(
                                          widget.groupId, 'text', messageText);
                                    },
                                  )
                                : GestureDetector(
                                    onLongPress: () async {
                                      if (await PermissionsService()
                                          .hasMicrophonePermission()) {
                                        setState(() {
                                          isMicrophoneGranted = true;
                                        });
                                      } else {
                                        bool isGranted =
                                            await PermissionsService()
                                                .requestMicrophonePermission(
                                                    onPermissionDenied: () {
                                          AppUtil.alertDialog(
                                              context,
                                              'info',
                                              'You must grant this microphone access to be able to use this feature.',
                                              'OK');
                                          print('Permission has been denied');
                                        });
                                        setState(() {
                                          isMicrophoneGranted = isGranted;
                                        });
                                        return;
                                      }

                                      if (isMicrophoneGranted) {
                                        setState(() {
                                          _currentStatus =
                                              RecordingStatus.Recording;
                                        });
                                        await initRecorder();
                                        await recorder.startRecording(
                                            conversation: this.widget);
                                      } else {}
                                    },
                                    onLongPressEnd: (longPressDetails) async {
                                      if (isMicrophoneGranted) {
                                        setState(() {
                                          _currentStatus =
                                              RecordingStatus.Stopped;
                                        });
                                        Recording result =
                                            await recorder.stopRecording();
                                        _url = await AppUtil.uploadFile(
                                            File(result.path),
                                            context,
                                            'group_chat_voice_messages/${widget.groupId}/${randomAlphaNumeric(20)}${path.extension(result.path)}',
                                            groupMembersIds: groupMembersIds);

                                        await DatabaseService.sendGroupMessage(
                                            widget.groupId, 'audio', _url);
                                      }
                                    },
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.mic,
                                        color: switchColor(
                                            MyColors.lightPrimary,
                                            Colors.white70),
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
      ),
    );
  }

  void _select(String value) {
    switch (value) {
      case 'Members':
        Navigator.of(context).pushNamed('/group-members',
            arguments: {'groupId': widget.groupId});
        break;

      case 'Group Details':
        Navigator.of(context).pushNamed('/group-details',
            arguments: {'groupId': widget.groupId});
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

  Future<Uint8List> _loadFileBytes(String url, {OnError onError}) async {
    Uint8List bytes;
    try {
      bytes = await readBytes(url);
    } on ClientException {
      rethrow;
    }
    return bytes;
  }

  void updateRecordTime(String rt) {
    if (mounted) {
      setState(() {
        recordTime = rt;
      });
    }
  }

  Future<bool> _onBackBtnPressed() {
    Navigator.of(context).pop();
  }
}
