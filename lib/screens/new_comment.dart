import 'package:chewie/chewie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/screens/home/home.dart';
import 'package:glitcher/screens/home/home_body.dart';
import 'package:glitcher/utils/Loader.dart';
import 'package:glitcher/utils/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class NewComment extends StatefulWidget {
  NewComment currentUser;
  String postId;
  int commentsNo;
  NewComment({this.postId, this.commentsNo});
  @override
  _NewCommentState createState() =>
      _NewCommentState(postId: postId, commentsNo: commentsNo);
}

class _NewCommentState extends State<NewComment> {
  var comments = [];
  var lastVisibleCommentSnapShot;
  var _postText;

  var profileImage;

  String username;

  var commenterProfileimages = [];

  var commenters = [];

  _NewCommentState({this.postId, this.commentsNo});

  FirebaseUser currentUser;
  final mainTextController = TextEditingController();
  bool _loading = false;
  var _firestore = Firestore.instance;
  String commentText;
  String postId;
  int commentsNo;

  var _image;
  var _video;
  bool _isPlaying;
  VideoPlayerController videoPlayerController;
  ChewieController chewieController;
  Chewie playerWidget;

  String _youtubeId;
  YoutubePlayerController _youtubeController = YoutubePlayerController();
  var _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    getCurrentUser();
    loadPost(postId);
  }

  @override
  void dispose() {
    videoPlayerController.dispose();
    chewieController.dispose();
    super.dispose();
  }

  void loadComments() async {
    await _firestore
        .collection("posts")
        .document(postId)
        .collection('comments')
        .orderBy("timestamp")
        .limit(3)
        .getDocuments()
        .then((snap) {
      for (int i = 0; i < snap.documents.length; i++) {
        setState(() {
          this.comments.add(snap.documents[i]);
          loadCommenterData(snap.documents[i].data['commenter']);
        });
      }
      this.lastVisibleCommentSnapShot =
          snap.documents[snap.documents.length - 1].data['timestamp'];
    });
  }

  nextComments() async {
    await _firestore
        .collection("posts")
        .document(postId)
        .collection('comments')
        .orderBy("timestamp")
        .startAfter([this.lastVisibleCommentSnapShot])
        .limit(3)
        .getDocuments()
        .then((snap) {
      for (int i = 0; i < snap.documents.length; i++) {
        setState(() {
          this.comments.add(snap.documents[i]);
          loadCommenterData(snap.documents[i].data['commenter']);
        });
      }
      this.lastVisibleCommentSnapShot =
      snap.documents[snap.documents.length - 1].data['timestamp'];
    });
  }

  void loadPosterData(String uid) async {
    await _firestore.collection('users').document(uid).get().then((onValue) {
      setState(() {
        profileImage = onValue.data['profile_url'];
        username = onValue.data['username'];
      });
    });
  }

  void loadCommenterData(String uid) async {
    await _firestore.collection('users').document(uid).get().then((onValue) {
      setState(() {
        commenterProfileimages.add(onValue.data['profile_url']);
        commenters.add(onValue.data['username']);
      });
    });
  }

  void loadPost(String uid) async {
    await _firestore.collection('posts').document(postId).get().then((onValue) {
      setState(() {
        _image = onValue.data['image'];
        _video = onValue.data['video'];
        _youtubeId = onValue.data['youtubeId'];
        _postText = onValue.data['text'];
        loadPosterData(onValue.data['owner']);
        loadComments();
        if (_video != null) {
          playVideo();
        }
      });
    });
  }

  void playVideo() {
    videoPlayerController = VideoPlayerController.file(_video);
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

  Future uploadComment(String text) async {
    setState(() {
      _loading = true;
    });
    commentText = mainTextController.text;
    await _firestore
        .collection('posts')
        .document(postId)
        .collection('comments')
        .add({
      'commenter': currentUser.uid,
      'text': commentText,
      'timestamp': FieldValue.serverTimestamp()
    }).then((_) {
      setState(() {
        _loading = false;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomePage()));
      });
    });

    await _firestore
        .collection('posts')
        .document(postId)
        .updateData({'comments': commentsNo + 1});
  }

  void getCurrentUser() async {
    this.currentUser = await Auth().getCurrentUser();
  }

  Widget getList() {
    return ListView.builder(
        controller: _scrollController,
        itemCount: comments.length,
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
                            image: NetworkImage(commenterProfileimages[index]),
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
                                      commenters[index],
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
                              padding:
                                  const EdgeInsets.only(top: 0.0, bottom: 8.0),
                              child: Text(
                                comments.length > 0
                                    ? comments[index].data['text']
                                    : '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
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
            ));
  }

  Widget _buildWidget() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            profileImage != null
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 60.0,
                          height: 60.0,
                          decoration: new BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              fit: BoxFit.fitHeight,
                              image: NetworkImage(profileImage),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Text(
                                        username,
                                        style: TextStyle(
                                          fontSize: 16,
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
                                padding: const EdgeInsets.only(
                                    top: 0.0, bottom: 8.0),
                                child: Text(
                                  _postText,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Container(
                                child: _image == null
                                    ? null
                                    : Container(
                                        width: double.infinity,
                                        child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: Image.network(_image)),
                                      ),
                              ),
                              Container(
                                child: _video == null ? null : playerWidget,
                              ),
                              Container(
                                child: _youtubeId == null
                                    ? null
                                    : YoutubePlayer(
                                        context: context,
                                        videoId: _youtubeId,
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
                                          _youtubeController
                                              .addListener(listener);
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  )
                : Container(),
            Container(
              height: 200,
              child: getList(),
            ),

            GestureDetector(
              onTap: (){
                nextComments();
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  child: Text(
                    'Load more',
                    style: TextStyle(color: Colors.blue),
                  ),
                  alignment: Alignment.center,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: mainTextController,
                decoration: new InputDecoration.collapsed(
                    hintText: 'What\'s in your mind?'),
                minLines: 1,
                maxLines: 5,
                autocorrect: true,
                autofocus: true,
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              child: RaisedButton(
                  child: Text('Post Comment'),
                  textColor: Colors.white,
                  color: Colors.blue,
                  onPressed: () {
                    uploadComment(mainTextController.text);
                  }),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Comment'),
      ),
      body: Stack(
        alignment: Alignment(0, 0),
        children: <Widget>[
          _buildWidget(),
          _loading
              ? LoaderTwo()
              : Container(
                  width: 0,
                  height: 0,
                ),
        ],
      ),
    );
  }
}
