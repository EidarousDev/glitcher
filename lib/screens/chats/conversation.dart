import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

class _ConversationState extends State<Conversation> {
  Firestore _firestore = Firestore.instance;
//  static Random random = Random();
//  String name;
//  String profileImage;
  User otherUser;
  final String otherUid;
  FirebaseUser currentUser;

  String messageText;

  var messages;

  TextEditingController messageController = TextEditingController();

  _ConversationState({this.otherUid});

  void getCurrentUser() async {
    this.currentUser = await Auth().getCurrentUser();

    streamMessages();
  }

  void loadUserData(String uid) async {
    User user;
    user = await DatabaseService.getUserWithId(uid);

    setState(() {
      otherUser = user;
    });
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();

    loadUserData(otherUid);
  }

  void sendMessage() async {
    messageController.clear();

    await _firestore
        .collection('chats')
        .document(currentUser.uid)
        .collection('conversations')
        .document(otherUid)
        .collection('messages')
        .add({
      'sender': currentUser.uid,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text'
    });

    await _firestore
        .collection('chats')
        .document(otherUid)
        .collection('conversations')
        .document(currentUser.uid)
        .collection('messages')
        .add({
      'sender': currentUser.uid,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text'
    });
  }

  void streamMessages() async {
    await for (var snapshot in _firestore
        .collection('chats')
        .document(currentUser.uid)
        .collection('conversations')
        .document(otherUid)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()) {
      setState(() {
        messages = snapshot.documents;
      });
    }
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
                      otherUser.username != null ? otherUser.username : '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      otherUser != null
                          ? otherUser.online == 'online'
                              ? 'online'
                              : formatTimestamp(otherUser.online)
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
            messages != null
                ? Flexible(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      itemCount: messages.length,
                      reverse: true,
                      itemBuilder: (BuildContext context, int index) {
                        Map msg = messages[index].data;
                        return ChatBubble(
                          message: msg['type'] == "text"
                              ? msg['text']
                              : msg['image'],
                          username: otherUser.username,
                          time: formatTimestamp(msg['timestamp']),
                          type: msg['type'],
                          replyText: null,
                          isMe: msg['sender'] == currentUser.uid,
                          isGroup: false,
                          isReply: false,
                          replyName: null,
                        );
                      },
                    ),
                  )
                : Container(),
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