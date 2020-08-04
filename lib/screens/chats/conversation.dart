import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:glitcher/services/audio_recorder.dart';
import 'package:glitcher/services/permissions_service.dart';
import 'package:glitcher/widgets/bottom_sheets/profile_image_edit_bottom_sheet.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/models/message_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/notification_handler.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/chat_bubble.dart';
import 'package:glitcher/widgets/image_overlay.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:intl/intl.dart';
import 'package:random_string/random_string.dart';

class Conversation extends StatefulWidget {
  final String otherUid;
  final _ConversationState state = _ConversationState();
  Conversation({this.otherUid});

  updateRecordTime(String recordTime) {
    print('recordTime: $recordTime');
    state.updateRecordTime(recordTime);
  }

  @override
  _ConversationState createState() => state;
}

class _ConversationState extends State<Conversation>
    with WidgetsBindingObserver {
  Firestore _firestore = Firestore.instance;
//  static Random random = Random();
//  String name;
//  String profileImage;

  User otherUser = User();
  Timestamp firstVisibleGameSnapShot;
  String messageText;
  bool _typing = false;
  FocusScopeNode _focusNode = FocusScopeNode();
  AudioRecorder recorder;
  var _url;
  List<Message> _messages;

  TextEditingController messageController = TextEditingController();

  var seen = false;
  final formatter = new NumberFormat("##");

  StreamSubscription<QuerySnapshot> messagesSubscription;

  ScrollController _scrollController = ScrollController();

  String recordTime = 'recording...';

  var _currentStatus;

  _ConversationState();

  initRecorder() async {
    recorder = AudioRecorder();
    await recorder.init();
  }

  void loadUserData(String uid) async {
    User user;
    user = await DatabaseService.getUserWithId(uid);
    setState(() {
      otherUser = user;
    });
  }

  void getMessages() async {
    var messages = await DatabaseService.getMessages(widget.otherUid);
    setState(() {
      this._messages = messages;
      this.firstVisibleGameSnapShot = messages.last.timestamp;
    });
  }

  void getPrevMessages() async {
    var messages;
    messages = await DatabaseService.getPrevMessages(
        firstVisibleGameSnapShot, widget.otherUid);

    if (messages.length > 0) {
      setState(() {
        messages.forEach((element) => this._messages.add(element));
        this.firstVisibleGameSnapShot = messages.last.timestamp;
      });
    }
  }

  void listenToMessagesChanges() async {
    messagesSubscription = _firestore
        .collection('chats')
        .document(Constants.currentUserID)
        .collection('conversations')
        .document(widget.otherUid)
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

        if (Message.fromDoc(change.document).sender == widget.otherUid) {
          //print('made seen');
          makeMessagesSeen();
        }
      });
    });
  }

  void listenIfMessagesSeen() {
    _firestore
        .collection('chats')
        .document(Constants.currentUserID)
        .collection('conversations')
        .document(widget.otherUid)
        .collection('messages')
        .snapshots()
        .listen((querySnapshot) {
      querySnapshot.documentChanges.forEach((change) {
        if (change.document.documentID == 'seen') {
          if (this.mounted) {
            setState(() {
              seen = change.document.data['isSeen'];
              print('seen');
            });
          }
        }
      });
    });
  }

  void otherUserListener() {
    usersRef.snapshots().listen((querySnapshot) {
      querySnapshot.documentChanges.forEach((change) {
        if (change.document.documentID == widget.otherUid) {
          setState(() {
            otherUser = User.fromDoc(change.document);
          });
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

  void updateOnlineUserState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      await usersRef
          .document(Constants.currentUserID)
          .updateData({'online': FieldValue.serverTimestamp()});
    } else if (state == AppLifecycleState.resumed) {
      await usersRef
          .document(Constants.currentUserID)
          .updateData({'online': 'online'});
    }
  }

  makeMessagesSeen() async {
    await _firestore
        .collection('chats')
        .document(widget.otherUid)
        .collection('conversations')
        .document(Constants.currentUserID)
        .updateData({'isSeen': true});
  }

  makeMessagesUnseen() async {
    await _firestore
        .collection('chats')
        .document(Constants.currentUserID)
        .collection('conversations')
        .document(widget.otherUid)
        .setData({'isSeen': false});

    await _firestore
        .collection('chats')
        .document(widget.otherUid)
        .collection('conversations')
        .document(Constants.currentUserID)
        .setData({'isSeen': false});
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _typing = true;
    } else {
      _focusNode.unfocus();
      _typing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    updateOnlineUserState(state);
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getMessages();
    listenToMessagesChanges();
    otherUserListener();
    listenIfMessagesSeen();
    loadUserData(widget.otherUid);
    //initRecorder();

    _focusNode.addListener(_onFocusChange);

    ///Set up listener here
    _scrollController
      ..addListener(() {
        if (_scrollController.offset >=
                _scrollController.position.maxScrollExtent &&
            !_scrollController.position.outOfRange) {
          print('reached the bottom');
          getPrevMessages();
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
          flexibleSpace: gradientAppBar(),
          leading: IconButton(
              icon: Icon(
                Icons.keyboard_backspace,
              ),
              onPressed: () async {
                var message =
                    await DatabaseService.getLastMessage(widget.otherUid);

                Navigator.of(context).pop(message);
              }),
          titleSpacing: 0,
          title: InkWell(
            child: Row(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(left: 0.0, right: 10.0),
                  child: otherUser.profileImageUrl != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(
                            otherUser.profileImageUrl,
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
                        otherUser.username ?? '',
                        style: TextStyle(
                          color: switchColor(Colors.black87, Colors.white70),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        otherUser != null
                            ? otherUser.online == 'online'
                                ? 'online'
                                : 'offline'
                            : '',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: switchColor(Colors.black87, Colors.white70),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {},
          ),
//        actions: <Widget>[
//          IconButton(
//            icon: Icon(
//              Icons.more_horiz,
//            ),
//            onPressed: () {},
//          ),
//        ],
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
                            username: otherUser.username,
                            time: msg.timestamp != null
                                ? formatTimestamp(msg.timestamp)
                                : 'now',
                            type: msg.type,
                            replyText: null,
                            isMe: msg.sender == Constants.currentUserID,
                            isGroup: false,
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
                        color: switchColor(Colors.grey[500], Colors.grey[500]),
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
                                      btnText: 'Send',
                                      btnFunction: () async {
                                        String url = await AppUtil.uploadFile(
                                            image,
                                            context,
                                            'image_messages/${Constants.currentUserID}/${widget.otherUid}/' +
                                                randomAlphaNumeric(20));

                                        messageController.clear();
                                        await DatabaseService.sendMessage(
                                            widget.otherUid, 'image', url);
                                        makeMessagesUnseen();

                                        await NotificationHandler
                                            .sendNotification(
                                                widget.otherUid,
                                                Constants.currentUser.username,
                                                ' sent you an image.',
                                                Constants.currentUserID,
                                                'message');

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
                                    color: switchColor(
                                        Colors.black54, Colors.white70),
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(10.0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5.0),
                                      borderSide: BorderSide(
                                        color: MyColors.darkBG,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: MyColors.darkBG,
                                      ),
                                      borderRadius: BorderRadius.circular(5.0),
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
                                    color: switchColor(
                                        MyColors.lightPrimary, Colors.white70),
                                  ),
                                  onPressed: () async {
                                    messageController.clear();
                                    await DatabaseService.sendMessage(
                                        widget.otherUid, 'text', messageText);
                                  },
                                )
                              : GestureDetector(
                                  onLongPress: () async {
                                    bool isGranted;
                                    if (await PermissionsService()
                                        .hasMicrophonePermission()) {
                                      isGranted = true;
                                    } else {
                                      isGranted = await PermissionsService()
                                          .requestMicrophonePermission(
                                              onPermissionDenied: () {
                                        print('Permission has been denied');
                                      });
                                      return;
                                    }

                                    if (isGranted) {
                                      setState(() {
                                        _currentStatus =
                                            RecordingStatus.Recording;
                                      });
                                      await initRecorder();
                                      await recorder.startRecording(
                                          conversation: this.widget);
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
                                    setState(() {
                                      _currentStatus = RecordingStatus.Stopped;
                                    });
                                    Recording result =
                                        await recorder.stopRecording();

                                    //Storage path is voice_messages/sender_id/receiver_id/file
                                    _url = await AppUtil.uploadFile(
                                        File(result.path),
                                        context,
                                        'voice_messages/${Constants.currentUserID}/${widget.otherUid}/${randomAlphaNumeric(20)}');

                                    await DatabaseService.sendMessage(
                                        widget.otherUid, 'audio', _url);
                                  },
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.mic,
                                      color: switchColor(MyColors.lightPrimary,
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
    );
  }

  void updateRecordTime(String rt) {
    if (mounted) {
      setState(() {
        recordTime = rt;
      });
    }
  }
}
