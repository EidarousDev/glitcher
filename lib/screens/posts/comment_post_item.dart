import 'package:cache_image/cache_image.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/notification_handler.dart';
import 'package:glitcher/services/share_link.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:share/share.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class CommentPostItem extends StatefulWidget {
  final Post post;
  final User author;

  CommentPostItem({Key key, @required this.post, @required this.author})
      : super(key: key);
  @override
  _CommentPostItemState createState() => _CommentPostItemState();
}

class _CommentPostItemState extends State<CommentPostItem> {
  YoutubePlayerController _youtubeController;
  bool _isPlaying;
  VideoPlayerController videoPlayerController;
  ChewieController chewieController;
  Chewie playerWidget;
  String dropdownValue = 'Edit';

  bool isLiked = false;
  bool isDisliked = false;
  var likes = [];
  var dislikes = [];
  NotificationHandler notificationHandler = NotificationHandler();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: _buildPost(widget.post, widget.author),
    );
  }

  _buildPost(Post post, User author) {
    initLikes(post);
    return Column(
      children: <Widget>[
        ListTile(
          contentPadding: EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
          leading: InkWell(
              child: CircleAvatar(
                radius: 25.0,
                backgroundColor: Colors.grey,
                backgroundImage: loggedInProfileImageURL != null
                    ? CacheImage(loggedInProfileImageURL)
                    : AssetImage('assets/images/default_profile.png'),
              ),
              onTap: () {
                Navigator.of(context).pushNamed('/user-profile', arguments: {
                  'userId': post.authorId,
                });
              }),
          title: InkWell(
            child: Text('@${author.username}' ?? '',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Constants.darkPrimary)),
            onTap: () {
              Navigator.of(context).pushNamed('/user-profile', arguments: {
                'userId': author.id,
              });
            },
          ),
          subtitle: InkWell(
            child: Text('↳ ${post.game}' ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Constants.darkGrey,
                )),
            onTap: () {
              Navigator.of(context).pushNamed('/user-profile', arguments: {
                'userId': author.id,
              });
            },
          ),
          trailing: InkWell(
              onTap: dropDownOptions(), child: Icon(Icons.keyboard_arrow_down)),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      post.text ?? '',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(
                      height: 8.0,
                    ),
                    Container(
                      child: post.imageUrl == null
                          ? null
                          : Container(
                              width: double.infinity,
                              height: Sizes.home_post_image_h,
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    post.imageUrl,
                                    fit: BoxFit.fill,
                                  )),
                            ),
                    ),
                    Container(
                      child: post.video == null ? null : playerWidget,
                    ),
                    Container(child: null
                        //TODO: Fix YouTube Player
//                      post.youtubeId == null
//                          ? null
//                          : YoutubePlayer(
//                              context: context,
//                              videoId: post.youtubeId,
//                              flags: YoutubePlayerFlags(
//                                autoPlay: false,
//                                showVideoProgressIndicator: true,
//                                forceHideAnnotation: true,
//                              ),
//                              videoProgressIndicatorColor: Colors.red,
//                              progressColors: ProgressColors(
//                                playedColor: Colors.red,
//                                handleColor: Colors.redAccent,
//                              ),
//                              onPlayerInitialized: (controller) {
//                                _youtubeController = controller;
//                                _youtubeController.addListener(listener);
//                              },
//                            ),
                        ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "${Functions.formatTimestamp(post.timestamp)}",
                        style: TextStyle(
                            fontSize: 13.0, color: Constants.darkGrey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 1.0,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
                color: currentTheme == AvailableThemes.LIGHT_THEME
                    ? Constants.lightLineBreak
                    : Constants.darkLineBreak),
          ),
        ),
        Container(
          height: inlineBreak,
          color: currentTheme == AvailableThemes.LIGHT_THEME
              ? Constants.lightPrimary
              : Constants.darkAccent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              InkWell(
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      height: 14.0,
                      width: 18.0,
                      child: IconButton(
                        onPressed: () {},
                        padding: new EdgeInsets.all(0.0),
                        icon: isLiked
                            ? Icon(
                                FontAwesome.getIconData('thumbs-up'),
                                size: 18.0,
                                color: Colors.blue,
                              )
                            : Icon(
                                FontAwesome.getIconData('thumbs-o-up'),
                                size: 18.0,
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Text(
                        post.likesCount.toString(),
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  //playSound('like_sound.mp3');
                  likeBtnHandler(post);
                },
              ),
              SizedBox(
                width: 1.0,
                height: inlineBreak,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: currentTheme == AvailableThemes.LIGHT_THEME
                          ? Constants.lightInLineBreak
                          : Constants.darkLineBreak),
                ),
              ),
              InkWell(
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      height: 14.0,
                      width: 18.0,
                      child: IconButton(
                        onPressed: () {},
                        padding: new EdgeInsets.all(0.0),
                        icon: isDisliked
                            ? Icon(
                                FontAwesome.getIconData('thumbs-down'),
                                size: 18.0,
                                color: Colors.blue,
                              )
                            : Icon(
                                FontAwesome.getIconData('thumbs-o-down'),
                                size: 18.0,
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Text(
                        post.disLikesCount.toString(),
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  //playSound('dislike_sound.mp3');
                  dislikeBtnHandler(post);
                },
              ),
              SizedBox(
                width: 1.0,
                height: inlineBreak,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: currentTheme == AvailableThemes.LIGHT_THEME
                          ? Constants.lightInLineBreak
                          : Constants.darkLineBreak),
                ),
              ),
              SizedBox(
                height: 14.0,
                width: 18.0,
                child: IconButton(
                  padding: new EdgeInsets.all(0.0),
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    size: 18.0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/post', arguments: {
                      'postId': post.id,
                      'commentsNo': post.commentsCount
                    });
                  },
                ),
              ),
              SizedBox(
                  height: 14.0,
                  width: 18.0,
                  child: Text(
                    post.commentsCount.toString(),
                  )),
              SizedBox(
                width: 1.0,
                height: inlineBreak,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: currentTheme == AvailableThemes.LIGHT_THEME
                          ? Constants.lightInLineBreak
                          : Constants.darkLineBreak),
                ),
              ),
              InkWell(
                child: SizedBox(
                  height: 14.0,
                  width: 18.0,
                  child: IconButton(
                    onPressed: () {},
                    padding: new EdgeInsets.all(0.0),
                    icon: Icon(
                      Icons.share,
                      size: 18.0,
                    ),
                  ),
                ),
                onTap: () {
                  sharePost(post.id, post.text, post.imageUrl);
                },
              ),
            ],
          ),
        ),
        SizedBox(
          height: 2.0,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
                color: currentTheme == AvailableThemes.LIGHT_THEME
                    ? Constants.lightLineBreak
                    : Constants.darkLineBreak),
          ),
        ),
      ],
    );
  }

  // Sharing a post with a shortened url
  void sharePost(String postId, String postText, String imageUrl) async {
    var postLink = await DynamicLinks.createDynamicLink(
        {'postId': postId, 'postText': postText, 'imageUrl': imageUrl});
    Share.share('Check out: $postText : $postLink');
    print('Check out: $postText : $postLink');
  }

  // Youtube Video listener
  void listener() {
//    if (_youtubeController.value.playerState == PlayerState.ENDED) {
//      //_showThankYouDialog();
//    }
    if (mounted) {
//      setState(() {
//        //_playerStatus = _youtubeController.value.playerState.toString();
//        //_errorCode = _youtubeController.value.errorCode.toString();
//      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  void likeBtnHandler(Post post) {
    if (isLiked) {
      setState(() {
        isLiked = false;
        post.likesCount--;
      });
      postsRef
          .document(post.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .delete();
      postsRef.document(post.id).updateData({'likes': post.likesCount});
    } else {
      if (isDisliked) {
        setState(() {
          isDisliked = false;
          post.disLikesCount--;
        });
        postsRef
            .document(post.id)
            .collection('dislikes')
            .document(Constants.currentUserID)
            .delete();
        postsRef.document(post.id).updateData({'dislikes': post.disLikesCount});
      }
      setState(() {
        isLiked = true;
        post.likesCount++;
      });
      postsRef
          .document(post.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});
      postsRef.document(post.id).updateData({'likes': post.likesCount});

      notificationHandler.sendNotification(
          post.authorId, 'New Post Like', 'likes your post', post.id);
    }
  }

  void dislikeBtnHandler(Post post) {
    if (isDisliked) {
      setState(() {
        isDisliked = false;
        post.disLikesCount--;
      });
      postsRef
          .document(post.id)
          .collection('dislikes')
          .document(Constants.currentUserID)
          .delete();
      postsRef.document(post.id).updateData({'dislikes': post.disLikesCount});
    } else {
      if (isLiked) {
        setState(() {
          isLiked = false;
          post.likesCount--;
        });
        postsRef
            .document(post.id)
            .collection('likes')
            .document(Constants.currentUserID)
            .delete();
        postsRef.document(post.id).updateData({'likes': post.likesCount});
      }
      setState(() {
        isDisliked = true;
        post.disLikesCount++;
      });
      postsRef
          .document(post.id)
          .collection('dislikes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});
      postsRef.document(post.id).updateData({'dislikes': post.disLikesCount});
    }
  }

  void initLikes(Post post) async {
    DocumentSnapshot likedSnapshot = await postsRef
        .document(post.id)
        .collection('likes')
        ?.document(Constants.currentUserID)
        ?.get();
    DocumentSnapshot dislikedSnapshot = await postsRef
        .document(post.id)
        .collection('dislikes')
        ?.document(Constants.currentUserID)
        ?.get();
    //Solves the problem setState() called after dispose()
    if (mounted) {
      setState(() {
        isLiked = likedSnapshot.exists;
        isDisliked = dislikedSnapshot.exists;
      });
    }
  }

  dropDownOptions() {}
}
