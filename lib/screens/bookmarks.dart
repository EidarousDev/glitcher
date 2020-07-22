import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/list_items/post_item.dart';
import 'package:glitcher/services/database_service.dart';

class BookmarksScreen extends StatefulWidget {
  @override
  _BookmarksScreenState createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen>
    with WidgetsBindingObserver {
  ScrollController _scrollController = ScrollController();
  User loggedInUser;
  String username;
  String profileImageUrl = '';
  var _posts = [];
  FirebaseUser currentUser;
  Timestamp lastVisiblePostSnapShot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: SingleChildScrollView(
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
                    future: DatabaseService.getUserWithId(post.authorId),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (!snapshot.hasData) {
                        return SizedBox.shrink();
                      }
                      User author = snapshot.data;
                      return PostItem(
                        post: post,
                        author: author,
                        route: '/bookmarks',
                      );
                    })
                : SizedBox(
                    child: Center(
                        child:
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Text('This post has been deleted by the author.'),
                                IconButton(icon: Icon(Icons.close), onPressed: () async{
                                  await usersRef
                                  .document(Constants.currentUserID)
                                  .collection('bookmarks')
                                  .document(post.id)
                                  .delete();
                                  _setupFeed();
                                },)
                              ],
                            )),
                    height: 100,
                  );
          },
        ),
      ),
    );
  }

  _onBackPressed() {
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
      //print('profileImageUrl = $profileImageUrl and username = $username');
    });
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
