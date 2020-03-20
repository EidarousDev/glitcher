import 'dart:typed_data';

import 'package:audiofileplayer/audiofileplayer.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/notification_handler.dart';
import 'package:glitcher/services/share_link.dart';
import 'package:glitcher/utils/constants.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:share/share.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PostItem extends StatefulWidget {
  final Post post;
  final User author;

  PostItem({Key key, @required this.post, @required this.author})
      : super(key: key);
  @override
  _PostItemState createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  /// On-the-fly audio data for the second card.
  int _spawnedAudioCount = 0;
  ByteData _likeSFX;
  ByteData _dislikeSFX;
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
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed('/post',
            arguments: {'postId': post.id, 'commentsNo': post.commentsCount});
      },
      child: Column(
        children: <Widget>[
          ListTile(
            contentPadding: EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
            leading: InkWell(
                child: author.profileImageUrl != null
                    ? CircleAvatar(
                        radius: 30.0,
                        backgroundImage: NetworkImage(author
                            .profileImageUrl), // no matter how big it is, it won't overflow
                      )
                    : CircleAvatar(
                        backgroundImage:
                            AssetImage('assets/images/default_profile.png'),
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
              child: Text('↳ ${post.category}' ?? '',
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
                onTap: dropDownOptions(),
                child: Icon(Icons.keyboard_arrow_down)),
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
                                height: 200.0,
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
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: double.infinity,
              height: .5,
            ),
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
                : Constants.darkCardBG,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                InkWell(
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        child: isLiked
                            ? Icon(
                                FontAwesome.getIconData('thumbs-up'),
                                size: Constants.cardBtnSize,
                                color: Constants.darkPrimary,
                              )
                            : Icon(
                                FontAwesome.getIconData('thumbs-o-up'),
                                size: Constants.cardBtnSize,
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
                    _likeSFX == null
                        ? null
                        : Audio.loadFromByteData(_likeSFX,
                            onComplete: () =>
                                setState(() => --_spawnedAudioCount))
                      ..play()
                      ..dispose();
                    setState(() => ++_spawnedAudioCount);
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
                        child: isDisliked
                            ? Icon(
                                FontAwesome.getIconData('thumbs-down'),
                                size: Constants.cardBtnSize,
                                color: Constants.darkPrimary,
                              )
                            : Icon(
                                FontAwesome.getIconData('thumbs-o-down'),
                                size: Constants.cardBtnSize,
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
                    _dislikeSFX == null
                        ? null
                        : Audio.loadFromByteData(_dislikeSFX,
                            onComplete: () =>
                                setState(() => --_spawnedAudioCount))
                      ..play()
                      ..dispose();
                    setState(() => ++_spawnedAudioCount);
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
                InkWell(
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        child: Icon(
                          Icons.chat_bubble_outline,
                          size: Constants.cardBtnSize,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Text(
                          post.commentsCount.toString(),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).pushNamed('/post', arguments: {
                      'postId': post.id,
                      'commentsNo': post.commentsCount
                    });
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
                  child: SizedBox(
                    child: Icon(
                      Icons.share,
                      size: Constants.cardBtnSize,
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
            height: 14.0,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                  color: currentTheme == AvailableThemes.LIGHT_THEME
                      ? Constants.lightLineBreak
                      : Constants.darkLineBreak),
            ),
          ),
        ],
      ),
    );
  }

  // Sharing a post with a shortened url
  void sharePost(String postId, String postText, String imageUrl) async {
    var postLink = await DynamicLinks.createDynamicLink(
        {'postId': postId, 'postText': postText, 'imageUrl': imageUrl});
    Share.share('Check out: $postText : $postLink');
    print('Check out: $postText : $postLink');
  }

  void _loadAudioByteData() async {
    _likeSFX = await rootBundle.load('assets/sounds/like_sound.mp3');
    _dislikeSFX = await rootBundle.load('assets/sounds/dislikesfx.mp3');
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
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    _loadAudioByteData();
    super.initState();
  }

  Future<void> likeBtnHandler(Post post) async {
    if (isLiked && !isDisliked) {
      postsRef
          .document(post.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .delete();
      postsRef
          .document(post.id)
          .updateData({'likes': FieldValue.increment(-1)});
      setState(() {
        isLiked = false;
        //post.likesCount = likesNo;
      });
    } else {
      if (isDisliked && !isLiked) {
        postsRef
            .document(post.id)
            .collection('dislikes')
            .document(Constants.currentUserID)
            .delete();
        postsRef
            .document(post.id)
            .updateData({'dislikes': FieldValue.increment(-1)});
      }
      setState(() {
        isDisliked = false;
        //post.disLikesCount = dislikesNo;
      });
      postsRef
          .document(post.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});
      postsRef.document(post.id).updateData({'likes': FieldValue.increment(1)});

      setState(() {
        isLiked = true;
        //post.likesCount = likesNo;
      });

      notificationHandler.sendNotification(
          post.authorId, 'New Post Like', 'likes your post', post.id);
    }
    var postMeta = await DatabaseService.getPostMeta(post.id);
    setState(() {
      post.likesCount = postMeta['likes'];
      post.disLikesCount = postMeta['dislikes'];
    });

    print(
        'likes = ${postMeta['likes']} and dislikes = ${postMeta['dislikes']}');
  }

  Future<void> dislikeBtnHandler(Post post) async {
    if (isDisliked && !isLiked) {
      postsRef
          .document(post.id)
          .collection('dislikes')
          .document(Constants.currentUserID)
          .delete();
      postsRef
          .document(post.id)
          .updateData({'dislikes': FieldValue.increment(-1)});
      setState(() {
        isDisliked = false;
        //post.disLikesCount = dislikesNo;
      });
    } else {
      if (isLiked && !isDisliked) {
        postsRef
            .document(post.id)
            .collection('likes')
            .document(Constants.currentUserID)
            .delete();
        postsRef
            .document(post.id)
            .updateData({'likes': FieldValue.increment(-1)});
      }
      setState(() {
        isLiked = false;
        //post.likesCount = likesNo;
      });
      postsRef
          .document(post.id)
          .collection('dislikes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});
      postsRef
          .document(post.id)
          .updateData({'dislikes': FieldValue.increment(1)});

      setState(() {
        isDisliked = true;
        //post.disLikesCount = dislikesNo;
      });
    }

    var postMeta = await DatabaseService.getPostMeta(post.id);

    setState(() {
      post.likesCount = postMeta['likes'];
      post.disLikesCount = postMeta['dislikes'];
    });

    print(
        'likes = ${postMeta['likes']} and dislikes = ${postMeta['dislikes']}');
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

  Widget dropDownBtn() {
    if (Constants.currentUserID == widget.post.authorId) {
      return specialBtns();
    }
    return Container();
  }

  Widget specialBtns() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 16.0),
      child: Row(
        children: <Widget>[
          InkWell(
              child: Icon(
                Icons.report_problem,
                size: 22.0,
                color: Constants.darkAccent,
              ),
              onTap: () {}),
          InkWell(
              child: Icon(
                Icons.delete_forever,
                size: 22.0,
                color: Constants.darkAccent,
              ),
              onTap: () {}),
          InkWell(
              child: Icon(
                Icons.edit,
                size: 22.0,
                color: Constants.darkAccent,
              ),
              onTap: () {}),
        ],
      ),
    );
  }

  dropDownOptions() {}
}
