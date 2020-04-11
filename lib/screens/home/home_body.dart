import 'dart:async';
import 'dart:io';

//import 'package:audioplayer/audioplayer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/screens/posts/post_preview.dart';
import 'package:glitcher/screens/posts/post_item.dart';
import 'package:glitcher/screens/user_timeline/profile_screen.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/services/share_link.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/utils/statics.dart';
import 'package:share/share.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:soundpool/soundpool.dart';

class HomeBody extends StatefulWidget {
  @override
  _HomeBodyState createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> with WidgetsBindingObserver {
  List<Post> _posts = [];
  var posts = [];
  var postsIDs = [];
  Timestamp lastVisiblePostSnapShot;

  var profileImages = [];
  var usernames = [];
  var retweets = ['10'];
  var likes = [];
  var dislikes = [];

  Soundpool pool = Soundpool(streamType: StreamType.ring);
  //AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();
  YoutubePlayerController _youtubeController;
  bool _isPlaying;
  VideoPlayerController videoPlayerController;
  ChewieController chewieController;
  Chewie playerWidget;
  FirebaseUser currentUser;
  String selectedCategory = "";
  GlobalKey<AutoCompleteTextFieldState<String>> autocompleteKey =
      new GlobalKey();

  int allOrFollowing = 0;

  var following = [];

  void getCurrentUser() async {
    this.currentUser = await Auth().getCurrentUser();
  }

  var _scrollController = ScrollController();

  void playVideo(String video) {
    videoPlayerController = VideoPlayerController.network(video);
    chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      aspectRatio: videoPlayerController.value.aspectRatio,
      autoPlay: false,
      looping: false,
    );

    playerWidget = Chewie(
      controller: chewieController,
    );
    videoPlayerController
      ..addListener(() {
        final bool isPlaying = videoPlayerController.value.isPlaying;
        if (isPlaying != _isPlaying) {
          setState(() {
            _isPlaying = isPlaying;
          });
        }
      });
    videoPlayerController
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
  }

  @override
  void dispose() {
    if (videoPlayerController != null) videoPlayerController.dispose();
    if (_youtubeController != null) _youtubeController.dispose();
    if (_scrollController != null) _scrollController.dispose();

    if (chewieController != null) chewieController.dispose();
    super.dispose();
  }

  void loadPosts() async {
    this.posts = [];
    this.postsIDs = [];
    this.likes = [];
    this.dislikes = [];

    await postsRef.orderBy("timestamp").limit(10).getDocuments().then((snap) {
      for (int i = 0; i < snap.documents.length; i++) {
        setState(() {
          this.posts.add(snap.documents[i]);
          this.postsIDs.add(snap.documents[i].documentID);
          loadUserData(snap.documents[i].data['owner']);

          if (snap.documents[i].data['video'] != null) {
            playVideo(snap.documents[i].data['video']);
          }
        });
      }
      this.lastVisiblePostSnapShot =
          snap.documents[snap.documents.length - 1].data['timestamp'];
    });

    for (int j = 0; j < postsIDs.length; j++) {
      DocumentSnapshot likedSnapshot = await postsRef
          .document(postsIDs[j])
          .collection('likes')
          .document(currentUser.uid)
          .get();
      DocumentSnapshot dislikedSnapshot = await postsRef
          .document(postsIDs[j])
          .collection('dislikes')
          .document(currentUser.uid)
          .get();

      bool liked = likedSnapshot.exists;
      bool disliked = dislikedSnapshot.exists;
      setState(() {
        likes.add(liked);
        dislikes.add(disliked);
      });
    }
  }

  void loadCategorizedPosts() async {
    this.posts = [];
    this.postsIDs = [];
    this.likes = [];
    this.dislikes = [];

    await postsRef
        .orderBy("timestamp")
        .limit(10)
        .where('category', isEqualTo: selectedCategory)
        .getDocuments()
        .then((snap) {
      for (int i = 0; i < snap.documents.length; i++) {
        setState(() {
          this.posts.add(snap.documents[i]);
          this.postsIDs.add(snap.documents[i].documentID);
          loadUserData(snap.documents[i].data['owner']);

          if (snap.documents[i].data['video'] != null) {
            playVideo(snap.documents[i].data['video']);
          }
        });
      }
      this.lastVisiblePostSnapShot =
          snap.documents[snap.documents.length - 1].data['timestamp'];
    });

    for (int j = 0; j < postsIDs.length; j++) {
      DocumentSnapshot likedSnapshot = await postsRef
          .document(postsIDs[j])
          .collection('likes')
          .document(currentUser.uid)
          .get();
      DocumentSnapshot dislikedSnapshot = await postsRef
          .document(postsIDs[j])
          .collection('dislikes')
          .document(currentUser.uid)
          .get();

      bool liked = likedSnapshot.exists;
      bool disliked = dislikedSnapshot.exists;
      setState(() {
        likes.add(liked);
        dislikes.add(disliked);
      });
    }
  }

