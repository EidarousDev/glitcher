import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/list_items/user_item.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/notification_handler.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/caching_image.dart';
import 'package:glitcher/widgets/custom_loader.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';

class UsersScreen extends StatefulWidget {
  final String screenType;

  const UsersScreen({Key key, @required this.screenType}) : super(key: key);

  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<User> users;
  TextEditingController _searchController = TextEditingController();
  bool _searching = false;
  List<User> filteredUsers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: TextField(
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
            if (text.length != 0) {
              setState(() {
                _searching = true;
              });
            } else {
              setState(() {
                _searching = false;
              });
            }
            users.forEach((user) {
              if (user.username.toLowerCase().contains(text.toLowerCase())) {
                setState(() {
                  filteredUsers.add(user);
                });
              }
            });
          },
        ),
        flexibleSpace: gradientAppBar(),
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: new IconButton(
                icon: new Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ),
      ),
      body: users.length > 0
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
              itemCount: !_searching ? users.length : filteredUsers.length,
              padding: EdgeInsets.all(10),
              itemBuilder: (context, index) {
                return !_searching
                    ? UserItem(
                        user: users[index],
                      )
                    : UserItem(
                        user: filteredUsers[index],
                      );
              })
          : Center(
              child: Text(
              'No ${widget.screenType} yet',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            )),
    );
  }

  @override
  void initState() {
    switch (widget.screenType) {
      case 'Friends':
        setState(() {
          users = Constants.userFriends;
        });
        break;
      case 'Following':
        setState(() {
          users = Constants.userFollowing;
        });
        break;
      case 'Followers':
        setState(() {
          users = Constants.userFollowers;
        });
        break;
    }
    super.initState();
  }
}
