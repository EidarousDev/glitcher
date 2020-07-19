import 'package:flutter/material.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/widgets/caching_image.dart';

class UsersScreen extends StatefulWidget {
  final String screenType;

  const UsersScreen({Key key, @required this.screenType}) : super(key: key);

  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<User> users;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.screenType),
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
      body: ListView.separated(
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
          itemCount: users.length,
          padding: EdgeInsets.all(10),
          itemBuilder: (context, index) {
            return ListTile(
              contentPadding: EdgeInsets.all(10),
              leading: InkWell(
                  child: CacheThisImage(
                    imageUrl: users[index].profileImageUrl,
                    imageShape: BoxShape.circle,
                    width: Sizes.md_profile_image_w,
                    height: Sizes.md_profile_image_h,
                    defaultAssetImage: Strings.default_profile_image,
                  ),
                  onTap: () {
                    Navigator.of(context)
                        .pushNamed('/user-profile', arguments: {
                      'userId': users[index].id,
                    });
                  }),
              title: Text(users[index].username),
              trailing: widget.screenType != 'followers'
                  ? MaterialButton(
                      child: Text('Unfollow'),
                      onPressed: () async {
                        await DatabaseService.unfollowUser(users[index].id);
                        Navigator.of(context).pushReplacementNamed('/friends');
                      },
                      color: MyColors.darkPrimary,
                    )
                  : null,
            );
          }),
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
