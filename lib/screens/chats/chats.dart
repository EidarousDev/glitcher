import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/list_items/chat_item.dart';
import 'package:glitcher/main.dart';
import 'package:glitcher/models/group_model.dart';
import 'package:glitcher/models/message_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/drawer.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';

class Chats extends StatefulWidget {
  @override
  _ChatsState createState() => _ChatsState();
}

class _ChatsState extends State<Chats>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  TabController _tabController;
  List<ChatItem> chats = [];
  List<Group> groups = [];
  List<User> friends = [];

  bool _searching = false;

  List<ChatItem> filteredChats = [];
  List<Group> filteredGroups = [];

  TextEditingController _searchController = TextEditingController();

  void getCurrentUserFriends() async {
    List<User> friends =
        await DatabaseService.getFriends(Constants.currentUserID);

    friends.forEach((f) async {
      await loadUserData(f.id);
      await sortChatItems();
    });

    setState(() {
      this.friends = friends;
    });
  }

  Future<ChatItem> loadUserData(String uid) async {
    ChatItem chatItem;
    User user = await DatabaseService.getUserWithId(uid);
    Message message = await DatabaseService.getLastMessage(user.id);
    setState(() {
      chatItem = ChatItem(
        key: ValueKey(uid),
        dp: user.profileImageUrl,
        name: user.username,
        isOnline: user.online == 'online',
        msg: message ?? 'No messages yet',
        counter: 0,
      );
      chats.add(chatItem);
    });

    return chatItem;
  }

  @override
  void initState() {
    getCurrentUserFriends();
    getChatGroups();
    super.initState();
    _tabController = TabController(vsync: this, initialIndex: 0, length: 2);
  }

  getChatGroups() async {
    List<String> groupsIds = await DatabaseService.getGroups();
    for (String groupId in groupsIds) {
      Group group = await DatabaseService.getGroupWithId(groupId);
      setState(() {
        this.groups.add(group);
      });
    }
  }

  sortChatItems() {
    int n = chats.length;
    for (int i = 0; i < n - 1; i++) {
      for (int j = 0; j < n - i - 1; j++) {
        var current = chats[j].msg.timestamp;
        var next = chats[j + 1].msg.timestamp;
        if (current.seconds <= next.seconds) {
          setState(() {
            ChatItem temp = chats[j];
            chats[j] = chats[j + 1];
            chats[j + 1] = temp;
          });
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    sortChatItems();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: gradientAppBar(),
//        elevation: 4,
          title: TextField(
            cursorColor: MyColors.darkPrimary,
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.search,
                size: 28.0,
              ),
              suffixIcon: _searching
                  ? IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                      })
                  : null,
              hintText: 'Search',
            ),
            onChanged: (text) {
              filteredChats = [];
              filteredGroups = [];
              if (text.length != 0) {
                setState(() {
                  _searching = true;
                });
              } else {
                setState(() {
                  _searching = false;
                });
              }
              if (_tabController.index == 0) {
                chats.forEach((chatItem) {
                  if (chatItem.name
                      .toLowerCase()
                      .contains(text.toLowerCase())) {
                    setState(() {
                      filteredChats.add(chatItem);
                    });
                  }
                });
              } else {
                groups.forEach((groupItem) {
                  if (groupItem.name
                      .toLowerCase()
                      .contains(text.toLowerCase())) {
                    setState(() {
                      filteredGroups.add(groupItem);
                    });
                  }
                });
              }
            },
          ),
          leading: Builder(
              builder: (context) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: Icon(IconData(58311, fontFamily: 'MaterialIcons')),
                    ),
                  )),
          actions: <Widget>[],
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                filteredGroups = [];
                filteredChats = [];
                _searching = false;
              });
              _searchController.clear();
            },
            controller: _tabController,
            indicatorColor: Theme.of(context).accentColor,
            labelColor: MyColors.darkGrey,
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
        floatingActionButton: _tabController.index == 1
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/new-group');
                },
                child: Icon(
                  Icons.add,
                ))
            : null,
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            chats.length > 0
                ? ListView.separated(
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
                    itemCount:
                        !_searching ? chats.length : filteredChats.length,
                    itemBuilder: !_searching
                        ? (BuildContext context, int index) {
                            ChatItem chat = chats[index];
                            return chat;
                          }
                        : (BuildContext context, int index) {
                            ChatItem chat = filteredChats[index];
                            return chat;
                          },
                  )
                : Center(
                    child: Text(
                    'No chats yet',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  )),
            groups.length > 0
                ? ListView.separated(
                    padding: EdgeInsets.symmetric(
                      vertical: 7,
                    ),
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
                    itemCount: !_searching && _tabController.index == 1
                        ? this.groups.length
                        : this.filteredGroups.length,
                    itemBuilder: (BuildContext context, int index) {
                      Group group = !_searching && _tabController.index == 1
                          ? this.groups[index]
                          : this.filteredGroups[index];

                      return ListTile(
                        onTap: () {
                          Navigator.of(context).pushNamed('/group-conversation',
                              arguments: {'groupId': group.id});
                        },
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey.shade400,
                          backgroundImage: group.image != null
                              ? NetworkImage(group.image)
                              : AssetImage(Strings.default_group_image),
                        ),
                        title: Text(group.name),
                      );
                    },
                  )
                : Center(
                    child: Text(
                    'No groups yet',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  )),
          ],
        ),
        drawer: BuildDrawer(),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  Future<bool> _onBackPressed() {
    /// Navigate back to home page
    Navigator.of(context).pushReplacementNamed('/home');
  }
}
