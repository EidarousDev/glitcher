import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class HomeBody extends StatefulWidget {
  @override
  _HomeBodyState createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  Firestore _firestore = Firestore.instance;

  var posts = [];
  Timestamp lastVisiblePostSnapShot;
  var postsRef;

  var profileimages = [];
  var names = ['ahmed'];
  var usernames = [];
  var replies = ['1'];
  var retweets = ['10'];
  var likes = ['50'];

  YoutubePlayerController _youtubeController = YoutubePlayerController();
  bool _isPlaying;
  VideoPlayerController videoPlayerController;
  ChewieController chewieController;
  Chewie playerWidget;
  FirebaseUser currentUser;

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
    videoPlayerController.dispose();
    chewieController.dispose();
    super.dispose();
  }

  void loadPosts() async {
    await _firestore
        .collection("posts")
        .orderBy("timestamp")
        .limit(10)
        .getDocuments()
        .then((snap) {
      for (int i = 0; i < snap.documents.length; i++) {
        setState(() {
          this.posts.add(snap.documents[i].data);
          loadUserData(snap.documents[i].data['owner']);

          if (posts[i]['video'] != null) {
            playVideo(posts[i]['video']);
          }
        });
      }

      this.lastVisiblePostSnapShot =
          snap.documents[snap.documents.length - 1].data['timestamp'];
    });
  }

  void loadUserData(String uid) async {
    await _firestore.collection('users').document(uid).get().then((onValue) {
      setState(() {
        profileimages.add(onValue.data['profile_url']);
        usernames.add(onValue.data['name']);
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
              this.posts.add(snap.documents[i].data);
              loadUserData(snap.documents[i].data['owner']);

              if (posts[i]['video'] != null) {
                playVideo(posts[i]['video']);
              }
            });
          }
          this.lastVisiblePostSnapShot =
              snap.documents[snap.documents.length - 1].data['timestamp'];
        });
  }

  prev() async {
    this.posts = [];
    var query = await this
        .postsRef
        .orderBy("city")
        .endBefore(this.lastVisiblePostSnapShot)
        .limit(10);
    query.get().then((snap) {
      snap.forEach((doc) {
        this.posts.add(doc.data());
      });
      this.lastVisiblePostSnapShot = snap.docs[snap.docs.length - 1];
    });
  }

  Widget getList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: posts.length,
      itemBuilder: (context, index) => Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 40.0,
                  height: 40.0,
                  decoration: new BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      fit: BoxFit.fitHeight,
                      image: NetworkImage(profileimages[index]),
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
                                names[0],
                                style: TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  usernames[index],
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
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
                          posts.length > 0 ? posts[index]['text'] : '',
                          style: TextStyle(
                            color: Colors.black54,
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
                                    child:
                                        Image.network(posts[index]['image'])),
                              ),
                      ),
                      Container(
                        child:
                            posts[index]['video'] == null ? null : playerWidget,
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
                                      Icons.chat_bubble_outline,
                                      size: 18.0,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {},
                                  ),
                                ),
                                SizedBox(
                                    height: 14.0,
                                    width: 18.0,
                                    child: Text(
                                      replies[0],
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                SizedBox(
                                  height: 14.0,
                                  width: 18.0,
                                  child: IconButton(
                                    padding: new EdgeInsets.all(0.0),
                                    icon: Icon(
                                      Icons.favorite_border,
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
                                      likes[0],
                                      style: TextStyle(color: Colors.grey),
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
              height: 0.5,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      child: getList(),
    );
  }

  @override
  void initState() {
    super.initState();

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
