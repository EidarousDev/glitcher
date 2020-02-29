import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/font_awesome.dart';
import 'package:glitcher/common_widgets/card_icon_text.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/screens/chats/chats.dart';
import 'package:glitcher/screens/notifications/notifications_screen.dart';
import 'package:glitcher/screens/posts/post_item.dart';
import 'package:glitcher/screens/user_timeline/profile_screen.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/permissions_service.dart';
import 'package:glitcher/utils/constants.dart';
import 'package:glitcher/utils/functions.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  User loggedInUser;
  String username;
  String profileImageUrl = '';
  List<Post> _posts = [];
  FirebaseUser currentUser;
  Timestamp lastVisiblePostSnapShot;
  bool _noMorePosts = false;
  bool _isFetching = false;

  ScrollController _scrollController;
  double _scrollPosition;

  _scrollListener() {
    setState(() {
      _scrollPosition = _scrollController.position.pixels;
    });
    print('Position $_scrollPosition pixels');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Icon(IconData(58311, fontFamily: 'MaterialIcons')),
//                    CachedNetworkImage(
//                      imageUrl: profileImageUrl,
//                      imageBuilder: (context, imageProvider) => CircleAvatar(
//                        radius: 25.0,
//                      ),
//                      placeholder: (context, url) =>
//                          CircularProgressIndicator(),
//                      errorWidget: (context, url, error) => Icon(Icons.error),
//                    ),
            ),
          ),
        ),
        title: Text("Feeds"),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.filter_list,
            ),
            onPressed: () {
              PermissionsService().requestContactsPermission(
                  onPermissionDenied: () {
                print('Permission has been denied');
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    radius: 25.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: profileImageUrl != null
                        ? CachedNetworkImageProvider(profileImageUrl)
                        : AssetImage('assets/images/default_profile.png'),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          border: Border.all(
                              color: currentTheme == AvailableThemes.LIGHT_THEME
                                  ? Constants.lightAccent
                                  : Constants.darkPrimary,
                              width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 22.0),
                          child: TextField(
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "What's on your mind?",
                                enabled: false,
                                hintStyle: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    color: currentTheme ==
                                            AvailableThemes.LIGHT_THEME
                                        ? Constants.lightAccent
                                        : Constants.darkPrimary)),
                          ),
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pushReplacementNamed('/new-post');
                    },
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 1,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: currentTheme == AvailableThemes.LIGHT_THEME
                        ? Constants.lightLineBreak
                        : Constants.darkLineBreak),
              ),
            ),
            Center(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                      child: CardIconText(
                    tStyle: TextStyle(fontWeight: FontWeight.bold),
                    icon: FontAwesome.getIconData("image"),
                    text: "Image",
                    color: currentTheme == AvailableThemes.LIGHT_THEME
                        ? Constants.lightLineBreak
                        : Constants.darkLineBreak,
                    ccolor: Colors.blue,
                  )),
                  SizedBox(
                    height: 25,
                    width: 1.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: currentTheme == AvailableThemes.LIGHT_THEME
                              ? Constants.lightLineBreak
                              : Constants.darkLineBreak),
                    ),
                  ),
                  Expanded(
                      child: CardIconText(
                    tStyle: TextStyle(fontWeight: FontWeight.bold),
                    icon: FontAwesome.getIconData("file-video-o"),
                    text: "Video",
                    color: currentTheme == AvailableThemes.LIGHT_THEME
                        ? Constants.lightLineBreak
                        : Constants.darkLineBreak,
                    ccolor: Colors.greenAccent,
                  )),
                  SizedBox(
                    height: 25,
                    width: 1.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: currentTheme == AvailableThemes.LIGHT_THEME
                              ? Constants.lightLineBreak
                              : Constants.darkLineBreak),
                    ),
                  ),
                  Expanded(
                      child: CardIconText(
                    tStyle: TextStyle(fontWeight: FontWeight.bold),
                    icon: FontAwesome.getIconData("youtube"),
                    text: "YouTube",
                    color: currentTheme == AvailableThemes.LIGHT_THEME
                        ? Constants.lightLineBreak
                        : Constants.darkLineBreak,
                    ccolor: Colors.pink,
                  )),
                ],
              ),
            ),
            SizedBox(
              height: 1.0,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: currentTheme == AvailableThemes.LIGHT_THEME
                        ? Constants.lightLineBreak
                        : Constants.darkLineBreak),
              ),
            ),
            SizedBox(
              height: 14.0,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: currentTheme == AvailableThemes.LIGHT_THEME
                        ? Constants.lightLineBreak
                        : Constants.darkLineBreak),
              ),
            ),
            ListView.builder(
              controller: _scrollController,
              itemCount: _posts.length,
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                Post post = _posts[index];
                return FutureBuilder(
                    future: DatabaseService.getUserWithId(post.authorId),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (!snapshot.hasData) {
                        return SizedBox.shrink();
                      }
                      User author = snapshot.data;
                      return PostItem(post: post, author: author);
                    });
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.add,
        ),
        onPressed: () {
          Navigator.of(context).pushNamed('/new-post');
        },
      ),
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
                      backgroundColor: Theme.of(context).primaryColor,
                      backgroundImage: profileImageUrl != null
                          ? CachedNetworkImageProvider(profileImageUrl)
                          : AssetImage('assets/images/default_profile.png'),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        username != null ? username : '',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
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
                        builder: (context) => ProfileScreen(currentUser.uid)));
              },
              title: Text(
                'Profile',
              ),
              leading: Icon(
                Icons.person,
              ),
            ),
            ListTile(
              title: Text(
                'Lists',
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
                changeTheme(context);
              },
              title: Text(
                'Change Theme',
              ),
              leading: Icon(
                Icons.apps,
              ),
            ),
            Container(
              width: double.infinity,
              height: 0.5,
            ),
            ListTile(
              title: Text(
                'Settings and Privacy',
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
              ),
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
      ),
    );
  }

  _setupFeed() async {
    //print('what\'s happening?');
    List<Post> posts = await DatabaseService.getPosts();
    setState(() {
      _posts = posts;
      this.lastVisiblePostSnapShot = posts.last.timestamp;
    });
  }

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    super.initState();
    WidgetsBinding.instance.addObserver(this);
