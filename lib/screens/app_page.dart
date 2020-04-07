import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/screens/home/home_screen.dart';
import 'package:glitcher/screens/notifications/notifications_screen.dart';
import 'package:glitcher/screens/user_timeline/profile_screen.dart';
import 'package:badges/badges.dart';
import 'package:glitcher/services/notification_handler.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:package_info/package_info.dart';
import 'chats/chats.dart';

class AppPage extends StatefulWidget {
  static const String id = 'home_page';
  AppPage({Key key}) : super(key: key);

  @override
  _AppPageState createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  PageController _pageController;
  int _page = 0; //Highlight the first Icon in the BottomNavigationBarItem
  String username;
  String profileImageUrl;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  PackageInfo packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        physics: NeverScrollableScrollPhysics(),
        controller: _pageController,
        onPageChanged: onPageChanged,
        children: <Widget>[
          HomeScreen(),
          Chats(),
          NotificationsScreen(),
          ProfileScreen(Constants.currentUserID),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
            // sets the background color of the `BottomNavigationBar`
            canvasColor: Theme.of(context).backgroundColor,
            // sets the active color of the `BottomNavigationBar` if `Brightness` is light
            primaryColor: Theme.of(context).primaryColor,
            accentColor: MyColors.darkPrimary,
            textTheme: Theme.of(context).textTheme),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
//            BottomNavigationBarItem(
//              icon: Icon(
//                Icons.group,
//              ),
//              title: Container(height: 0.0),
//            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
              ),
              title: Container(height: 0.0),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.message,
              ),
              title: Container(height: 0.0),
            ),
            BottomNavigationBarItem(
              // ignore: null_aware_before_operator
              icon: Constants.loggedInUser?.notificationsNumber > 0
                  ? Badge(
                      badgeContent: Text(Constants
                          .loggedInUser?.notificationsNumber
                          .toString()),
                      child: Icon(Icons.notifications),
                      toAnimate: true,
                      animationType: BadgeAnimationType.scale,
                    )
                  : Icon(Icons.notifications),
              title: Container(height: 0.0),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
              ),
              title: Container(height: 0.0),
            ),
          ],
          onTap: navigationTapped,
          currentIndex: _page,
        ),
      ),
    );
  }

  void navigationTapped(int page) {
    _pageController.jumpToPage(page);
  }

  @override
  void initState() {
    super.initState();
    setPackageInfo();
    print('Constants.loggedInUser: ${Constants.loggedInUser}');
    _pageController = PageController(initialPage: 0);
    _retrieveDynamicLink();
    userListener();
    _saveDeviceToken();
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

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  userListener() {
    usersRef.snapshots().listen((querySnapshot) {
      querySnapshot.documentChanges.forEach((change) {
        setState(() {
          if (change.document.documentID == Constants.currentUserID) {
            Constants.loggedInUser = User.fromDoc(change.document);
          }
        });
      });
    });
  }

  void onPageChanged(int page) {
    //Solves the problem setState() called after dispose()
    if (mounted) {
      setState(() {
        this._page = page;
        if (page == 3) {
          //notification screen
          NotificationHandler().clearNotificationsNumber();
        }
      });
    }
  }

  _saveDeviceToken() async {
    String token = await _firebaseMessaging.getToken();
    if (token != null) {
      usersRef
          .document(Constants.currentUserID)
          .collection('tokens')
          .document(token)
          .setData({'modifiedAt': FieldValue.serverTimestamp()});
    }
    print('token = $token');
  }

  Future<void> setPackageInfo() async {
    await initPackageInfo();
    // App Strings
    setState(() {
      Strings.packageName = packageInfo.packageName;
      Strings.appVersion = packageInfo.version;
      Strings.appName = packageInfo.appName;
      Strings.buildNumber = packageInfo.buildNumber;
    });
  }

  Future<void> initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = info;
    });
    print(
        'packageName ${packageInfo.packageName}, buildNumber ${packageInfo.buildNumber}, appName: ${packageInfo.appName} , packageVersion ${packageInfo.version}');
  }
}
