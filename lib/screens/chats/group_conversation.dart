import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/models/group_model.dart';
import 'package:glitcher/models/message_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/widgets/chat_bubble.dart';
import 'package:image_picker/image_picker.dart';
import 'package:glitcher/widgets/image_overlay.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  _GroupConversationState({this.groupId});

  void loadGroupData(String groupId) async {
    Group group;
    group = await DatabaseService.getGroupWithId(groupId);
    setState(() {
      this.group = group;
    });

    await getGroupUsersData();
  }

  void sendMessage() async {
    messageController.clear();

    await chatGroupsRef.document(groupId).collection('messages').add({
      'sender': Constants.currentUserID,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text'
    });
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

  Future chooseImage() async {
    await ImagePicker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 52,
            maxHeight: 400,
            maxWidth: 600)
        .then((image) {
      showDialog(
          barrierDismissible: true,
          child: Container(
            width: Sizes.sm_profile_image_w,
            height: Sizes.sm_profile_image_h,
            child: ImageOverlay(
              imageFile: image,
              btnText: 'Send',
              btnFunction: () async {
                await uploadFile(image, context);

                await sendImageMessage();

                Navigator.of(context).pop();
              },
            ),
          ),
          context: context);
    });
  }

  sendImageMessage() async {
    messageController.clear();
    await chatGroupsRef.document(groupId).collection('messages').add({
      'sender': Constants.currentUserID,
      'image': _url,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'image'
    });
  }

  Future uploadFile(File file, BuildContext context) async {
    if (file == null) return;

    print((file));

    StorageReference storageReference = FirebaseStorage.instance
        .ref()
        .child('image_messages/')
        .child(randomAlphaNumeric(20));
    StorageUploadTask uploadTask = storageReference.putFile(file);

    await uploadTask.onComplete;
    print('File Uploaded');
    _url = await storageReference.getDownloadURL();
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getGroupMessages();
    listenToMessagesChanges();
    loadGroupData(groupId);

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
    return Scaffold(
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
                          message: msg.type == "text" ? msg.text : msg.image,
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
                          onPressed: () {
                            chooseImage();
                          },
                        ),
                        contentPadding: EdgeInsets.all(0),
                        title: TextField(
                          textCapitalization: TextCapitalization.sentences,
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
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.send,
                            color: Colors.white70,
                          ),
                          onPressed: () async {
                            sendMessage();
                          },
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
}
