import 'dart:convert';

import 'package:audiofileplayer/audiofileplayer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/list_items/post_item.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/caching_image.dart';
import 'package:glitcher/widgets/drawer.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';
import 'package:glitcher/widgets/rate_app.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();

  static bool isBottomSheetVisible = false;

  static showMyBottomSheet(BuildContext context) {
    // the context of the bottomSheet will be this widget
    //the context here is where you want to show the bottom sheet
    showBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return BottomSheet(
            enableDrag: true,
            onClosing: () {
              HomeScreen.isBottomSheetVisible = false;
            },
            builder: (BuildContext context) {
              return Container(
                color: MyColors.darkPrimary,
                height: 120,
              );
            },
          ); // returns your BottomSheet widget
        });
  }
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  User loggedInUser;
  String username;
  //String profileImageUrl = '';
  List<Post> _posts = [];
  FirebaseUser currentUser;
  Timestamp lastVisiblePostSnapShot;
  bool _noMorePosts = false;
//  bool _isFetching = false;
//  bool arePostsFilteredByFollowedGames = false;
//  bool arePostsFilteredByFollowing = false;
//  int gamersFilterRadio = -1;
  int feedFilter = 0;

  ScrollController _scrollController = ScrollController();

  bool isFiltering = false;

  int _spawnedAudioCount = 0;
  ByteData _swipeUpSFX;
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Home'),
        flexibleSpace: gradientAppBar(),
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Icon(const IconData(58311, fontFamily: 'MaterialIcons')),
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
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.tune,
            ),
            onPressed: () {
              setState(() {
                isFiltering = !isFiltering;
              });
//              PermissionsService().requestContactsPermission(
//                  onPermissionDenied: () {
//                print('Permission has been denied');
//              });
            },
          ),
        ],
      ),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        header: WaterDropHeader(),
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                height: isFiltering ? 252 : 70,
                //height: 120,//TODO use this if video fixed
                color: switchColor(MyColors.lightBG, MyColors.darkBG),
                child: Column(
                  children: <Widget>[
                    isFiltering
                        ? Padding(
                            padding: const EdgeInsets.only(
                                left: 10, top: 2, right: 10),
                            child: Container(
                              child: Column(
                                children: <Widget>[
                                  Text(
                                    'Filter by:',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Radio(
                                          activeColor: MyColors.darkPrimary,
                                          value: 0,
                                          groupValue: feedFilter,
                                          onChanged: (value) {
                                            setState(() {
                                              //arePostsFilteredByFollowedGames = false;
                                              feedFilter = value;
                                            });
                                          }),
                                      Text(
                                        'Recent Posts',
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      Radio(
                                          activeColor: MyColors.darkPrimary,
                                          value: 1,
                                          groupValue: feedFilter,
                                          onChanged: (value) {
                                            setState(() {
                                              //arePostsFilteredByFollowedGames = false;
                                              feedFilter = value;
                                            });
                                          }),
                                      Text(
                                        'Followed Gamers',
                                      ),
                                      Radio(
                                          activeColor: MyColors.darkPrimary,
                                          value: 2,
                                          groupValue: feedFilter,
                                          onChanged: (value) {
                                            setState(() {
                                              //arePostsFilteredByFollowedGames = true;
                                              feedFilter = value;
                                            });
                                          }),
                                      Text(
                                        'Followed Games',
                                      ),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: MaterialButton(
                                      color: MyColors.darkPrimary,
                                      child: Text('Filter'),
                                      onPressed: () {
                                        _setupFeed();
                                        setState(() {
                                          isFiltering = false;
                                        });
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Divider(
                                      height: 1,
                                      color: Colors.white,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          )
                        : Container(),
                    Row(
                      children: <Widget>[
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CacheThisImage(
                              imageUrl: loggedInProfileImageURL,
                              imageShape: BoxShape.circle,
                              width: Sizes.sm_profile_image_w,
                              height: Sizes.sm_profile_image_h,
                              defaultAssetImage: Strings.default_profile_image,
                            )),
                        Expanded(
                          child: InkWell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                  border: Border.all(
                                      color: switchColor(MyColors.lightPrimary,
                                          MyColors.darkPrimary),
                                      width: 1),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 22.0),
                                  child: TextField(
                                    decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: "Any thoughts?",
                                        enabled: false,
                                        hintStyle: TextStyle(
                                            fontWeight: FontWeight.w400,
                                            color: Constants.currentTheme ==
                                                    AvailableThemes.LIGHT_THEME
                                                ? MyColors.lightPrimary
                                                : MyColors.darkPrimary)),
                                  ),
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context)
                                  .pushReplacementNamed('/new-post');
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
                            color: switchColor(
                                MyColors.lightCardBG, MyColors.darkLineBreak)),
                      ),
                    ),
//TODO uncomment after fixing video
//                    Center(
//                      child: Row(
//                        crossAxisAlignment: CrossAxisAlignment.center,
//                        mainAxisAlignment: MainAxisAlignment.center,
//                        children: <Widget>[
//                          Expanded(
//                              child: CardIconText(
//                            tStyle: TextStyle(fontWeight: FontWeight.bold),
//                            icon: FontAwesome.getIconData("image"),
//                            text: "Image",
//                            color: Constants.currentTheme ==
//                                    AvailableThemes.LIGHT_THEME
//                                ? MyColors.lightBG
//                                : MyColors.darkLineBreak,
//                            ccolor:
//                                switchColor(MyColors.lightPrimary, Colors.blue),
//                          )),
//                          SizedBox(
//                            height: 25,
//                            width: 1.0,
//                            child: DecoratedBox(
//                              decoration: BoxDecoration(
//                                  color: Constants.currentTheme ==
//                                          AvailableThemes.LIGHT_THEME
//                                      ? MyColors.lightLineBreak
//                                      : MyColors.darkLineBreak),
//                            ),
//                          ),
//                          Expanded(
//                              child: CardIconText(
//                            tStyle: TextStyle(fontWeight: FontWeight.bold),
//                            icon: FontAwesome.getIconData("file-video-o"),
//                            text: "Video",
//                            color: Constants.currentTheme ==
//                                    AvailableThemes.LIGHT_THEME
//                                ? MyColors.lightBG
//                                : MyColors.darkLineBreak,
//                            ccolor: switchColor(
//                                MyColors.lightPrimary, Colors.greenAccent),
//                          )),
//                          SizedBox(
//                            height: 25,
//                            width: 1.0,
//                            child: DecoratedBox(
//                              decoration: BoxDecoration(
//                                  color: Constants.currentTheme ==
//                                          AvailableThemes.LIGHT_THEME
//                                      ? MyColors.lightLineBreak
//                                      : MyColors.darkLineBreak),
//                            ),
//                          ),
//                          Expanded(
//                              child: CardIconText(
//                            tStyle: TextStyle(fontWeight: FontWeight.bold),
//                            icon: FontAwesome.getIconData("youtube"),
//                            text: "YouTube",
//                            color: Constants.currentTheme ==
//                                    AvailableThemes.LIGHT_THEME
//                                ? MyColors.lightBG
//                                : MyColors.darkLineBreak,
//                            ccolor:
//                                switchColor(MyColors.lightPrimary, Colors.pink),
//                          )),
//                        ],
//                      ),
//                    ),
                    SizedBox(
                      height: 1,
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: switchColor(
                                MyColors.lightCardBG, MyColors.darkLineBreak)),
                      ),
                    ),
                  ],
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
                            future:
                                DatabaseService.getUserWithId(post.authorId),
                            builder:
                                (BuildContext context, AsyncSnapshot snapshot) {
                              if (!snapshot.hasData) {
                                return SizedBox.shrink();
                              }
                              User author = snapshot.data;
                              return PostItem(post: post, author: author);
                            });
                      },
                    )
                  : Padding(
                      padding: const EdgeInsets.only(top: 160.0),
                      child: Center(
                          child: Text(
                        'No posts to show',
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                      )),
                    ),
            ],
          ),
        ),
      ),
      drawer: BuildDrawer(),
    );
  }

  _setupFeed() async {
    List<Post> posts;
    feedFilter = await getFavouriteFilter();

    print('Home Filter: $feedFilter');

    if (feedFilter == 0) {
      posts = await DatabaseService.getPosts();
      setState(() {
        _posts = posts;
        this.lastVisiblePostSnapShot = posts.last.timestamp;
      });
    } else if (feedFilter == 1) {
      posts = await DatabaseService.getPostsFilteredByFollowing();
      setState(() {
        _posts = posts;
        this.lastVisiblePostSnapShot = posts.last.timestamp;
      });
    } else if (feedFilter == 2) {
      posts = await DatabaseService.getPostsFilteredByFollowedGames();
      setState(() {
        _posts = posts;
        this.lastVisiblePostSnapShot = posts.last.timestamp;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Constants.currentRoute = '/home';

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
    RateApp(context).rateGlitcher();
    _loadAudioByteData();
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
    updateOnlineUserState(state);
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

  void updateOnlineUserState(AppLifecycleState state) async {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      await usersRef
          .document(Constants.currentUserID)
          .updateData({'online': FieldValue.serverTimestamp()});
    } else if (state == AppLifecycleState.resumed) {
      await usersRef
          .document(Constants.currentUserID)
          .updateData({'online': 'online'});
    }
  }

  void loadUserData() async {
    currentUser = await auth.currentUser();
    //print('currentUserID: ${currentUser.uid}');
    // here you write the codes to input the data into firestore
    loggedInUser = await DatabaseService.getUserWithId(currentUser.uid);

    if (mounted) {
      setState(() {
        //profileImageUrl = loggedInUser.profileImageUrl;
        loggedInProfileImageURL = loggedInUser.profileImageUrl;
        username = loggedInUser.username;
//        print(
//            'profileImageUrl = ${loggedInProfileImageURL} and username = $username');
      });
    }
  }

  void nextPosts() async {
    var posts;
    if (feedFilter == 0) {
      posts = await DatabaseService.getNextPosts(lastVisiblePostSnapShot);
    } else if (feedFilter == 1) {
      posts = await DatabaseService.getNextPostsFilteredByFollowing(
          lastVisiblePostSnapShot);
    } else if (feedFilter == 2) {
      posts = await DatabaseService.getNextPostsFilteredByFollowedGames(
          lastVisiblePostSnapShot);
    }
    if (posts.length > 0) {
      setState(() {
        posts.forEach((element) => _posts.add(element));
        this.lastVisiblePostSnapShot = posts.last.timestamp;
      });
    }
  }

  void _onRefresh() async {
    _swipeUpSFX == null
        ? null
        : Audio.loadFromByteData(_swipeUpSFX,
            onComplete: () => setState(() => --_spawnedAudioCount))
      ..play()
      ..dispose();
    setState(() => ++_spawnedAudioCount);
    await _setupFeed();
    //await Future.delayed(Duration(milliseconds: 1000));
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    // monitor network fetch
    //await Future.delayed(Duration(milliseconds: 1000));
    // if failed,use loadFailed(),if no data return,use LoadNodata()
    if (mounted) setState(() {});
    _refreshController.loadComplete();
  }

  void _refresh() {
    getTemporaryDirectory().then((dir) {
      dir.delete(recursive: true);
    });
    setState(() {});
  }

  void _loadAudioByteData() async {
    _swipeUpSFX = await rootBundle.load(Strings.swipe_up_to_reload);
  }
}

void updateGames() async {
  String url =
      'https://api.rawg.io/api/games?dates=2000-01-01%2C2020-12-31&ordering=-added&page=382';
  var response = await http.get(url);
  String body = response.body;
  while (jsonDecode(body)['next'] != null) {
    var response = await http.get(url);
    //print(url);
    String body = response.body;
    List results = jsonDecode(body)['results'];

    for (int i = 0; i < results.length; i++) {
      List genres = [];
      (results[i]['genres'] as List).forEach((genre) {
        genres.add(genre['name']);
      });

      List platforms = [];
      if (results[i]['platforms'] != null) {
        (results[i]['platforms'] as List).forEach((platform) {
          platforms.add(platform['platform']['name']);
        });
      } else {}

      List stores = [];
      if (results[i]['stores'] != null) {
        (results[i]['stores'] as List).forEach((store) {
          stores.add(store['store']['name']);
        });
      } else {}

      List tags = [];
      (results[i]['tags'] as List).forEach((tag) {
        tags.add(tag['name']);
      });

      String detailedUrl = 'https://api.rawg.io/api/games/${results[i]['id']}';
      var detailedResponse = await http.get(detailedUrl);
      String gameDetailsBody = detailedResponse.body;
      var gameDetails = jsonDecode(gameDetailsBody);

      List publishers = [];
      (gameDetails['publishers'] as List).forEach((publisher) {
        publishers.add(publisher['name']);
      });

      List developers = [];
      (gameDetails['developers'] as List).forEach((developer) {
        developers.add(developer['name']);
      });

      List search = searchList(results[i]['name']);

      (gameDetails['alternative_names'] as List).forEach((element) {
        search.addAll(searchList(element));
      });

      //print(gameDetails['description_raw']);
      //print(utf8.decode(gameDetails['description_raw'].toString().runes.toList()));
      print('Game: ${fixString(results[i]['name'])}');
      await firestore
          .collection('games')
          .document(results[i]['id'].toString())
          .setData({
        'fullName': fixString(results[i]['name']),
        'slug': results[i]['slug'],
        'tba': results[i]['tba'],
        'release_date': results[i]['released'],
        'description': fixString(gameDetails['description_raw'].toString()),
        'website': gameDetails['website'],
        'reddit_url': gameDetails['reddit_url'],
        'alternative_names': gameDetails['alternative_names'],
        'platforms': platforms,
        'stores': stores,
        'metacritic': results[i]['metacritic'],
        'esrb_rating': gameDetails['esrb_rating'] == null
            ? null
            : gameDetails['esrb_rating']['name'],
        'metacritic_url': gameDetails['metacritic_url'],
        'genres': genres,
        'image': results[i]['background_image'],
        'publishers': publishers,
        'developers': developers,
        'timestamp': FieldValue.serverTimestamp(),
        'search': search
      });
    }

    url = jsonDecode(body)['next'];
    print('next url: $url');
  }
}

fixString(String s) {
  try {
    return utf8.decode(s.runes.toList());
  } catch (ex) {
    return s;
  }
}

searchList(String text) {
  List<String> list = [];
  for (int i = 1; i <= text.length; i++) {
    list.add(text.substring(0, i).toLowerCase());
  }
  return list;
}
