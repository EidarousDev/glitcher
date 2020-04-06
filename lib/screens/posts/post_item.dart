import 'dart:typed_data';
import 'package:audiofileplayer/audiofileplayer.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/notification_handler.dart';
import 'package:glitcher/services/share_link.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/caching_image.dart';
import 'package:glitcher/widgets/image_overlay.dart';
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
  bool isLikeEnabled = true;
  bool isDisliked = false;
  bool isDislikedEnabled = true;
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
                child: CacheThisImage(
                  imageUrl: author.profileImageUrl,
                  imageShape: BoxShape.circle,
                  width: Sizes.md_profile_image_w,
                  height: Sizes.md_profile_image_h,
                  defaultAssetImage: Strings.default_profile_image,
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
                      color: MyColors.darkPrimary)),
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
                    color: MyColors.darkGrey,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
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
                                width: Sizes.home_post_image_w,
                                height: Sizes.home_post_image_h,
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: InkWell(
                                        onTap: () {
                                          showDialog(
                                              barrierDismissible: true,
                                              child: Container(
                                                width: Sizes.sm_profile_image_w,
                                                height:
                                                    Sizes.sm_profile_image_h,
                                                child: ImageOverlay(
                                                  imageUrl: post.imageUrl,
                                                  btnText: 'Download',
                                                  btnFunction: () {},
                                                ),
                                              ),
                                              context: context);
                                        },
                                        child: CacheThisImage(
                                          imageUrl: post.imageUrl,
                                          imageShape: BoxShape.rectangle,
                                          width: Sizes.home_post_image_w,
                                          height: Sizes.home_post_image_h,
                                          defaultAssetImage:
                                              Strings.default_post_image,
                                        ))),
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
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "${Functions.formatTimestamp(post.timestamp)}",
                          style:
                              TextStyle(fontSize: 13.0, color: Colors.white30),
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
                      ? MyColors.lightLineBreak
                      : MyColors.darkLineBreak),
            ),
          ),
          Container(
            height: Sizes.inline_break,
            color: currentTheme == AvailableThemes.LIGHT_THEME
                ? MyColors.lightLineBreak
                : MyColors.darkCardBG,
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
                                size: Sizes.card_btn_size,
                                color: MyColors.darkPrimary,
                              )
                            : Icon(
                                FontAwesome.getIconData('thumbs-o-up'),
                                size: Sizes.card_btn_size,
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
                    if (isLikeEnabled) {
                      _likeSFX == null
                          ? null
                          : Audio.loadFromByteData(_likeSFX,
                              onComplete: () =>
                                  setState(() => --_spawnedAudioCount))
                        ..play()
                        ..dispose();
                      setState(() => ++_spawnedAudioCount);
                      await likeBtnHandler(post);
                    }
                  },
                ),
                SizedBox(
                  width: 1.0,
                  height: Sizes.inline_break,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: currentTheme == AvailableThemes.LIGHT_THEME
                            ? MyColors.lightInLineBreak
                            : MyColors.darkLineBreak),
                  ),
                ),
                InkWell(
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        child: isDisliked
                            ? Icon(
                                FontAwesome.getIconData('thumbs-down'),
                                size: Sizes.card_btn_size,
                                color: MyColors.darkPrimary,
                              )
                            : Icon(
                                FontAwesome.getIconData('thumbs-o-down'),
                                size: Sizes.card_btn_size,
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
                    if (isDislikedEnabled) {
                      _dislikeSFX == null
                          ? null
                          : Audio.loadFromByteData(_dislikeSFX,
                              onComplete: () =>
                                  setState(() => --_spawnedAudioCount))
                        ..play()
                        ..dispose();
                      setState(() => ++_spawnedAudioCount);
                      await dislikeBtnHandler(post);
                    }
                  },
                ),
                SizedBox(
                  width: 1.0,
                  height: Sizes.inline_break,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: currentTheme == AvailableThemes.LIGHT_THEME
                            ? MyColors.lightInLineBreak
                            : MyColors.darkLineBreak),
                  ),
                ),
                InkWell(
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        child: Icon(
                          Icons.chat_bubble_outline,
                          size: Sizes.card_btn_size,
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
                  height: Sizes.inline_break,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: currentTheme == AvailableThemes.LIGHT_THEME
                            ? MyColors.lightInLineBreak
                            : MyColors.darkLineBreak),
                  ),
                ),
                InkWell(
                  child: SizedBox(
                    child: Icon(
                      Icons.share,
                      size: Sizes.card_btn_size,
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
                      ? MyColors.lightLineBreak
                      : MyColors.darkLineBreak),
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
    _likeSFX = await rootBundle.load(Strings.like_sound);
    _dislikeSFX = await rootBundle.load(Strings.dislike_sound);
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
    setState(() {
      isLikeEnabled = false;
    });
    if (isLiked == true && isDisliked == false) {
      await postsRef
          .document(post.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .delete();
      await postsRef
          .document(post.id)
          .updateData({'likes': FieldValue.increment(-1)});
      setState(() {
        isLiked = false;
        //post.likesCount = likesNo;
      });
    } else if (isDisliked == true && isLiked == false) {
      await postsRef
          .document(post.id)
          .collection('dislikes')
          .document(Constants.currentUserID)
          .delete();
      await postsRef
          .document(post.id)
          .updateData({'dislikes': FieldValue.increment(-1)});

      setState(() {
        isDisliked = false;
        //post.disLikesCount = dislikesNo;
      });
      await postsRef
          .document(post.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .document(post.id)
          .updateData({'likes': FieldValue.increment(1)});

      setState(() {
        isLiked = true;
        //post.likesCount = likesNo;
      });

      notificationHandler.sendNotification(
          post.authorId, 'New Post Like', 'likes your post', post.id);
    } else if (isLiked == false && isDisliked == false) {
      await postsRef
          .document(post.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .document(post.id)
          .updateData({'likes': FieldValue.increment(1)});
      setState(() {
        isLiked = true;
        //post.likesCount = likesNo;
      });
    } else {
      throw Exception('Unconditional Event Occurred!');
    }
    var postMeta = await DatabaseService.getPostMeta(post.id);
    setState(() {
      post.likesCount = postMeta['likes'];
      post.disLikesCount = postMeta['dislikes'];
      isLikeEnabled = true;
    });

    print(
        'likes = ${postMeta['likes']} and dislikes = ${postMeta['dislikes']}');
  }

  Future<void> dislikeBtnHandler(Post post) async {
    setState(() {
      isDislikedEnabled = false;
    });
    if (isDisliked == true && isLiked == false) {
      await postsRef
          .document(post.id)
          .collection('dislikes')
          .document(Constants.currentUserID)
          .delete();
      await postsRef
          .document(post.id)
          .updateData({'dislikes': FieldValue.increment(-1)});
      setState(() {
        isDisliked = false;
        //post.disLikesCount = dislikesNo;
      });
    } else if (isLiked == true && isDisliked == false) {
      await postsRef
          .document(post.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .delete();
      await postsRef
          .document(post.id)
          .updateData({'likes': FieldValue.increment(-1)});
      setState(() {
        isLiked = false;
        //post.likesCount = likesNo;
      });
      await postsRef
          .document(post.id)
          .collection('dislikes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .document(post.id)
          .updateData({'dislikes': FieldValue.increment(1)});

      setState(() {
        isDisliked = true;
        //post.disLikesCount = dislikesNo;
      });
    } else if (isDisliked == false && isLiked == false) {
      await postsRef
          .document(post.id)
          .collection('dislikes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .document(post.id)
          .updateData({'dislikes': FieldValue.increment(1)});

      setState(() {
        isDisliked = true;
        //post.disLikesCount = dislikesNo;
      });
    } else {
      throw Exception('Unconditional Event Occurred.');
    }

    var postMeta = await DatabaseService.getPostMeta(post.id);

    setState(() {
      post.likesCount = postMeta['likes'];
      post.disLikesCount = postMeta['dislikes'];
      isDislikedEnabled = true;
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
                color: MyColors.darkAccent,
              ),
              onTap: () {}),
          InkWell(
              child: Icon(
                Icons.delete_forever,
                size: 22.0,
                color: MyColors.darkAccent,
              ),
              onTap: () {}),
          InkWell(
              child: Icon(
                Icons.edit,
                size: 22.0,
                color: MyColors.darkAccent,
              ),
              onTap: () {}),
        ],
      ),
    );
  }

  dropDownOptions() {}
}
