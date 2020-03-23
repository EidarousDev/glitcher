import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/models/message_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/widgets/chat_bubble.dart';

class Conversation extends StatefulWidget {
  final String otherUid;

  Conversation({this.otherUid});

  @override
  _ConversationState createState() => _ConversationState(otherUid: otherUid);
}

class _ConversationState extends State<Conversation>
    with WidgetsBindingObserver {
  Firestore _firestore = Firestore.instance;
//  static Random random = Random();
//  String name;
//  String profileImage;
  User otherUser = User();
  final String otherUid;
  Timestamp firstVisibleGameSnapShot;
  String messageText;

  List<Message> _messages;

  TextEditingController messageController = TextEditingController();

  var seen = false;

  StreamSubscription<QuerySnapshot> messagesSubscription;

  ScrollController _scrollController = ScrollController();

  _ConversationState({this.otherUid});

  void loadUserData(String uid) async {
    User user;
    user = await DatabaseService.getUserWithId(uid);
    setState(() {
      otherUser = user;
    });
  }

  void sendMessage() async {
    messageController.clear();

    await _firestore
        .collection('chats')
        .document(Constants.currentUserID)
        .collection('conversations')
        .document(otherUid)
        .collection('messages')
        .add({
      'sender': Constants.currentUserID,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text'
    });

    await _firestore
        .collection('chats')
        .document(otherUid)
        .collection('conversations')
        .document(Constants.currentUserID)
        .collection('messages')
        .add({
      'sender': Constants.currentUserID,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text'
    });

    makeMessagesUnseen();
  }

  void getMessages() async {
    var messages = await DatabaseService.getMessages(otherUid);
    setState(() {
      this._messages = messages;
      this.firstVisibleGameSnapShot = messages.last.timestamp;
    });
  }

  void getPrevMessages() async{
    var messages;
    messages = await DatabaseService.getPrevMessages(firstVisibleGameSnapShot, otherUid);

    if (messages.length > 0) {
      setState(() {
        messages.forEach((element) => this._messages.add(element));
        this.firstVisibleGameSnapShot = messages.last.timestamp;
      });
    }
  }

//  void streamMessages() async {
//    await for (var snapshot in _firestore
//        .collection('chats')
//        .document(Constants.currentUserID)
//        .collection('conversations')
//        .document(otherUid)
//        .collection('messages')
//        .orderBy('timestamp', descending: true)
//        .snapshots()) {
//      setState(() {
//        messages = snapshot.documents;
//        if (snapshot.documents.first.data['sender'] == otherUid) {
//          print('made seen');
//          makeMessagesSeen();
//        }
//      });
//    }
//  }
  void listenToMessagesChanges() async{
    messagesSubscription = _firestore
        .collection('chats')
        .document(Constants.currentUserID)
        .collection('conversations')
        .document(otherUid)
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

        if (Message.fromDoc(change.document).sender == otherUid) {
          print('made seen');
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
        .document(otherUid)
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
        if (change.document.documentID == otherUid) {
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

  void makeMessagesSeen() async {
//    await _firestore
//        .collection('chats')
//        .document(Constants.currentUserID)
//        .collection('conversations')
//        .document(otherUid)
//        .collection('messages')
//        .document('seen')
//        .setData({'isSeen': true});

    await _firestore
        .collection('chats')
        .document(otherUid)
        .collection('conversations')
        .document(Constants.currentUserID)
        .collection('messages')
        .document('seen')
        .setData({'isSeen': true});
  }

  void makeMessagesUnseen() async {
    await _firestore
        .collection('chats')
        .document(Constants.currentUserID)
        .collection('conversations')
        .document(otherUid)
        .collection('messages')
        .document('seen')
        .updateData({'isSeen': false});

    await _firestore
        .collection('chats')
        .document(otherUid)
        .collection('conversations')
        .document(Constants.currentUserID)
        .collection('messages')
        .document('seen')
        .updateData({'isSeen': false});
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
    }
    else if (state == AppLifecycleState.detached) {
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
    loadUserData(otherUid);

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
    _scrollController
        .dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      otherUser != null
                          ? otherUser.online == 'online' ? 'online' : 'offline'
                          : '',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
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
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.more_horiz,
            ),
            onPressed: () {},
          ),
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
                  child: Text(seen ? 'seen' : ''),
                )),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
//                height: 140,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
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
                            color: Theme.of(context).accentColor,
                          ),
                          onPressed: () {},
                        ),
                        contentPadding: EdgeInsets.all(0),
                        title: TextField(
                          controller: messageController,
                          onChanged: (value) {
                            messageText = value;
                          },
                          style: TextStyle(
                            fontSize: 15.0,
                            color: Theme.of(context).textTheme.title.color,
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(10.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                              ),
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            hintText: "Write your message...",
                            hintStyle: TextStyle(
                              fontSize: 15.0,
                              color: Theme.of(context).textTheme.title.color,
                            ),
                          ),
                          maxLines: null,
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.send,
                            color: Theme.of(context).accentColor,
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
}
