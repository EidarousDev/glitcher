import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/font_awesome.dart';
import 'package:glitcher/common_widgets/card_icon_text.dart';
import 'package:glitcher/common_widgets/drawer.dart';
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
  var _posts = [];
  FirebaseUser currentUser;
  Timestamp lastVisiblePostSnapShot;
  bool _noMorePosts = false;
  bool _isFetching = false;

  ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Constants.darkBG,
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
      body: Column(
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
                      : Constants.darkCardBG,
                  ccolor: Constants.darkPrimary,
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
                      : Constants.darkCardBG,
                  ccolor: Constants.darkPrimary,
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
                      : Constants.darkCardBG,
                  ccolor: Constants.darkPrimary,
                )),
              ],
            ),
          ),
          SizedBox(
            height: 8.0,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                  color: currentTheme == AvailableThemes.LIGHT_THEME
                      ? Constants.lightLineBreak
                      : Constants.darkLineBreak),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.vertical,
              itemCount: _posts.length,
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.add,
        ),
        onPressed: () {
          Navigator.of(context).pushNamed('/new-post');
        },
      ),
      drawer: BuildDrawer(),
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
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    ///Set up listener here
    _scrollController
      ..addListener(() {
        if (_scrollController.offset >=
                _scrollController.position.maxScrollExtent &&
            !_scrollController.position.outOfRange) {
          print('reached the bottom');
          nextPosts();
        } else if (_scrollController.offset <=
                _scrollController.position.minScrollExtent &&
            !_scrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });
    loadUserData();
    _setupFeed();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController
        .dispose(); // it is a good practice to dispose the controller
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
    var posts = await DatabaseService.getNextPosts(lastVisiblePostSnapShot);
    if (posts.length > 0) {
      setState(() {
        posts.forEach((element) => _posts.add(element));
        this.lastVisiblePostSnapShot = posts.last.timestamp;
      });
    }
  }
}
