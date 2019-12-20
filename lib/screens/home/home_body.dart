import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:glitcher/screens/new_comment.dart';
import 'package:glitcher/screens/profile_screen.dart';
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
  Firestore _firestore = Firestore.instance;

  var posts = [];
  var postsIDs = [];
  Timestamp lastVisiblePostSnapShot;
  var postsRef;

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

    await _firestore
        .collection("posts")
        .orderBy("timestamp")
        .limit(10)
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
      DocumentSnapshot likedSnapshot = await _firestore
          .collection('posts')
          .document(postsIDs[j])
          .collection('likes')
          .document(currentUser.uid)
          .get();
      DocumentSnapshot dislikedSnapshot = await _firestore
          .collection('posts')
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

  void loadFilteredPosts() async {
    this.posts = [];
    this.postsIDs = [];
    this.likes = [];
    this.dislikes = [];

    await _firestore
        .collection("posts")
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
      DocumentSnapshot likedSnapshot = await _firestore
          .collection('posts')
          .document(postsIDs[j])
          .collection('likes')
          .document(currentUser.uid)
          .get();
      DocumentSnapshot dislikedSnapshot = await _firestore
          .collection('posts')
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

  void loadUserData(String uid) async {
    await _firestore.collection('users').document(uid).get().then((onValue) {
      setState(() {
        profileImages.add(onValue.data['profile_url']);
        usernames.add(onValue.data['username']);
      });
    });
  }

  nextPosts() async {
    await _firestore
        .collection("posts")
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
      DocumentSnapshot likedSnapshot = await _firestore
          .collection('posts')
          .document(postsIDs[j])
          .collection('likes')
          .document(currentUser.uid)
          .get();
      DocumentSnapshot dislikedSnapshot = await _firestore
          .collection('posts')
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

  Widget getList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: posts.length,
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemBuilder: (context, index) => Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              GestureDetector(
                onTap: (){
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                          )));
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: new BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        fit: BoxFit.fitHeight,
                        image: NetworkImage(profileImages[index]),
                      ),
                    ),
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
                                usernames[index],
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
                          posts.length > 0 ? posts[index].data['text'] : '',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        child: posts[index]['image'] == null
                            ? null
                            : Container(
                                width: double.infinity,
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                        posts[index].data['image'])),
                              ),
                      ),
                      Container(
                        child: posts[index].data['video'] == null
                            ? null
                            : playerWidget,
                      ),
                      Container(
                        child: posts[index].data['youtubeId'] == null
                            ? null
                            : YoutubePlayer(
                                context: context,
                                videoId: posts[index].data['youtubeId'],
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
                                      likes[index]
                                          ? FontAwesome.getIconData('thumbs-up')
                                          : FontAwesome.getIconData(
                                              'thumbs-o-up'),
                                      size: 18.0,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () async {
                                      assetsAudioPlayer.open(AssetsAudio(
                                        asset: "like_sound.mp3",
                                        folder: "assets/sounds/",
                                      ));
                                      assetsAudioPlayer.play();

                                      setState(() {
                                        if (likes[index]) {
                                          likes[index] = false;
                                          posts[index].data['likes']--;
                                          _firestore
                                              .collection('posts')
                                              .document(postsIDs[index])
                                              .collection('likes')
                                              .document(currentUser.uid)
                                              .delete();
                                          _firestore
                                              .collection('posts')
                                              .document(postsIDs[index])
                                              .updateData(posts[index].data);
                                        } else {
                                          if (dislikes[index]) {
                                            dislikes[index] = false;
                                            posts[index].data['dislikes']--;
                                            _firestore
                                                .collection('posts')
                                                .document(postsIDs[index])
                                                .collection('dislikes')
                                                .document(currentUser.uid)
                                                .delete();
                                          }
                                          likes[index] = true;
                                          posts[index].data['likes']++;
                                          _firestore
                                              .collection('posts')
                                              .document(postsIDs[index])
                                              .collection('likes')
                                              .document(currentUser.uid)
                                              .setData({
                                            'timestamp':
                                                FieldValue.serverTimestamp()
                                          });
                                          _firestore
                                              .collection('posts')
                                              .document(postsIDs[index])
                                              .updateData(posts[index].data);
                                        }
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(
                                    height: 14.0,
                                    width: 18.0,
                                    child: Text(
                                      posts[index].data['likes'].toString(),
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
                                      dislikes[index]
                                          ? FontAwesome.getIconData(
                                              'thumbs-down')
                                          : FontAwesome.getIconData(
                                              'thumbs-o-down'),
                                      size: 18.0,
                                      color: Colors.black54,
                                    ),
                                    onPressed: () {
                                      assetsAudioPlayer.open(AssetsAudio(
                                        asset: "dislike_sound.mp3",
                                        folder: "assets/sounds/",
                                      ));
                                      assetsAudioPlayer.play();
                                      setState(() {
                                        if (dislikes[index]) {
                                          dislikes[index] = false;
                                          posts[index].data['dislikes']--;
                                          _firestore
                                              .collection('posts')
                                              .document(postsIDs[index])
                                              .collection('dislikes')
                                              .document(currentUser.uid)
                                              .delete();
                                          _firestore
                                              .collection('posts')
                                              .document(postsIDs[index])
                                              .updateData(posts[index].data);
                                        } else {
                                          if (likes[index]) {
                                            likes[index] = false;
                                            posts[index].data['likes']--;
                                            _firestore
                                                .collection('posts')
                                                .document(postsIDs[index])
                                                .collection('likes')
                                                .document(currentUser.uid)
                                                .delete();
                                          }
                                          dislikes[index] = true;
                                          posts[index].data['dislikes']++;
                                          _firestore
                                              .collection('posts')
                                              .document(postsIDs[index])
                                              .collection('dislikes')
                                              .document(currentUser.uid)
                                              .setData({
                                            'timestamp':
                                                FieldValue.serverTimestamp()
                                          });
                                          _firestore
                                              .collection('posts')
                                              .document(postsIDs[index])
                                              .updateData(posts[index].data);
                                        }
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(
                                    height: 14.0,
                                    width: 18.0,
                                    child: Text(
                                      posts[index].data['dislikes'].toString(),
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
                                                    postId: postsIDs[index],
                                                    commentsNo: posts[index]
                                                        ['comments'],
                                                  )));
                                    },
                                  ),
                                ),
                                SizedBox(
                                    height: 14.0,
                                    width: 18.0,
                                    child: Text(
                                      posts[index]['comments'].toString(),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Statics.filterPanel
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
                      loadFilteredPosts();
                    });
                  },
                  onFocusChanged: (hasFocus) {},
                  itemBuilder: (context, item) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                            color: Colors.grey.shade300,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
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
                onPressed: (){
                  loadPosts();
                },
              )
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
          nextPosts();
        }
      }
    });

    loadPosts();
  }
}
