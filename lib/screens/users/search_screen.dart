import 'package:flutter/material.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/list_items/user_item.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/functions.dart';
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
                        setState(() {
                          filteredUsers = [];
                        });
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
                      child: Icon(Icons.menu),
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
                  return UserItem(
                    user: filteredUsers[index],
                  );
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