//    // set up listener here
//    _scrollController = ScrollController();
//    _scrollController.addListener(() {
//      print('are we even here?!');
//      if (_scrollController.offset >=
//              _scrollController.position.maxScrollExtent &&
//          !_scrollController.position.outOfRange) {
//        setState(() {
//          print('reached the bottom');
//        });
//      } else if (_scrollController.offset <=
//              _scrollController.position.minScrollExtent &&
//          !_scrollController.position.outOfRange) {
//        setState(() {
//          print("reached the top");
//        });
//      } else {
//        setState(() {
//          print('were here');
//        });
//      }
//    });
    loadUserData();
    _setupFeed();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // user returned to our app
      _setupFeed();
    } else if (state == AppLifecycleState.inactive) {
      // app is inactive
      _setupFeed();
    } else if (state == AppLifecycleState.paused) {
      // user is about quit our app temporally
      _setupFeed();
    } else if (state == AppLifecycleState.detached) {
      // app suspended (not used in iOS)
    }
  }

  void loadUserData() async {
    currentUser = await auth.currentUser();
    //print('currentUserID: ${currentUser.uid}');
    // here you write the codes to input the data into firestore
    loggedInUser = await DatabaseService.getUserWithId(currentUser.uid);

    setState(() {
      profileImageUrl = loggedInUser.profileImageUrl;
      username = loggedInUser.username;
      print('profileImageUrl = $profileImageUrl and username = $username');
    });
  }

  void nextPosts() async {
    dynamic posts = await DatabaseService.getNextPosts(lastVisiblePostSnapShot);
    setState(() {
      _posts.add(posts);
      this.lastVisiblePostSnapShot = posts.last.timestamp;
    });
  }

//  void _scrollListener() async {
//    //if (_noMorePosts) return;
//    print('reached 1120 posts!');
//
//    if (_scrollController.position.pixels ==
//            _scrollController.position.maxScrollExtent &&
//        _isFetching == false) {
//      _isFetching = true;
//      print('reached 10 posts!');
//      nextPosts();
//      _isFetching = false;
//    }
//    print('reached 1000 posts!');
//  }
}
