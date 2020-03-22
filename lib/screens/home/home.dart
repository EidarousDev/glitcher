import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/common_widgets/platform_alert_dialog.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/screens/chats/chats.dart';
import 'package:glitcher/screens/home/home_body.dart';
import 'package:glitcher/screens/login_page.dart';
import 'package:glitcher/root_page.dart';
import 'package:glitcher/screens/notifications/notifications_screen.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/screens/posts/new_post.dart';
import 'package:glitcher/screens/user_timeline/profile_screen.dart';
import 'package:glitcher/services/auth_provider.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/permissions_service.dart';
import 'package:glitcher/utils/statics.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  static const String id = 'home_page';
  HomePage({Key key, this.userId, this.onSignedOut}) : super(key: key);

  final VoidCallback onSignedOut;
  final String userId;

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String username;

  String profileImageUrl;

  dynamic body = HomeBody();

  void loadUserData(String uid) async {
    await firestore.collection('users').document(uid).get().then((onValue) {
      setState(() {
        username = onValue.data['username'];
        profileImageUrl = onValue.data['profile_url'];
      });
    });
  }

  FirebaseUser currentUser;

  _HomePageState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //AppBar
      appBar: AppBar(
        leading: Builder(
            builder: (context) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          fit: BoxFit.fill,
                          image: profileImageUrl != null
                              ? NetworkImage(profileImageUrl)
                              : AssetImage('assets/images/default_profile.png'),
                        ),
                      ),
                    ),
                  ),
                )),
        backgroundColor: Theme.of(context).primaryColorDark,
        title: body is HomeBody
            ? Text('Home')
            : body is Chats ? Text('Chats') : Text(''),
        actions: <Widget>[
          body is HomeBody
              ? IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: () {
                    PermissionsService().requestContactsPermission(
                        onPermissionDenied: () {
                      print('Permission has been denied');
                    });
                    setState(() {
                      Statics.filterPanel = !Statics.filterPanel;
                    });
                  },
                )
              : Container(),
        ],
      ),
      //MainBody

      body: body,

      drawer: Drawer(
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
                                  ProfileScreen(currentUser.uid)));
                    },
                    child: CircleAvatar(
                      radius: 35.0,
                      backgroundColor: Colors.grey,
                      backgroundImage: profileImageUrl != null
                          ? NetworkImage(profileImageUrl)
                          : AssetImage('assets/images/default_profile.png'),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        username != null ? username : '',
                        style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                      Icon(Icons.arrow_drop_down)
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.grey,
              height: 0.5,
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ProfileScreen(currentUser.uid)));
              },
              title: Text(
                'Profile',
                style: TextStyle(color: Colors.black54),
              ),
              leading: Icon(
                Icons.person,
                color: Colors.grey,
              ),
            ),
            ListTile(
              title: Text(
                'Lists',
                style: TextStyle(color: Colors.black54),
              ),
              leading: Icon(
                Icons.list,
                color: Colors.grey,
              ),
            ),
            ListTile(
              title: Text(
                'Bookmarks',
                style: TextStyle(color: Colors.black54),
              ),
              leading: Icon(
                Icons.bookmark_border,
                color: Colors.grey,
              ),
            ),
            ListTile(
              title: Text(
                'Moments',
                style: TextStyle(color: Colors.black54),
              ),
              leading: Icon(
                Icons.apps,
                color: Colors.grey,
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.grey,
              height: 0.5,
            ),
            ListTile(
              title: Text(
                'Settings and Privacy',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NotificationsScreen()));
              },
              title: Text(
                'Help center',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => Chats()));
              },
              title: Text(
                'Chats',
                style: TextStyle(color: Colors.black54),
              ),
              leading: Icon(
                Icons.chat_bubble,
                color: Colors.grey,
              ),
            ),
            ListTile(
              onTap: () {
                _signOut(context);
              },
              title: Text(
                'Sign Out',
                style: TextStyle(color: Colors.black54),
              ),
              leading: Icon(
                Icons.power_settings_new,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: body is HomeBody
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => NewPost()));
              },
              child: Icon(Icons.edit),
              backgroundColor: Theme.of(context).accentColor,
            )
          : null,

      //BottomnavBar
      bottomNavigationBar: Container(
        height: 50.0,
        color: Theme.of(context).primaryColorDark,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                setState(() {
                  body = HomeBody();
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.search),
              onPressed: null,
            ),
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                setState(() {
                  body = NotificationsScreen();
                });
              },
            ),
            IconButton(
              color: Colors.grey,
              icon: Icon(Icons.chat_bubble),
              onPressed: () {
                setState(() {
                  body = Chats();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    _retrieveDynamicLink();
    //checkPermission(PermissionGroup.storage);
  }

  Future<void> _retrieveDynamicLink() async {
    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;

    if (deepLink != null) {
      // to get the parameters we sent
      // to get what link it is use deepLink.path
      print('test link $deepLink.path');
      String postId = deepLink.queryParameters['postId'];
      // perform your navigation operations here
      Navigator.of(context).pushNamed('/post', arguments: {'postId': postId});
    }
  }

  void getCurrentUser() async {
    setState(() async {
      currentUser = await Auth().getCurrentUser();
    });
    loadUserData(currentUser.uid);
  }

  logOutCallback() async {
//    moveUserTo(
//        context: context, widget: RootPage(auth: new Auth()), routeId: '/');
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      final BaseAuth auth = AuthProvider.of(context).auth;
      await auth.signOut();
      widget.onSignedOut();
      //moveUserTo(context: context, widget: LoginPage());
    } catch (e) {
      print('Sign out: $e');
    }
  }

  requestPermission(List<PermissionGroup> permissionGroup) async {
    var permissions =
        await PermissionHandler().requestPermissions(permissionGroup);
    print('permission result is: ${permissions.toString()}');
  }

  checkPermission(PermissionGroup permissionGroup) async {
    var permissionStatus =
        await PermissionHandler().checkPermissionStatus(permissionGroup);
    if (permissionStatus != PermissionStatus.granted) {
      requestPermission([permissionGroup]);
    }
    print('permissionStatus: ${permissionStatus.toString()}');
  }
//
//    print('permission result is: ${permissionStatus.toString()}');
//  }
//
//  getPermissionStatus(Permission getPermission) async {
//    setState(() async {
//      permissionStatus =
//          await SimplePermissions.getPermissionStatus(getPermission);
//    });
//
//    print('permission result is: ${permissionStatus.toString()}');
//  }
}
