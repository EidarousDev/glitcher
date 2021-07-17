import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/list_items/post_item.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart' as user_model;
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';

class BookmarksScreen extends StatefulWidget {
  @override
  _BookmarksScreenState createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen>
    with WidgetsBindingObserver {
  ScrollController _scrollController = ScrollController();
  user_model.User loggedInUser;
  String username;
  String profileImageUrl = '';
  var _posts = [];
  User currentUser;
  Timestamp lastVisiblePostSnapShot;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: gradientAppBar(),
          leading: new IconButton(
            icon: new Icon(Icons.arrow_back),
            onPressed: () {
              _onBackPressed();
            },
          ),
          title: Text('Bookmarks'),
          centerTitle: true,
        ),
        body: _posts.length > 0
            ? SingleChildScrollView(
                controller: _scrollController,
                child: ListView.separated(
                  separatorBuilder: (BuildContext context, int index) {
                    return Container(
                      height: 1,
                      color: MyColors.darkAccent,
                      width: MediaQuery.of(context).size.width / 1.3,
                      child: Divider(),
                    );
                  },
                  physics: NeverScrollableScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  itemCount: _posts.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    Post post = _posts[index];
                    //print('post author: ${post.authorId}');
                    return post.authorId != 'deleted'
                        ? FutureBuilder(
                            future: DatabaseService.getUserWithId(post.authorId,
                                checkLocal: true),
                            builder:
                                (BuildContext context, AsyncSnapshot snapshot) {
                              if (!snapshot.hasData) {
                                return SizedBox.shrink();
                              }
                              user_model.User author = snapshot.data;
                              return PostItem(
                                post: post,
                                author: author,
                              );
                            })
                        : SizedBox(
                            child: Center(
                                child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                    'This post has been deleted by the author.'),
                                IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () async {
                                    await usersRef
                                        .doc(Constants.currentUserID)
                                        .collection('bookmarks')
                                        .doc(post.id)
                                        .delete();
                                    _setupFeed();
                                  },
                                )
                              ],
                            )),
                            height: 100,
                          );
                  },
                ),
              )
            : Center(
                child: Text(
                'No posts bookmarked',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              )),
      ),
    );
  }

  Future<bool> _onBackPressed() {
    Constants.routesStack.pop();
    Navigator.of(context).pop();
  }

  _setupFeed() async {
    //print('what\'s happening?');
    List<Post> posts = await DatabaseService.getBookmarksPosts();
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
          nextBookmarksPosts();
        } else if (_scrollController.offset <=
                _scrollController.position.minScrollExtent &&
            !_scrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });
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

  void nextBookmarksPosts() async {
    var posts =
        await DatabaseService.getNextBookmarksPosts(lastVisiblePostSnapShot);
    if (posts.length > 0) {
      setState(() {
        posts.forEach((element) => _posts.add(element));
        this.lastVisiblePostSnapShot = posts.last.timestamp;
      });
    }
  }
}
