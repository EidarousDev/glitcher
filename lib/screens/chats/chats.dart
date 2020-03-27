import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/models/group_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/chat_item.dart';
import 'package:glitcher/utils/data.dart';

class Chats extends StatefulWidget {
  @override
  _ChatsState createState() => _ChatsState();
}

class _ChatsState extends State<Chats>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  TabController _tabController;

  Firestore _firestore = Firestore.instance;
  var following = [];
  var followers = [];
  Set friends = Set();
  List<ChatItem> chats = [];
  List<Group> groups = [];

  void getCurrentUserFriends() async {
    await loadFollowing();
    await loadFollowers();
    await getFriends();
  }

  Future<Set> getFriends() async {
    Set followingSet = Set();
    Set followerSet = Set();

    for (int i = 0; i < following.length; i++) {
      followingSet.add(following[i]);
    }

    for (int j = 0; j < followers.length; j++) {
      followerSet.add(followers[j]);
    }
    friends = followingSet.intersection(followerSet);

    for (int i = 0; i < friends.length; i++) {
      await loadUserData(friends.elementAt(i));
    }

    return friends;
  }

  loadFollowing() async {
    if (following.length == 0) {
      QuerySnapshot snap = await _firestore
          .collection('users')
          .document(Constants.currentUserID)
          .collection('following')
          .getDocuments();

      for (int i = 0; i < snap.documents.length; i++) {
        this.following.add(snap.documents[i].documentID);
      }
    }
  }

  loadFollowers() async {
    if (followers.length == 0) {
      QuerySnapshot snap = await _firestore
          .collection('users')
          .document(Constants.currentUserID)
          .collection('followers')
          .getDocuments();

      for (int i = 0; i < snap.documents.length; i++) {
        this.followers.add(snap.documents[i].documentID);
      }
    }
  }

  Future<ChatItem> loadUserData(String uid) async {
    ChatItem chatItem;
    User user = await DatabaseService.getUserWithId(uid);
      setState(() {
        chatItem = ChatItem(
          key: ValueKey(uid),
          dp: user.profileImageUrl,
          name: user.username,
          isOnline:user.online == 'online',
          msg: 'Last Message',
          time: user.online == 'online'
              ? 'online'
              : Functions.formatTimestamp(user.online),
          counter: 0,
        );
        chats.add(chatItem);
      });


    return chatItem;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, initialIndex: 0, length: 2);

    getCurrentUserFriends();
    getChatGroups();
  }

  getChatGroups() async{
    List<String> groupsIds = await DatabaseService.getGroups();
    for(String groupId in groupsIds){
      Group group = await DatabaseService.getGroupWithId(groupId);
      setState(() {
        this.groups.add(group);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Constants.darkCardBG, Constants.darkBG])),
        ),
//        elevation: 4,
        leading: IconButton(
          icon: Icon(
            Icons.keyboard_backspace,
          ),
          onPressed: () {},
        ),
        title: TextField(
          decoration: InputDecoration.collapsed(
            hintText: 'Search',
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.add,
            ),
            onPressed: () {
              Navigator.of(context).pushNamed('new-group');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).accentColor,
          labelColor: Constants.darkGrey,
          unselectedLabelColor: Theme.of(context).textTheme.caption.color,
          isScrollable: false,
          tabs: <Widget>[
            Tab(
              text: "Friends",
            ),
            Tab(
              text: "Groups",
            ),
          ],
        ),
      ),
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
            padding: EdgeInsets.symmetric(vertical: 7,),
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
            itemCount: this.groups.length,
            itemBuilder: (BuildContext context, int index) {
              Group group = this.groups[index];

              return ListTile(
                onTap: (){
                  Navigator.of(context).pushNamed('group-conversation', arguments: {'groupId': group.id});
                },
                leading: CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(group.image),
                ),
                title: Text(group.name),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
