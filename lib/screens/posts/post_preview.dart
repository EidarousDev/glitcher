import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/common_widgets/gradient_appbar.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/models/comment_model.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/screens/posts/comment_item.dart';
import 'package:glitcher/screens/posts/comment_post_item.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/Loader.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:video_player/video_player.dart';

class PostPreview extends StatefulWidget {
  final String postId;
  PostPreview({@required this.postId});
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
  bool _loading = true;
  bool _isPlaying = false;

  /// Instantiating required Widgets
  Chewie playerWidget;

  /// @param youtubeId for posts with an Embedded YouTube Video
  String _youtubeId;

  AnimationController _animationController;
  Animation _animation;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    loadPostData();
    super.initState();

    ///Set up listener here
    _scrollController.addListener(() {
      if (_scrollController.offset >=
              _scrollController.position.maxScrollExtent &&
          !_scrollController.position.outOfRange) {
        print('reached the bottom');
        //nextComments();
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
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void loadComments() async {
    List<Comment> comments = await DatabaseService.getComments(widget.postId);
    if (comments.length > 0) {
      setState(() {
        _comments = comments;
        this.lastVisibleCommentSnapShot = comments.last.timestamp;
        print('It"s actually here!');
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

  Future uploadComment() async {
    print('posting Comment...');
    setState(() {
      _loading = true;
    });

    DatabaseService.addComment(widget.postId, _commentText);

    setState(() {
      _loading = false;
    });
  }

  Widget getList() {
    return Flexible(
      fit: FlexFit.loose,
      child: StreamBuilder<QuerySnapshot>(
        stream: postsRef
            .document(widget.postId)
            ?.collection('comments')
            ?.snapshots(),
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
                      future:
                          DatabaseService.getUserWithId(comment.commenterID),
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
        },
      ),
    );
  }

  Widget _buildWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CommentPostItem(post: _currentPost, author: _author),
        getList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: true,
      appBar: AppBar(
        title: Text('New Comment'),
        flexibleSpace: gradientAppBar(),
      ),
      body: new InkWell(
        // to dismiss the keyboard when the user tabs out of the TextField
        splashColor: Colors.transparent,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.vertical,
          child: _loading ? Center(child: LoaderTwo()) : _buildWidget(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.comment,
          color: MyColors.darkGrey,
        ),
        onPressed: () {
          Navigator.of(context).pushNamed('/add-comment', arguments: {
            'post': _currentPost,
            'user': _author,
          });
        },
      ),
    );
  }

  void loadPostData() async {
    _currentPost = await DatabaseService.getPostWithId(widget.postId);
    _author = await DatabaseService.getUserWithId(_currentPost.authorId);
    print('currentPost = $_currentPost and author= $_author');
    loadComments();
    print('comments.length = ${_comments.length}');
    setState(() {
      _loading = false;
    });
  }
}
