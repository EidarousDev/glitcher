import 'package:chewie/chewie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/models/comment_model.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/screens/home/home.dart';
import 'package:glitcher/screens/home/home_body.dart';
import 'package:glitcher/screens/posts/comment_item.dart';
import 'package:glitcher/screens/posts/post_item.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/Loader.dart';
import 'package:glitcher/services/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glitcher/utils/constants.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class NewComment extends StatefulWidget {
  final String postId;
  final int commentsNo;
  NewComment({@required this.postId, this.commentsNo});
  @override
  _NewCommentState createState() => _NewCommentState();
}

class _NewCommentState extends State<NewComment> {
  /// Post Data
  Post _currentPost;

  /// author Data
  /// @param authorAvatar for profileImageURL;
  /// @param authorUsername;
  /// @param author for User object;
  User _author; // The owner of the post
  //var profileImage;
  String username;

  /// Comments Data
  var _comments = [];
  var lastVisibleCommentSnapShot;

  /// Commenters Data
  var commenters = [];
  var commenterProfileimages = [];

  /// Submit Comment Data
  String commentText;

  /// Screen Controllers
  final mainTextController = TextEditingController();
  var _scrollController = ScrollController();
  VideoPlayerController videoPlayerController;
  ChewieController chewieController;
  //TODO: Fix YouTube Player
  //YoutubePlayerController _youtubeController = YoutubePlayerController();

  /// Value Checkers
  bool _loading = true;
  bool _isPlaying = false;

  /// Instantiating required Widgets
  Chewie playerWidget;

  /// @param youtubeId for posts with an Embedded YouTube Video
  String _youtubeId;

  @override
  void initState() {
    super.initState();
    loadPostData();
  }

  @override
  void dispose() {
    //videoPlayerController.dispose();
    //chewieController.dispose();
    super.dispose();
  }

  void loadComments() async {
    List<Comment> comments = await DatabaseService.getComments(widget.postId);
    setState(() {
      _comments = comments;
      this.lastVisibleCommentSnapShot = comments.last.timestamp;
    });
  }

  void playVideo() {
    videoPlayerController = VideoPlayerController.file(_currentPost.video);
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
//    if (_youtubeController.value.playerState == PlayerState.ENDED) {
//      //_showThankYouDialog();
//    }
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
    await firestore
        .collection('posts')
        .document(widget.postId)
        .collection('comments')
        .add({
      'commenter': Constants.currentUserID,
      'text': commentText,
      'timestamp': FieldValue.serverTimestamp()
    }).then((_) {
      setState(() {
        _loading = false;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomePage()));
      });
    });

    await firestore
        .collection('posts')
        .document(widget.postId)
        .updateData({'comments': widget.commentsNo + 1});
  }

  Widget getList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _comments.length,
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemBuilder: (BuildContext context, int index) {
        Comment comment = _comments[index];
        return FutureBuilder(
            future: DatabaseService.getUserWithId(comment.commenterID),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (!snapshot.hasData) {
                return SizedBox.shrink();
              }
              User commenter = snapshot.data;
              print('commenter: $commenter and comment: $comment');
              return CommentItem(
                comment: comment,
                commenter: commenter,
              );
            });
      },
    );
  }

  Widget _buildWidget() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PostItem(post: _currentPost, author: _author),
            SizedBox(
              height: 1,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: currentTheme == AvailableThemes.LIGHT_THEME
                        ? Constants.lightLineBreak
                        : Constants.darkLineBreak),
              ),
            ),
            Container(
              height: 200,
              child: getList(),
            ),
            GestureDetector(
              onTap: () {
                //nextComments();
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
      body: Column(
        children: <Widget>[
          _loading
              ? Center(child: LoaderTwo())
              : Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10.0, horizontal: 0),
                  child: _buildWidget(),
                ),
        ],
      ),
    );
  }

  void loadPostData() async {
    _currentPost = await DatabaseService.getPostWithId(widget.postId);
    _author = await DatabaseService.getUserWithId(_currentPost.authorId);
    //print('currentPost = $_currentPost and author= $_author');
    loadComments();
    _loading = false;
  }
}
