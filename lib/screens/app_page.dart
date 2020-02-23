import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/font_awesome.dart';
import 'package:glitcher/screens/home/home_body.dart';
import 'package:glitcher/screens/home/home_screen.dart';
import 'package:glitcher/screens/user_timeline/profile_screen.dart';
import 'package:badges/badges.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/services/auth_provider.dart';
import 'package:glitcher/utils/constants.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'chats/chats.dart';

class AppPage extends StatefulWidget {
  static const String id = 'home_page';
  AppPage({Key key}) : super(key: key);

  @override
  _AppPageState createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  PageController _pageController;
  int _page = 2;
  String username;
  String profileImageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        physics: NeverScrollableScrollPhysics(),
        controller: _pageController,
        onPageChanged: onPageChanged,
        children: <Widget>[
          Chats(),
          Chats(),
          HomeScreen(),
          Chats(),
          ProfileScreen(Constants.currentUserID),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
            // sets the background color of the `BottomNavigationBar`
            canvasColor: Theme.of(context).primaryColor,
            // sets the active color of the `BottomNavigationBar` if `Brightness` is light
            primaryColor: Theme.of(context).accentColor,
            textTheme: Theme.of(context).textTheme),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(
                Icons.message,
              ),
              title: Container(height: 0.0),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.group,
              ),
              title: Container(height: 0.0),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
              ),
              title: Container(height: 0.0),
            ),
            BottomNavigationBarItem(
              icon: Badge(
                badgeContent: Text('3'),
                child: Icon(Icons.notifications),
                toAnimate: true,
                animationType: BadgeAnimationType.scale,
              ),
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
    _pageController = PageController(initialPage: 2);
    _retrieveDynamicLink();
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

  void onPageChanged(int page) {
    setState(() {
      this._page = page;
    });
  }
}
