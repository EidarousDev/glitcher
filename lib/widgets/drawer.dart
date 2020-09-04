import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/screens/games/games_screen.dart';
import 'package:glitcher/screens/profile/profile_screen.dart';
import 'package:glitcher/widgets/rate_app.dart';

class BuildDrawer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BuildDrawerState();
}

class _BuildDrawerState extends State<BuildDrawer> {
  @override
  Widget build(BuildContext context) {
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
                        Constants.currentUser.profileImageUrl != null
                            ? CachedNetworkImageProvider(
                                Constants.currentUser.profileImageUrl)
                            : AssetImage('assets/images/default_profile.png'),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        Constants.currentUser.username != null
                            ? Constants.currentUser.username
                            : '',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                    //Icon(Icons.arrow_drop_down)
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
            onTap: () {
              Navigator.of(context).pushNamed('/bookmarks');
            },
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
              final Email email = Email(
                body:
                    '\nPlease don\'t remove this line (${Constants.currentUserID})',
                subject: 'State subject here',
                recipients: ['support@gl1tch3r.com'],
                isHTML: false,
              );

              await FlutterEmailSender.send(email);
            },
            title: Text(
              'Contact us',
            ),
            leading: Icon(
              Icons.email,
            ),
          ),
          ListTile(
            onTap: () async {
              try {
                String token = await FirebaseMessaging().getToken();
                usersRef
                    .document(Constants.currentUserID)
                    .collection('tokens')
                    .document(token)
                    .updateData({
                  'modifiedAt': FieldValue.serverTimestamp(),
                  'signed': false
                });

                await firebaseAuth.signOut();

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
