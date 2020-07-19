import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/models/group_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/chat_item.dart';

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
    });

    setState(() {
      this.friends = friends;
    });
  }

  Future<ChatItem> loadUserData(String uid) async {
    ChatItem chatItem;
    User user = await DatabaseService.getUserWithId(uid);
    setState(() {
      chatItem = ChatItem(
        key: ValueKey(uid),
        dp: user.profileImageUrl,
        name: user.username,
        isOnline: user.online == 'online',
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

  getChatGroups() async {
    List<String> groupsIds = await DatabaseService.getGroups();
    for (String groupId in groupsIds) {
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
        flexibleSpace: gradientAppBar(),
//        elevation: 4,
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.search,
              size: 28.0,
            ),
            suffixIcon: IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  _searchController.clear();
                }),
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
                if (chatItem.name.contains(text)) {
                  setState(() {
                    filteredChats.add(chatItem);
                  });
                }
              });
            } else {
              groups.forEach((groupItem) {
                if (groupItem.name.contains(text)) {
                  setState(() {
                    filteredGroups.add(groupItem);
                  });
                }
              });
            }
          },
        ),
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
            itemCount: !_searching ? chats.length : filteredChats.length,
            itemBuilder: !_searching
                ? (BuildContext context, int index) {
                    ChatItem chat = chats[index];
                    return chat;
                  }
                : (BuildContext context, int index) {
                    ChatItem chat = filteredChats[index];
                    return chat;
                  },
          ),
          ListView.separated(
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
