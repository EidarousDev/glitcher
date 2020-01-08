import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/utils/auth.dart';
import 'package:glitcher/widgets/chat_item.dart';
import 'package:glitcher/utils/data.dart';

class Chats extends StatefulWidget {
  @override
  _ChatsState createState() => _ChatsState();
}

class _ChatsState extends State<Chats> with SingleTickerProviderStateMixin,
    AutomaticKeepAliveClientMixin{
  TabController _tabController;

  Firestore _firestore = Firestore.instance;
  var following = [];
  var followers = [];
  Set friends = Set();
  List<ChatItem> chats = [];

  FirebaseUser currentUser;

  void getCurrentUser() async {
    this.currentUser = await Auth().getCurrentUser();
    loadFollowing();
  }

  Future<Set> getFriends() async{
    Set followingSet = Set();
    Set followerSet = Set();

    for(int i = 0; i < following.length; i++){
      followingSet.add(following[i]);
    }

    for(int j = 0; j < followers.length; j++){
      followerSet.add(followers[j]);
    }
    friends = followingSet.intersection(followerSet);

    for(int i = 0; i < friends.length; i++){
      await loadUserData(friends.elementAt(i));
    }

    return friends;
  }

  void loadFollowing() async{
    if (following.length == 0) {
      await _firestore
          .collection('users')
          .document(currentUser.uid)
          .collection('following')
          .getDocuments()
          .then((snap) {
        for (int i = 0; i < snap.documents.length; i++) {
          this.following.add(snap.documents[i].documentID);
        }
        loadFollowers();
      });
    }
  }

  void loadFollowers() async{
    if (followers.length == 0) {
      await _firestore
          .collection('users')
          .document(currentUser.uid)
          .collection('followers')
          .getDocuments()
          .then((snap) {
        for (int i = 0; i < snap.documents.length; i++) {
          this.followers.add(snap.documents[i].documentID);
        }
        getFriends();
      });
    }
  }

  Future<ChatItem> loadUserData(String uid) async {
    ChatItem chatItem;
    await _firestore.collection('users').document(uid).get().then((onValue) {
      setState(() {
        chatItem = ChatItem(
          key: ValueKey(uid),
          dp: onValue.data['profile_url'],
          name: onValue.data['username'],
          isOnline: onValue.data['online'] == 'online',
          msg: 'Last Message',
          time: onValue.data['online'] == 'online' ? 'online' : formatTimestamp(onValue.data['online']),
          counter: 0,
        );
        chats.add(chatItem);
      });
    });

    return chatItem;
  }


  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, initialIndex: 0, length: 2);

    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          ListView.separated(
            padding: EdgeInsets.all(10),
            separatorBuilder: (BuildContext context, int index) {
              return Align(
                alignment: Alignment.centerRight,
                child: Container(
                  height: 0.5,
                  width: MediaQuery.of(context).size.width / 1.3,
                  child: Divider(),
                ),
              );
            },
            itemCount: chats.length,
            itemBuilder: (BuildContext context, int index) {
              ChatItem chat = chats[index];
              return chat;
            },
          ),
          ListView.separated(
            padding: EdgeInsets.all(10),
            separatorBuilder: (BuildContext context, int index) {
              return Align(
                alignment: Alignment.centerRight,
                child: Container(
                  height: 0.5,
                  width: MediaQuery.of(context).size.width / 1.3,
                  child: Divider(),
                ),
              );
            },
            itemCount: groups.length,
            itemBuilder: (BuildContext context, int index) {
              Map chat = groups[index];

              return ChatItem(
                dp: chat['dp'],
                name: chat['name'],
                isOnline: chat['isOnline'],
                counter: chat['counter'],
                msg: chat['msg'],
                time: chat['time'],
              );
            },
          ),
        ],
      ),

    );
  }

  String formatTimestamp(Timestamp timestamp) {
    var now = Timestamp.now().toDate();
    var date = new DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);
    var diff = now.difference(date);
    var time = '';

    if (diff.inSeconds <= 60) {
      time = 'now';
    }
    else if(diff.inMinutes > 0 && diff.inMinutes < 60){
      if(diff.inMinutes == 1){
        time = 'A minute ago';
      }
      else{
        time = diff.inMinutes.toString() + ' minutes ago';
      }
    }

    else if(diff.inHours > 0 && diff.inHours < 24){
      if(diff.inHours == 1){
        time = 'An hour ago';
      }
      else{
        time = diff.inHours.toString() + ' hours ago';
      }
    }

    else if (diff.inDays > 0 && diff.inDays < 7) {
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
  bool get wantKeepAlive => true;
}