import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/chat_item.dart';
import 'package:glitcher/utils/data.dart';
import 'package:glitcher/widgets/user_item.dart';

class NewGroup extends StatefulWidget {
  @override
  _NewGroupState createState() => _NewGroupState();
}

class _NewGroupState extends State<NewGroup>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  Firestore _firestore = Firestore.instance;
  var following = [];
  var followers = [];
  Set friends = Set();
  List<User> friendsData = [];
  List<bool> chosens = [];

  TextEditingController textEditingController;

  ScrollController _scrollController;

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
      User user = await DatabaseService.getUserWithId(friends.elementAt(i));

      setState(() {
        friendsData.add(user);
        chosens.add(false);
      });
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

  loadUserData(String uid) async {}

  @override
  void initState() {
    super.initState();

    getCurrentUserFriends();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.done,
        ),
        onPressed: (){
          List chosenUsers = [];
          for(int i = 0; i < chosens.length; i++){
            if(chosens[i]){
              chosenUsers.add(friendsData[i]);
            }
          }
        },
      ),
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
      ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 50,
            leading: Container(),
            flexibleSpace:
            Container(
              color: Constants.darkBG,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.camera_alt),
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: TextField(
                      controller: textEditingController,
                      decoration: InputDecoration.collapsed(
                        hintText: 'Group name',
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              ListView.separated(
                physics: NeverScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
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
                itemCount: friendsData.length,
                itemBuilder: (BuildContext context, int index) {
                  //User user = groups[index];
                  return ListTile(
                    contentPadding: EdgeInsets.all(0),
                    leading: Stack(
                      children: <Widget>[
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                            friendsData.elementAt(index).profileImageUrl,
                          ),
                          radius: 25,
                        ),
                        Positioned(
                          bottom: 0.0,
                          left: 6.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            height: 11,
                            width: 11,
                            child: Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: friendsData.elementAt(index).online == 'online'
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                height: 7,
                                width: 7,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      friendsData.elementAt(index).username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(friendsData.elementAt(index).description),
                    trailing: Checkbox(
                        value: chosens[index],
                        onChanged: (value) {
                          setState(() {
                            chosens[index] = value;
                          });
                          print(value);
                        }),
                  );
                },
              )
            ]),
          )
        ],
      ),
    );
  }

  addGroup(){
//    _firestore.collection('chat_groups').add({
//      'name': textEditingController.text,
//      'image':
//    })
  }

  @override
  bool get wantKeepAlive => true;
}
