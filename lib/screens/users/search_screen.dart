import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/notification_handler.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/caching_image.dart';
import 'package:glitcher/widgets/drawer.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _searchController = TextEditingController();
  bool _searching = false;
  List<User> filteredUsers = [];

  String lastVisibleGameSnapShot;

  ScrollController _scrollController = ScrollController();

  _searchUsers(String text) async {
    List<User> users = await DatabaseService.searchUsers(text.toLowerCase());
    setState(() {
      filteredUsers = users;
      this.lastVisibleGameSnapShot = users.last.username;
    });
  }

  nextSearchUsers(String text) async {
    var users =
        await DatabaseService.nextSearchUsers(lastVisibleGameSnapShot, text);
    if (users.length > 0) {
      setState(() {
        users.forEach((element) => filteredUsers.add(element));
        this.lastVisibleGameSnapShot = users.last.username;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: TextField(
            cursorColor: MyColors.darkPrimary,
            controller: _searchController,
            decoration: InputDecoration(
              fillColor: switchColor(Colors.black54, Colors.black12),
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
              filteredUsers = [];
              if (text.isEmpty) {
                setState(() {
                  filteredUsers = [];
                  _searching = false;
                });
              } else {
                _searchUsers(text);
                setState(() {
                  _searching = true;
                });
              }
            },
          ),
          flexibleSpace: gradientAppBar(),
          leading: Builder(
              builder: (context) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: Icon(
                          const IconData(58311, fontFamily: 'MaterialIcons')),
                    ),
                  )),
        ),
        body: filteredUsers.length > 0
            ? ListView.separated(
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
                itemCount: filteredUsers.length,
                padding: EdgeInsets.all(10),
                itemBuilder: (context, index) {
                  return ListTile(
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed('/user-profile', arguments: {
                          'userId': filteredUsers[index].id,
                        });
                      },
                      contentPadding: EdgeInsets.all(10),
                      leading: InkWell(
                          child: CacheThisImage(
                            imageUrl: filteredUsers[index].profileImageUrl,
                            imageShape: BoxShape.circle,
                            width: Sizes.md_profile_image_w,
                            height: Sizes.md_profile_image_h,
                            defaultAssetImage: Strings.default_profile_image,
                          ),
                          onTap: () {
                            Navigator.of(context)
                                .pushNamed('/user-profile', arguments: {
                              'userId': filteredUsers[index].id,
                            });
                          }),
                      title: Text(filteredUsers[index].username),
                      trailing:
                          filteredUsers[index].id == Constants.currentUserID
                              ? Container(
                                  height: 0,
                                  width: 0,
                                )
                              : Constants.followingIds
                                      .contains(filteredUsers[index].id)
                                  ? MaterialButton(
                                      child: Text(
                                        'Unfollow',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      onPressed: () async {
                                        await DatabaseService.unfollowUser(
                                            filteredUsers[index].id);
                                        await NotificationHandler
                                            .removeNotification(
                                                filteredUsers[index].id,
                                                Constants.currentUserID,
                                                'follow');
                                        _searchUsers(_searchController.text);
                                      },
                                      color: MyColors.darkPrimary,
                                    )
                                  : MaterialButton(
                                      child: Text(
                                        'Follow',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      onPressed: () async {
                                        await DatabaseService.followUser(
                                            filteredUsers[index].id);
                                        _searchUsers(_searchController.text);
                                      },
                                      color: MyColors.darkPrimary,
                                    ));
                })
            : Center(
                child: Text(
                'Search for users',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              )),
        drawer: BuildDrawer(),
      ),
    );
  }

  @override
  void initState() {
    _scrollController.addListener(() {
      if (_scrollController.offset >=
              _scrollController.position.maxScrollExtent &&
          !_scrollController.position.outOfRange) {
        print('reached the bottom');
        nextSearchUsers(_searchController.text);
      } else if (_scrollController.offset <=
              _scrollController.position.minScrollExtent &&
          !_scrollController.position.outOfRange) {
        print("reached the top");
      } else {}
    });
    super.initState();
  }

  Future<bool> _onBackPressed() {
    /// Navigate back to home page
    Navigator.of(context).pushReplacementNamed('/home');
  }
}
