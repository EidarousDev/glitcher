import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/common_widgets/drawer.dart';
import 'package:glitcher/common_widgets/gradient_appbar.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/models/game_model.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/screens/posts/post_item.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/permissions_service.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:readmore/readmore.dart';

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
        flexibleSpace: gradientAppBar(),
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
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 15,
            ),
            Stack(
              children: <Widget>[
                Container(
                    height: 200,
                    width: Sizes.fullWidth(context),
                    child: Image.network(game.image)),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius:
                          BorderRadius.all(Radius.circular((5)))),
                      padding: EdgeInsets.all(5),
                      child: Text(
                        game.fullName,
                        style: TextStyle(fontSize: 22, shadows: [
                          Shadow(
                            blurRadius: 5.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 5,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "${game.genres}",
                style: TextStyle(fontSize: 14),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Flexible(
              fit: FlexFit.loose,
              child: ExpansionTile(
                title: Text('Details', style: TextStyle(color: MyColors.darkPrimary),),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ReadMoreText(
                      game.description,
                      colorClickableText: MyColors.darkPrimary,
                      trimLength: 300,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),

                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    height: 1,
                    color: switchColor(
                        MyColors.lightLineBreak, Colors.grey.shade600),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Platforms: ${game.platforms}'),
                  ),
                  Container(
                    height: 1,
                    color: switchColor(
                        MyColors.lightLineBreak, Colors.grey.shade600),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Stores: ${game.stores}'),
                  ),
                  Container(
                    height: 1,
                    color: switchColor(
                        MyColors.lightLineBreak, Colors.grey.shade600),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('ESRB Rating: ${game.esrbRating}'),
                  ),
                  Container(
                    height: 1,
                    color: switchColor(
                        MyColors.lightLineBreak, Colors.grey.shade600),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Metacritic score: ${game.metacritic}'),
                  ),
                  Container(
                    height: 1,
                    color: switchColor(
                        MyColors.lightLineBreak, Colors.grey.shade600),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Developers: ${game.developers}'),
                  ),
                  Container(
                    height: 1,
                    color: switchColor(
                        MyColors.lightLineBreak, Colors.grey.shade600),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Release Date: ${game.tba ? 'TBA' : game.releaseDate}'),
                  ),
                ],
              ),
            ),
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
