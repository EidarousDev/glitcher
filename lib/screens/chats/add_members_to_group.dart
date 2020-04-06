import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';

class AddMembersToGroup extends StatefulWidget {
  final String groupId;
  AddMembersToGroup(this.groupId);
  @override
  _AddMembersToGroupState createState() => _AddMembersToGroupState(groupId);
}

class _AddMembersToGroupState extends State<AddMembersToGroup>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final String groupId;
  List<User> friendsData = [];
  List<bool> chosens = [];
  List<String> existingMembersIds = [];

  TextEditingController textEditingController = TextEditingController();

  ScrollController _scrollController;

  _AddMembersToGroupState(this.groupId);

  getNonMembersFriends() async {
    existingMembersIds = await DatabaseService.getGroupMembersIds(groupId);

    List<User> friends =
        await DatabaseService.getFriends(Constants.currentUserID);

    for (int i = 0; i < friends.length; i++) {
      User user = await DatabaseService.getUserWithId(friends[i].id);

      setState(() {
        if (!existingMembersIds.contains(user.id)) {
          friendsData.add(user);
          chosens.add(false);
        }
      });
    }

    return friends;
  }

  @override
  void initState() {
    super.initState();

    getNonMembersFriends();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          child: Icon(
            Icons.done,
          ),
          onPressed: () async {
            for (int i = 0; i < chosens.length; i++) {
              if (chosens[i]) {
                await DatabaseService.addMemberToGroup(
                    groupId, friendsData[i].id);
              }
            }

            Navigator.of(context).pushReplacementNamed('group-members',
                arguments: {'groupId': groupId});
          },
        ),
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[MyColors.darkCardBG, MyColors.darkBG])),
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
        body: ListView.separated(
          controller: _scrollController,
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
                            color:
                                friendsData.elementAt(index).online == 'online'
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
        ));
  }

  @override
  bool get wantKeepAlive => true;
}
