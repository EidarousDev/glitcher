import 'package:flutter/material.dart';
import 'package:glitcher/common_widgets/gradient_appbar.dart';
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
            itemCount: this.groups.length,
            itemBuilder: (BuildContext context, int index) {
              Group group = this.groups[index];

              return ListTile(
                onTap: () {
                  Navigator.of(context).pushNamed('group-conversation',
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
