import 'package:assets_audio_player/assets_audio_player.dart';
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
import 'package:glitcher/screens/new_comment.dart';
import 'package:glitcher/screens/profile_screen.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/auth.dart';
import 'package:glitcher/utils/constants.dart';
import 'package:glitcher/utils/statics.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:soundpool/soundpool.dart';

class HomeBody extends StatefulWidget {
  @override
  _HomeBodyState createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
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
  AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();
  YoutubePlayerController _youtubeController = YoutubePlayerController();
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
      autoPlay: true,
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

  void listener() {
    if (_youtubeController.value.playerState == PlayerState.ENDED) {
      //_showThankYouDialog();
    }
    if (mounted) {
      setState(() {
        //_playerStatus = _youtubeController.value.playerState.toString();
        //_errorCode = _youtubeController.value.errorCode.toString();
      });
    }
  }

  @override
  void dispose() {
    if (videoPlayerController != null) videoPlayerController.dispose();

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
              return _buildPost(post, author);
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
                          suggestions: Constants.categories,
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

  _buildPost(Post post, User author) {
    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ProfileScreen(userId: post.authorId)));
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  radius: 25.0,
                  backgroundColor: Colors.grey,
                  backgroundImage: author.profileImageUrl.isEmpty
                      ? AssetImage('assets/images/default_profile.png')
                      : CachedNetworkImageProvider(author.profileImageUrl),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              author.username ?? '',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey,
                        )
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 0.0, bottom: 8.0),
                      child: Text(
                        post.text ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      child: post.imageUrl == null
                          ? null
                          : Container(
                        width: double.infinity,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(post.imageUrl)),
                      ),
                    ),
                    Container(
                      child: post.video == null ? null : playerWidget,
                    ),
                    Container(
                      child: post.youtubeId == null
                          ? null
                          : YoutubePlayer(
                        context: context,
                        videoId: post.youtubeId,
                        flags: YoutubePlayerFlags(
                          autoPlay: false,
                          showVideoProgressIndicator: true,
                        ),
                        videoProgressIndicatorColor: Colors.red,
                        progressColors: ProgressColors(
                          playedColor: Colors.red,
                          handleColor: Colors.redAccent,
                        ),
                        onPlayerInitialized: (controller) {
                          _youtubeController = controller;
                          _youtubeController.addListener(listener);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                height: 14.0,
                                width: 18.0,
                                child: IconButton(
                                  padding: new EdgeInsets.all(0.0),
                                  icon: Icon(
                                    FontAwesome.getIconData('thumbs-o-up'),
                                    size: 18.0,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () async {
                                    assetsAudioPlayer.open(AssetsAudio(
                                      asset: "like_sound.mp3",
                                      folder: "assets/sounds/",
                                    ));
                                    assetsAudioPlayer.play();

                                    //Likes Handling was here
                                  },
                                ),
                              ),
                              SizedBox(
                                  height: 14.0,
                                  width: 18.0,
                                  child: Text(
                                    post.likesCount.toString(),
                                    style: TextStyle(color: Colors.grey),
                                  )),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                height: 14.0,
                                width: 18.0,
                                child: IconButton(
                                  padding: new EdgeInsets.all(0.0),
                                  icon: Icon(
                                    FontAwesome.getIconData('thumbs-o-down'),
                                    size: 18.0,
                                    color: Colors.black54,
                                  ),
                                  onPressed: () {
                                    assetsAudioPlayer.open(AssetsAudio(
                                      asset: "dislike_sound.mp3",
                                      folder: "assets/sounds/",
                                    ));
                                    assetsAudioPlayer.play();
                                    //Dislikes Handling was here
                                  },
                                ),
                              ),
                              SizedBox(
                                  height: 14.0,
                                  width: 18.0,
                                  child: Text(
                                    post.disLikesCount.toString(),
                                    style: TextStyle(color: Colors.grey),
                                  )),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                height: 14.0,
                                width: 18.0,
                                child: IconButton(
                                  padding: new EdgeInsets.all(0.0),
                                  icon: Icon(
                                    Icons.chat_bubble_outline,
                                    size: 18.0,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => NewComment(
                                              postId: post.id,
                                              commentsNo:
                                              post.commentsCount,
                                            )));
                                  },
                                ),
                              ),
                              SizedBox(
                                  height: 14.0,
                                  width: 18.0,
                                  child: Text(
                                    post.commentsCount.toString(),
                                    style: TextStyle(color: Colors.black54),
                                  )),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                height: 14.0,
                                width: 18.0,
                                child: IconButton(
                                  padding: new EdgeInsets.all(0.0),
                                  icon: Icon(
                                    Icons.replay,
                                    size: 18.0,
                                    color: Colors.black54,
                                  ),
                                  onPressed: () {},
                                ),
                              ),
                              SizedBox(
                                  height: 14.0,
                                  width: 18.0,
                                  child: Text(
                                    retweets[0],
                                    style: TextStyle(color: Colors.black54),
                                  )),
                            ],
                          ),
                          SizedBox(
                            height: 14.0,
                            width: 10.0,
                            child: IconButton(
                              padding: new EdgeInsets.all(0.0),
                              icon: Icon(
                                Icons.share,
                                size: 18.0,
                                color: Colors.grey,
                              ),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            width: double.infinity,
            color: Colors.grey,
            height: .5,
          ),
        )
      ],
    );
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