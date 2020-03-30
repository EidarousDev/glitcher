import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/models/group_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/chat_item.dart';
import 'package:glitcher/utils/data.dart';
import 'package:glitcher/widgets/show_dialog.dart';

class GroupMembers extends StatefulWidget {
  final String groupId;
  GroupMembers({this.groupId});

  @override
  _GroupMembersState createState() => _GroupMembersState(groupId: groupId);
}

class _GroupMembersState extends State<GroupMembers>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> members = [];
  String groupId;

  _GroupMembersState({this.groupId});

  loadUsersData() async {
    List<Map<String, dynamic>> users = [];
    QuerySnapshot usersSnapshot = await chatGroupsRef
        .document(groupId)
        .collection('users')
        .getDocuments();

    usersSnapshot.documents.forEach((doc) async {
      Map<String, dynamic> user = {};
      User temp = await DatabaseService.getUserWithId(doc.documentID);
      user.putIfAbsent('name', (() => temp.username));
      user.putIfAbsent('image', (() => temp.profileImageUrl));
      user.putIfAbsent('is_admin', (() => doc.data['is_admin']));
      user.putIfAbsent('id', (() => doc.documentID));
      setState(() {
        members.add(user);
      });
    });
  }

  @override
  void initState() {
    super.initState();
    loadUsersData();
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
              Icons.person_add,
            ),
            onPressed: () {
              //TODO add new screen to add select friends to be added to group;
              /// DatabaseService.addMemberToGroup(groupId, '');
            },
          )
        ],
      ),
      body: ListView.separated(
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
        itemCount: members.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage(members[index]['image']),
            ),
            title: Text(members[index]['name'] ?? ''),
            subtitle: Text(members[index]['is_admin'] ? 'Admin' : ''),
            trailing: members
                    .where((member) => member['id'] == Constants.currentUserID)
                    .toList()[0]['is_admin']
                ? Container(
                    width: 100,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        IconButton(
                          icon: Icon(
                              MaterialCommunityIcons.getIconData('crown'),
                              color: Colors.white70),
                          onPressed: () {
                            print('user to be made admin');
                            MyDialog(
                              context: context,
                              bodyText: 'Sure to make this member an admin?',
                              dialogType: DialogType.TWO_BUTTONS,
                              confirmFunction: () {
                                DatabaseService.toggleMemberAdmin(
                                    groupId, members[index]['id']);
                                setState(() {
                                  members[index]['is_admin'] =
                                      !members[index]['is_admin'];
                                });
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white70),
                          onPressed: () {
                            print('user to be removed');
                            MyDialog(
                              context: context,
                              bodyText: 'Sure to delete this member?',
                              dialogType: DialogType.TWO_BUTTONS,
                              confirmFunction: () {
                                DatabaseService.removeGroupMember(
                                    groupId, members[index]['id']);
                                setState(() {
                                  members.removeAt(index);
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