  void loadFollowingPosts() async {
    this.posts = [];
    this.postsIDs = [];
    this.likes = [];
    this.dislikes = [];

    if (following.length == 0) {
      await usersRef
          .document(currentUser.uid)
          .collection('following')
          .getDocuments()
          .then((snap) {
        for (int i = 0; i < snap.documents.length; i++) {
          this.following.add(snap.documents[i].documentID);
        }
      });
    }

    await postsRef
        .orderBy("timestamp")
        .limit(10)
        .where('owner', whereIn: following)
        .getDocuments()
        .then((snap) {
      for (int i = 0; i < snap.documents.length; i++) {
        setState(() {
          this.posts.add(snap.documents[i]);
          this.postsIDs.add(snap.documents[i].documentID);
          loadUserData(snap.documents[i].data['owner']);

          if (snap.documents[i].data['video'] != null) {
            playVideo(snap.documents[i].data['video']);
          }
        });
      }
      this.lastVisiblePostSnapShot =
          snap.documents[snap.documents.length - 1].data['timestamp'];
    });

    for (int j = 0; j < postsIDs.length; j++) {
      DocumentSnapshot likedSnapshot = await postsRef
          .document(postsIDs[j])
          .collection('likes')
          .document(currentUser.uid)
          .get();
      DocumentSnapshot dislikedSnapshot = await postsRef
          .document(postsIDs[j])
          .collection('dislikes')
          .document(currentUser.uid)
          .get();

      bool liked = likedSnapshot.exists;
      bool disliked = dislikedSnapshot.exists;
      setState(() {
        likes.add(liked);
        dislikes.add(disliked);
      });
    }
  }

  void nextPosts() async {
    await postsRef
        .orderBy("timestamp")
        .startAfter([this.lastVisiblePostSnapShot])
        .limit(10)
        .getDocuments()
        .then((snap) {
          for (int i = 0; i < snap.documents.length; i++) {
            setState(() {
              this.posts.add(snap.documents[i]);
              loadUserData(snap.documents[i].data['owner']);

              if (snap.documents[i].data['video'] != null) {
                playVideo(snap.documents[i].data['video']);
              }
            });
          }
          this.lastVisiblePostSnapShot =
              snap.documents[snap.documents.length - 1].data['timestamp'];
        });

    for (int j = 0; j < postsIDs.length; j++) {
      DocumentSnapshot likedSnapshot = await postsRef
          .document(postsIDs[j])
          .collection('likes')
          .document(currentUser.uid)
          .get();
      DocumentSnapshot dislikedSnapshot = await postsRef
          .document(postsIDs[j])
          .collection('dislikes')
          .document(currentUser.uid)
          .get();

      bool liked = likedSnapshot.exists;
      bool disliked = dislikedSnapshot.exists;
      likes.add(liked);
      dislikes.add(disliked);
    }
  }

  void nextCategorizedPosts() async {
    await postsRef
        .orderBy("timestamp")
        .startAfter([this.lastVisiblePostSnapShot])
        .limit(10)
        .where('category', isEqualTo: selectedCategory)
        .getDocuments()
        .then((snap) {
          for (int i = 0; i < snap.documents.length; i++) {
            setState(() {
              this.posts.add(snap.documents[i]);
              loadUserData(snap.documents[i].data['owner']);

              if (snap.documents[i].data['video'] != null) {
                playVideo(snap.documents[i].data['video']);
              }
            });
          }
          this.lastVisiblePostSnapShot =
              snap.documents[snap.documents.length - 1].data['timestamp'];
        });

    for (int j = 0; j < postsIDs.length; j++) {
      DocumentSnapshot likedSnapshot = await postsRef
          .document(postsIDs[j])
          .collection('likes')
          .document(currentUser.uid)
          .get();
      DocumentSnapshot dislikedSnapshot = await postsRef
          .document(postsIDs[j])
          .collection('dislikes')
          .document(currentUser.uid)
          .get();

      bool liked = likedSnapshot.exists;
      bool disliked = dislikedSnapshot.exists;
      likes.add(liked);
      dislikes.add(disliked);
    }
  }

