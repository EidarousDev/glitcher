import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/common_widgets/drawer.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/models/game_model.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/screens/posts/post_item.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/permissions_service.dart';
import 'package:glitcher/constants/constants.dart';

class GameScreen extends StatefulWidget {
  GameScreen({this.game});

  final Game game;
  @override
  _GameScreenState createState() => _GameScreenState(game: game);
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  _GameScreenState({this.game});

  User loggedInUser;
  Game game;
  String username;
  String profileImageUrl = '';
  var _posts = [];
  FirebaseUser currentUser;
  Timestamp lastVisiblePostSnapShot;
  //bool _noMorePosts = false;
  //bool _isFetching = false;

  ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyColors.darkBG,
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Icon(IconData(58311, fontFamily: 'MaterialIcons')),
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
      body: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverAppBar(
            pinned: false,
            expandedHeight: 250,
            leading: Container(),
            flexibleSpace: Container(
              height: 250,
              color: MyColors.darkBG,
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 15,
                  ),
                  Container(
                      height: 100,
                      width: 100,
                      child: Image.network(game.image)),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    game.fullName,
                    style: TextStyle(fontSize: 22),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    game.genre,
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    game.description,
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    height: 20,
                    color: MyColors.darkLineBreak,
                  )
                ],
              ),
            ),
          ),
          SliverList(
              delegate: SliverChildListDelegate([
            ListView.builder(
              physics: NeverScrollableScrollPhysics(),
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
          ]))
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
    List<Post> posts = await DatabaseService.getGamePosts(game.fullName);
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
          nextGamePosts();
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

  void nextGamePosts() async {
    var posts = await DatabaseService.getNextGamePosts(
        lastVisiblePostSnapShot, game.fullName);
    if (posts.length > 0) {
      setState(() {
        posts.forEach((element) => _posts.add(element));
        this.lastVisiblePostSnapShot = posts.last.timestamp;
      });
    }
  }
}
