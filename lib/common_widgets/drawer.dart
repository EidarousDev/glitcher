import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/common_widgets/rate_app.dart';
import 'package:glitcher/screens/chats/chats.dart';
import 'package:glitcher/screens/games/games_screen.dart';
import 'package:glitcher/screens/notifications/notifications_screen.dart';
import 'package:glitcher/screens/user_timeline/profile_screen.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/utils/functions.dart';

class BuildDrawer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BuildDrawerState();
}

class _BuildDrawerState extends State<BuildDrawer> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return buildDrawer(context);
  }

  Drawer buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ProfileScreen(Constants.currentUserID)));
                  },
                  child: CircleAvatar(
                    radius: 35.0,
                    backgroundColor: Theme.of(context).primaryColor,
                    backgroundImage:
                        Constants.loggedInUser.profileImageUrl != null
                            ? CachedNetworkImageProvider(
                                Constants.loggedInUser.profileImageUrl)
                            : AssetImage('assets/images/default_profile.png'),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      Constants.loggedInUser.username != null
                          ? Constants.loggedInUser.username
                          : '',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    Icon(Icons.arrow_drop_down)
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: 0.5,
          ),
          ListTile(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ProfileScreen(Constants.currentUserID)));
            },
            title: Text(
              'Profile',
            ),
            leading: Icon(
              Icons.person,
            ),
          ),
          ListTile(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => GamesScreen()));
            },
            title: Text(
              'Games',
            ),
            leading: Icon(
              Icons.list,
            ),
          ),
          ListTile(
            title: Text(
              'Bookmarks',
            ),
            leading: Icon(
              Icons.bookmark_border,
            ),
          ),
          ListTile(
            onTap: () {
              Navigator.of(context).pushNamed('/settings');
              //Navigator.pop(context);
            },
            title: Text(
              'Settings',
            ),
            leading: Icon(
              Icons.settings,
            ),
          ),
          Container(
            width: double.infinity,
            height: 0.5,
          ),
          ListTile(
            title: Text(
              'About Glitcher',
            ),
            leading: Icon(
              Icons.info,
            ),
            onTap: () {
              Navigator.of(context).pushNamed('/about-us');
            },
          ),
          ListTile(
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => Chats()));
            },
            title: Text(
              'Chats',
            ),
            leading: Icon(
              Icons.chat_bubble,
            ),
          ),
          ListTile(
            onTap: () {
              RateApp(context).rateApp();
            },
            title: Text(
              'Rate us',
            ),
            leading: Icon(
              Icons.tag_faces,
            ),
          ),
          ListTile(
            onTap: () async {
              try {
                auth.signOut();
                setState(() {
                  authStatus = AuthStatus.NOT_LOGGED_IN;
                });
                print('Now, authStatus = $authStatus');
                Navigator.of(context).pushReplacementNamed('/');
                //moveUserTo(context: context, widget: LoginPage());
              } catch (e) {
                print('Sign out: $e');
              }
            },
            title: Text(
              'Sign Out',
            ),
            leading: Icon(
              Icons.power_settings_new,
            ),
          ),
        ],
      ),
    );
  }
}
