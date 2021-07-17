import 'dart:typed_data';

import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/list_items/comment_item.dart';
import 'package:glitcher/list_items/post_item.dart';
import 'package:glitcher/models/comment_model.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:video_player/video_player.dart';

class PostPreview extends StatefulWidget {
  final Post post;
  PostPreview({@required this.post});
  @override
  _PostPreviewState createState() => _PostPreviewState();
}

class _PostPreviewState extends State<PostPreview>
    with SingleTickerProviderStateMixin {
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
  String _commentText;

  /// Screen Controllers
  final mainTextController = TextEditingController();
  var _scrollController = ScrollController();
  VideoPlayerController videoPlayerController;
  ChewieController chewieController;
  //TODO: Fix YouTube Player
  //YoutubePlayerController _youtubeController = YoutubePlayerController();

  /// Value Checkers
  bool _loading = false;
  bool _isPlaying = false;

  /// Instantiating required Widgets
  Chewie playerWidget;

  /// @param youtubeId for posts with an Embedded YouTube Video
  String _youtubeId;

  //AnimationController _animationController = AnimationController();
  Animation _animation;
  FocusNode _focusNode = FocusNode();

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  ByteData _swipeUpSFX;
  int _spawnedAudioCount = 0;

  @override
  void initState() {
    super.initState();

    loadPostData();

    ///Set up listener here
    _scrollController.addListener(() {
      if (_scrollController.offset >=
              _scrollController.position.maxScrollExtent &&
          !_scrollController.position.outOfRange) {
        print('reached the bottom');
        nextComments();
      } else if (_scrollController.offset <=
              _scrollController.position.minScrollExtent &&
          !_scrollController.position.outOfRange) {
        print("reached the top");
      } else {}
    });
  }

  @override
  void dispose() {
    //videoPlayerController.dispose();
    //chewieController.dispose();
    //_animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> loadComments() async {
    List<Comment> comments = await DatabaseService.getComments(widget.post.id);
    setState(() {
      _comments = comments;
    });
    if (comments.length > 0) {
      setState(() {
        this.lastVisibleCommentSnapShot = comments.last.timestamp;
        print('It"s actually here!');
      });
    }
  }

  nextComments() async {
    var comments = await DatabaseService.getNextComments(
        widget.post.id, lastVisibleCommentSnapShot);
    if (comments.length > 0) {
      setState(() {
        comments.forEach((element) => _comments.add(element));
        this.lastVisibleCommentSnapShot = comments.last.timestamp;
      });
    }
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

  Widget getList() {
    return Flexible(
      fit: FlexFit.loose,
      child: StreamBuilder<QuerySnapshot>(
        stream:
            postsRef.doc(widget.post.id)?.collection('comments')?.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator());
            default:
              return ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemCount: _comments.length,
                itemBuilder: (BuildContext context, int index) {
                  Comment comment = _comments[index];
                  return FutureBuilder(
                      future: DatabaseService.getUserWithId(comment.commenterID,
                          checkLocal: true),
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (!snapshot.hasData) {
                          return SizedBox.shrink();
                        }
                        User commenter = snapshot.data;
                        //print('commenter: $commenter and comment: $comment');
                        return CommentItem(
                          post: widget.post,
                          comment: comment,
                          commenter: commenter,
                          isReply: false,
                        );
                      });
                },
              );
          }
        },
      ),
    );
  }

  AudioPlayer audioPlayer = AudioPlayer();
  void _onRefresh() async {
    audioPlayer
        .setAsset(Strings.swipe_up_to_reload)
        .then((value) => audioPlayer.play());

    loadPostData();
    loadComments();
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

  Widget _buildWidget() {
    return _currentPost != null
        ? Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PostItem(post: _currentPost, author: _author),
              _comments.length > 0
                  ? getList()
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 32.0),
                        child: Text('Be the first to comment...'),
                      ),
                    ),
            ],
          )
        : Center(
            heightFactor: 20,
            child: Text(
              'This post has been deleted',
              style: TextStyle(fontSize: 20),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          leading: new IconButton(
            icon: new Icon(Icons.arrow_back),
            onPressed: () {
              _onBackPressed();
            },
          ),
          title: Text('Post Preview'),
          flexibleSpace: gradientAppBar(),
        ),
        body: SmartRefresher(
          controller: _refreshController,
          enablePullDown: true,
          header: WaterDropHeader(),
          onRefresh: _onRefresh,
          onLoading: _onLoading,
          child: new InkWell(
            // to dismiss the keyboard when the user tabs out of the TextField
            splashColor: Colors.transparent,
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.vertical,
              child: _loading
                  ? Center(
                      child: Center(
                          child: Image.asset(
                      'assets/images/glitcher_loader.gif',
                      height: 250,
                      width: 250,
                    )))
                  : _buildWidget(),
            ),
          ),
        ),
//      floatingActionButton: FloatingActionButton(
//        child: Icon(
//          Icons.comment,
//          color: Colors.white70,
//        ),
//        onPressed: () {
//          Navigator.of(context).pushNamed('/add-comment', arguments: {
//            'post': _currentPost,
//            'user': _author,
//          });
//        },
//      ),
      ),
    );
  }

  void loadPostData() async {
    if (widget.post.id == null) {
      _currentPost = null;
      return;
    }

    setState(() {
      _loading = true;
    });
    _currentPost = await DatabaseService.getPostWithId(widget.post.id);
    _author = await DatabaseService.getUserWithId(_currentPost.authorId,
        checkLocal: true);
    print('currentPost = $_currentPost and author= $_author');
    await loadComments();
    print('comments.length = ${_comments.length}');
    setState(() {
      _loading = false;
    });
  }

  Future<bool> _onBackPressed() {
    Constants.routesStack.pop();
    Navigator.of(context).pop();
  }
}
