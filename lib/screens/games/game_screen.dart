import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:glitcher/services/share_link.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:glitcher/widgets/caching_image.dart';
import 'package:glitcher/widgets/circular_btn.dart';
import 'package:glitcher/widgets/custom_loader.dart';
import 'package:glitcher/widgets/drawer.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/models/game_model.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/list_items/post_item.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/permissions_service.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:readmore/readmore.dart';
import 'package:share/share.dart';

class GameScreen extends StatefulWidget {
  GameScreen({this.game});

  final Game game;
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  String username;
  String profileImageUrl = '';
  var _posts = [];
  FirebaseUser currentUser;
  Timestamp lastVisiblePostSnapShot;
  //bool _noMorePosts = false;
  //bool _isFetching = false;

  ScrollController _scrollController = ScrollController();

  AnimationController _animationController;
  Animation _degOneTranslationAnimation;
  Animation _rotationAnimation;

  Image _gameImage;

  bool isFollowing = false;

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  double radiansToDegrees(double degree) {
    double unitRadians = 57.295779513;
    return degree / unitRadians;
  }

  @override
  void initState() {
    super.initState();
    checkStates();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250));

    _degOneTranslationAnimation =
        Tween(begin: 0.0, end: 1.0).animate(_animationController);

    _rotationAnimation = Tween(begin: 180.0, end: 0.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addObserver(this);
    _gameImage = Image.network(
      widget.game.image,
    );

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
    _setupFeed();
  }

  checkStates() async {
    DocumentSnapshot game = await usersRef
        .document(Constants.currentUserID)
        .collection('followedGames')
        .document(widget.game.id)
        .get();
    if (game.exists) {
      if (mounted) {
        setState(() {
          isFollowing = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          isFollowing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/suggestion', arguments: {
                  'initial_title': '${widget.game.fullName} edit suggestion',
                  'initial_details':
                      'I (${Constants.currentUser.username}) suggest the following edit:',
                  'game_id': widget.game.id
                });
              },
              icon: Icon(
                MaterialCommunityIcons.getIconData('lightbulb-on'),
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () async {
                await shareGame(
                    widget.game.id, widget.game.fullName, widget.game.image);
              },
              icon: Icon(
                Icons.share,
                color: Colors.white,
              ),
            )
          ],
          flexibleSpace: gradientAppBar(),
          leading: Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  onPressed: () => _onBackPressed(),
                ),
              ),
            ),
          ),
          centerTitle: true,
        ),
        body: Container(
          height: Sizes.fullHeight(context),
          width: Sizes.fullWidth(context),
          child: Stack(
            children: [
              SingleChildScrollView(
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
                        CacheThisImage(
                          height: 180,
                          imageUrl: widget.game.image,
                          imageShape: BoxShape.rectangle,
                          width: Sizes.fullWidth(context),
                        ),
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
                                widget.game.fullName,
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
                      child: Center(
                        widthFactor: 10,
                        child: Text(
                          "${widget.game.genres}",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Flexible(
                      fit: FlexFit.loose,
                      child: ExpansionTile(
                        title: Text(
                          'Details',
                          style: TextStyle(color: MyColors.darkPrimary),
                        ),
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ReadMoreText(
                              widget.game.description,
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
                            child: Text('Platforms: ${widget.game.platforms}'),
                          ),
                          Container(
                            height: 1,
                            color: switchColor(
                                MyColors.lightLineBreak, Colors.grey.shade600),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('Stores: ${widget.game.stores}'),
                          ),
                          Container(
                            height: 1,
                            color: switchColor(
                                MyColors.lightLineBreak, Colors.grey.shade600),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child:
                                Text('ESRB Rating: ${widget.game.esrbRating}'),
                          ),
                          Container(
                            height: 1,
                            color: switchColor(
                                MyColors.lightLineBreak, Colors.grey.shade600),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                                'Metacritic score: ${widget.game.metacritic}'),
                          ),
                          Container(
                            height: 1,
                            color: switchColor(
                                MyColors.lightLineBreak, Colors.grey.shade600),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child:
                                Text('Developers: ${widget.game.developers}'),
                          ),
                          Container(
                            height: 1,
                            color: switchColor(
                                MyColors.lightLineBreak, Colors.grey.shade600),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                                'Release Date: ${widget.game.tba ? 'TBA' : widget.game.releaseDate}'),
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: MaterialButton(
                        height: 30,
                        onPressed: () {
                          followUnfollow();
                        },
                        textColor:
                            isFollowing ? MyColors.darkPrimary : Colors.white,
                        color:
                            isFollowing ? Colors.white70 : MyColors.darkPrimary,
                        child:
                            Text(isFollowing ? 'Unfollow Game' : 'Follow Game'),
                      ),
                    ),
                    _posts.length > 0
                        ? ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            itemCount: _posts.length,
                            shrinkWrap: true,
                            itemBuilder: (BuildContext context, int index) {
                              Post post = _posts[index];
                              return FutureBuilder(
                                  future: DatabaseService.getUserWithId(
                                      post.authorId,
                                      checkLocal: false),
                                  builder: (BuildContext context,
                                      AsyncSnapshot snapshot) {
                                    if (!snapshot.hasData) {
                                      return SizedBox.shrink();
                                    }
                                    User author = snapshot.data;
                                    return PostItem(post: post, author: author);
                                  });
                            },
                          )
                        : Center(
                            child: Text('Be the first to post on this game!')),
                  ],
                ),
              ),
//              Positioned(
//                right: 20,
//                bottom: 20,
//                child: Stack(
//                  alignment: Alignment.bottomRight,
//                  children: [
//                    IgnorePointer(
//                      child: Container(
////                        color: Colors.black.withOpacity(
////                            0.5), // comment or change to transparent color
//                        height: 130.0,
//                        width: 130.0,
//                      ),
//                    ),
//                    Transform.translate(
//                        child: Transform(
//                          transform: Matrix4.rotationZ(
//                            radiansToDegrees(_rotationAnimation.value),
//                          )..scale(_degOneTranslationAnimation.value,
//                              _degOneTranslationAnimation.value),
//                          alignment: Alignment.center,
//                          child: CircularButton(
//                            color: Colors.blue,
//                            width: 50,
//                            height: 50,
//                            icon: Icon(Icons.add_box),
//                            onClick: () {
//                              Navigator.of(context).pushNamed('/new-post',
//                                  arguments: {
//                                    'selectedGame': widget.game.fullName
//                                  });
//                            },
//                          ),
//                        ),
//                        offset: Offset.fromDirection(radiansToDegrees(190),
//                            _degOneTranslationAnimation.value * 80)),
//                    Transform.translate(
//                      child: Transform(
//                        transform: Matrix4.rotationZ(
//                          radiansToDegrees(_rotationAnimation.value),
//                        )..scale(_degOneTranslationAnimation.value,
//                            _degOneTranslationAnimation.value),
//                        alignment: Alignment.center,
//                        child: CircularButton(
//                          color:
//                              isFollowing ? MyColors.darkPrimary : Colors.white,
//                          width: 50,
//                          height: 50,
//                          icon: isFollowing
//                              ? Image.asset('assets/images/unfollow_game.png')
//                              : Image.asset('assets/images/follow_game.png'),
//                          onClick: () async {
//                            await followUnfollow();
//                          },
//                        ),
//                      ),
//                      offset: Offset.fromDirection(radiansToDegrees(250),
//                          _degOneTranslationAnimation.value * 80),
//                    ),
//                    CircularButton(
//                      color: MyColors.darkPrimary,
//                      width: 60,
//                      height: 60,
//                      icon: Icon(Icons.menu),
//                      onClick: () {
//                        if (_animationController.isCompleted) {
//                          _animationController.reverse();
//                        } else {
//                          _animationController.forward();
//                        }
//                      },
//                    ),
//                  ],
//                ),
//              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Image.asset(
            'assets/images/post_add.png',
            width: 25,
            height: 25,
          ),
          backgroundColor: MyColors.darkPrimary,
          onPressed: () {
            Navigator.of(context).pushNamed('/new-post',
                arguments: {'selectedGame': widget.game.fullName});
          },
        ),
        drawer: BuildDrawer(),
      ),
    );
  }

  followUnfollow() async {
    Navigator.of(context).push(CustomScreenLoader());

    DocumentSnapshot game = await usersRef
        .document(Constants.currentUserID)
        .collection('followedGames')
        .document(widget.game.id)
        .get();

    if (game.exists) {
      await DatabaseService.unFollowGame(widget.game.id);
      setState(() {
        isFollowing = false;
      });
      Constants.followedGamesNames.remove(widget.game.fullName);
      AppUtil.showToast('Game unfollowed');
    } else {
      await DatabaseService.followGame(widget.game.id);
      setState(() {
        isFollowing = true;
      });
      Constants.followedGamesNames.add(widget.game.fullName);
      AppUtil.showToast('Game followed');
    }
    Navigator.of(context).pop();
  }

  shareGame(String gameId, String gameName, String imageUrl) async {
    var gameLink = await DynamicLinks.createGameDynamicLink(
        {'gameId': gameId, 'text': gameName, 'imageUrl': imageUrl});
    Share.share('Check out ($gameName) : $gameLink');
    print('Check out this game ($gameName): $gameLink');
  }

  _setupFeed() async {
    //print('what\'s happening?');
    List<Post> posts = await DatabaseService.getGamePosts(widget.game.fullName);
    setState(() {
      _posts = posts;
      this.lastVisiblePostSnapShot = posts.last.timestamp;
    });
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

  void nextGamePosts() async {
    var posts = await DatabaseService.getNextGamePosts(
        lastVisiblePostSnapShot, widget.game.fullName);
    if (posts.length > 0) {
      setState(() {
        posts.forEach((element) => _posts.add(element));
        this.lastVisiblePostSnapShot = posts.last.timestamp;
      });
    }
  }

  Future<bool> _onBackPressed() {
    Navigator.of(context).pop();
  }
}