  void nextFollowingPosts() async {
    await postsRef
        .orderBy("timestamp")
        .startAfter([this.lastVisiblePostSnapShot])
        .limit(10)
        .where('owner', whereIn: following)
        .getDocuments()
        .then((snap) {
          for (int i = 0; i < snap.documents.length; i++) {
            setState(() {
              this.posts.add(snap.documents[i]);
              loadUserData(snap.documents[i].data['owner']);

              if (snap.documents[i].data['video'] != null) {
                playVideo(snap.documents[i].data['video']);
              }
            });
          }
          this.lastVisiblePostSnapShot =
              snap.documents[snap.documents.length - 1].data['timestamp'];
        });

    for (int j = 0; j < postsIDs.length; j++) {
      DocumentSnapshot likedSnapshot = await postsRef
          .document(postsIDs[j])
          .collection('likes')
          .document(currentUser.uid)
          .get();
      DocumentSnapshot dislikedSnapshot = await postsRef
          .document(postsIDs[j])
          .collection('dislikes')
          .document(currentUser.uid)
          .get();

      bool liked = likedSnapshot.exists;
      bool disliked = dislikedSnapshot.exists;
      likes.add(liked);
      dislikes.add(disliked);
    }
  }

  Future loadUserData(String uid) async {
    await usersRef.document(uid).get().then((onValue) {
      setState(() {
        profileImages.add(onValue.data['profile_url']);
        usernames.add(onValue.data['username']);
      });
    });
  }

  Widget getList() {
    return ListView.builder(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Statics.filterPanel
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SizedBox(
                          height: 10,
                        ),
                        CupertinoSegmentedControl(
                          children: {0: Text('All'), 1: Text('Following')},
                          onValueChanged: (int value) {
                            setState(() {
                              if (value == 0) {
                                loadPosts();
                              } else if (value == 1) {
                                loadFollowingPosts();
                              }
                              allOrFollowing = value;
                            });
                          },
                          groupValue: allOrFollowing,
                        ),
                        (allOrFollowing == 0)
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Expanded(
                                    flex: 4,
                                    child: AutoCompleteTextField<String>(
                                      clearOnSubmit: false,
                                      key: autocompleteKey,
                                      suggestions: Constants.games,
                                      decoration: InputDecoration(
                                          icon: Icon(Icons.videogame_asset),
                                          hintText: "Category"),
                                      itemFilter: (item, query) {
                                        return item
                                            .toLowerCase()
                                            .startsWith(query.toLowerCase());
                                      },
                                      itemSorter: (a, b) {
                                        return a.compareTo(b);
                                      },
                                      itemSubmitted: (item) {
                                        setState(() {
                                          selectedCategory = item;
                                          loadCategorizedPosts();
                                        });
                                      },
                                      onFocusChanged: (hasFocus) {},
                                      itemBuilder: (context, item) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Container(
                                                color: Colors.grey.shade300,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      10.0),
                                                  child: Text(item),
                                                )),
                                            Container(
                                              width: double.infinity,
                                              color: Colors.grey,
                                              height: .5,
                                            )
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    color: Colors.blue,
                                    icon: Icon(Icons.close),
                                    onPressed: () {
                                      loadPosts();
                                      selectedCategory = null;
                                    },
                                  ),
                                ],
                              )
                            : Container()
                      ],
                    )
                  : Container(),
            ),
            Statics.filterPanel
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey,
                      height: 1,
                    ),
                  )
                : Container(),
            Container(
              color: Theme.of(context).primaryColor,
              child: getList(),
            ),
          ],
        ),
      ),
    );
  }

  _setupFeed() async {
    List<Post> posts = await DatabaseService.getPosts();
    setState(() {
      _posts = posts;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    videoPlayerController.dispose();
    _youtubeController.dispose();
  }

  @override
  void initState() {
    super.initState();

    getCurrentUser();

    _scrollController.addListener(() {
      if (_scrollController.position.atEdge) {
        if (_scrollController.position.pixels == 0) {
        } else {
          if (allOrFollowing == 0) {
            if (selectedCategory == null) {
              nextPosts();
            } else {
              nextCategorizedPosts();
            }
          } else if (allOrFollowing == 1) {
            nextFollowingPosts();
          }
        }
      }
    });

    _setupFeed();
  }
}
