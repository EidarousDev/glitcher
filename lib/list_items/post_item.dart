import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/models/game_model.dart';
import 'package:glitcher/models/hashtag_model.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/screens/home/home_screen.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/notification_handler.dart';
import 'package:glitcher/services/share_link.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/bottom_sheets/post_bottom_sheet.dart';
import 'package:glitcher/widgets/caching_image.dart';
import 'package:glitcher/widgets/custom_url_text.dart';
import 'package:glitcher/widgets/image_overlay.dart';
import 'package:share/share.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PostItem extends StatefulWidget {
  final Post post;
  final User author;
  final bool isLoading;
  PostItem(
      {Key key,
      @required this.post,
      @required this.author,
      this.isLoading = false})
      : super(key: key);
  @override
  _PostItemState createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  /// On-the-fly audio data for the second card.
  int _spawnedAudioCount = 0;
  ByteData _likeSFX;
  ByteData _dislikeSFX;
  //YoutubePlayerController _youtubeController;
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

  String firstHalf;
  String secondHalf;
  bool flag = true;
  Game currentGame;
  final number = ValueNotifier(0);

  String _hashtagText = '';

  String _mentionText;

  var audioPlayer = AudioPlayer();

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
        Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
              leading: widget.isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey[300],
                      highlightColor: Colors.grey[100],
                      child: Container(
                        width: Sizes.md_profile_image_w,
                        height: Sizes.md_profile_image_h,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : InkWell(
                      child: CacheThisImage(
                        imageUrl: author.profileImageUrl,
                        imageShape: BoxShape.circle,
                        width: Sizes.md_profile_image_w,
                        height: Sizes.md_profile_image_h,
                        defaultAssetImage: Strings.default_profile_image,
                      ),
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed('/user-profile', arguments: {
                          'userId': post.authorId,
                        });
                      }),
              title: widget.isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey[300],
                      highlightColor: Colors.grey[100],
                      child: Container(
                        color: Colors.grey[300],
                        height: 10,
                        width: 70,
                      ))
                  : Row(
                      children: <Widget>[
                        InkWell(
                          child: Text('@${author.username}' ?? '',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: MyColors.darkPrimary)),
                          onTap: () {
                            Navigator.of(context)
                                .pushNamed('/user-profile', arguments: {
                              'userId': author.id,
                            });
                          },
                        ),
                      ],
                    ),
              subtitle: widget.isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey[300],
                      highlightColor: Colors.grey[100],
                      child: Container(
                        color: Colors.grey[300],
                        height: 10,
                        width: 70,
                      ))
                  : InkWell(
                      child: Text('↳ ${post.game}' ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: MyColors.darkGrey,
                          )),
                      onTap: () {
                        print('currentGame : ${currentGame.id}');
                        Navigator.of(context)
                            .pushNamed('/game-screen', arguments: {
                          'game': currentGame,
                        });
                      },
                    ),
              trailing: ValueListenableBuilder<int>(
                valueListenable: number,
                builder: (context, value, child) {
                  return PostBottomSheet().postOptionIcon(context, post);
                },
              ),
            ),
            widget.isLoading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey[300],
                    highlightColor: Colors.grey[100],
                    child: Container(
                      color: Colors.grey[300],
                      height: 200,
                      width: MediaQuery.of(context).size.width - 20,
                    ))
                : Row(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              secondHalf.isEmpty
                                  ? GestureDetector(
                                      onLongPress: () async {
                                        _onLongPressedPost(context);
                                      },
                                      onTap: () {
                                        if (Constants.routesStack.top() ==
                                            '/post') return;
                                        Navigator.of(context)
                                            .pushNamed('/post', arguments: {
                                          'post': post,
                                        });
                                      },
                                      child: UrlText(
                                        context: context,
                                        text: post.text,
                                        onMentionPressed: (text) =>
                                            mentionedUserProfile(),
                                        onHashTagPressed: (text) =>
                                            hashtagScreen(),
                                        style: TextStyle(
                                          color: switchColor(
                                              Colors.black, Colors.white),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        urlStyle: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w400),
                                      ),
                                    )
                                  : GestureDetector(
                                      onLongPress: () async {
                                        _onLongPressedPost(context);
                                      },
                                      onTap: () {
                                        if (Constants.routesStack.top() ==
                                            '/post') return;
                                        Navigator.of(context)
                                            .pushNamed('/post', arguments: {
                                          'post': post,
                                        });
                                      },
                                      child: UrlText(
                                        context: context,
                                        text: flag
                                            ? (firstHalf + '...')
                                            : (firstHalf + secondHalf),
                                        onMentionPressed: (text) =>
                                            mentionedUserProfile(),
                                        onHashTagPressed: (text) =>
                                            hashtagScreen(),
                                        style: TextStyle(
                                          color: switchColor(
                                              Colors.black, Colors.white),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        urlStyle: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w400),
                                      ),
                                    ),
                              InkWell(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    secondHalf.isEmpty
                                        ? Text('')
                                        : Text(
                                            flag ? 'Show more' : 'Show less',
                                            style: TextStyle(
                                                color: MyColors.darkPrimary),
                                          )
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    flag = !flag;
                                  });
                                },
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
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: InkWell(
                                                onTap: () {
                                                  showDialog(
                                                      barrierDismissible: true,
                                                      builder: (_) {
                                                        return Container(
                                                          width: Sizes
                                                              .sm_profile_image_w,
                                                          height: Sizes
                                                              .sm_profile_image_h,
                                                          child: ImageOverlay(
                                                            imageUrl:
                                                                post.imageUrl,
                                                            btnText: Strings
                                                                .SAVE_IMAGE,
                                                            btnFunction: () {},
                                                          ),
                                                        );
                                                      },
                                                      context: context);
                                                },
                                                child: CacheThisImage(
                                                  imageUrl: post.imageUrl,
                                                  imageShape:
                                                      BoxShape.rectangle,
                                                  width:
                                                      Sizes.home_post_image_w,
                                                  height:
                                                      Sizes.home_post_image_h,
                                                  defaultAssetImage: Strings
                                                      .default_post_image,
                                                ))),
                                      ),
                              ),
                              Container(
                                child: post.video == null
                                    ? null
                                    : AspectRatio(
                                        aspectRatio: videoPlayerController
                                            .value.aspectRatio,
                                        child: playerWidget),
                              ),
                              Container(
                                child:
                                    //TODO: Fix YouTube Player
                                    post.youtubeId != null &&
                                            post.imageUrl == null
                                        ? YoutubePlayerBuilder(
                                            onExitFullScreen: () {
                                              SystemChrome
                                                  .setPreferredOrientations(
                                                      DeviceOrientation.values);
                                            },
                                            player: YoutubePlayer(
                                              controller:
                                                  Constants.youtubeControllers[
                                                      widget.post.id],
                                              showVideoProgressIndicator: true,
                                              bottomActions: [
                                                CurrentPosition(),
                                                ProgressBar(isExpanded: true),
                                                RemainingDuration(),
                                                //FullScreenButton()
                                              ],
                                            ),
                                            builder: (context, player) =>
                                                player)
                                        : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "${Functions.formatTimestamp(post.timestamp)}",
                                  style: TextStyle(
                                      fontSize: 13.0,
                                      color: switchColor(
                                          MyColors.darkGrey, Colors.white70)),
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
          ],
        ),
        SizedBox(
          height: 1.0,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Theme.of(context).dividerColor),
          ),
        ),
        Container(
          height: Sizes.inline_break,
          color: Theme.of(context).cardColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              InkWell(
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      child: isLiked
                          ? Icon(
                              FontAwesome.thumbs_up,
                              size: Sizes.card_btn_size,
                              color: MyColors.darkPrimary,
                            )
                          : Icon(
                              FontAwesome.thumbs_o_up,
                              size: Sizes.card_btn_size,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Text(
                        '${post.likesCount ?? 0}',
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  if (isLikeEnabled) {
                    audioPlayer.setAsset(Strings.like_sound,
                    ).then((value) => audioPlayer.play());
                    await likeBtnHandler(post);
                  }
                },
              ),
              SizedBox(
                width: 1.0,
                height: Sizes.inline_break,
                child: DecoratedBox(
                  decoration:
                      BoxDecoration(color: Theme.of(context).dividerColor),
                ),
              ),
              InkWell(
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      child: isDisliked
                          ? Icon(
                              FontAwesome.thumbs_down,
                              size: Sizes.card_btn_size,
                              color: MyColors.darkPrimary,
                            )
                          : Icon(
                              FontAwesome.thumbs_o_down,
                              size: Sizes.card_btn_size,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Text(
                        '${post.disLikesCount ?? 0}',
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  if (isDislikedEnabled) {
                    audioPlayer.setAsset(Strings.dislike_sound,
                    ).then((value) => audioPlayer.play());
                    await dislikeBtnHandler(post);
                  }
                },
              ),
              SizedBox(
                width: 1.0,
                height: Sizes.inline_break,
                child: DecoratedBox(
                  decoration:
                      BoxDecoration(color: Theme.of(context).dividerColor),
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
                        '${post.commentsCount ?? 0}',
                      ),
                    ),
                  ],
                ),
                onTap: () {
//                    Navigator.of(context).pushNamed('/post', arguments: {
//                      'post': post,
//                      'commentsNo': post.commentsCount
//                    });
                  Navigator.of(context).pushNamed('/add-comment', arguments: {
                    'post': post,
                    'user': author,
                  });
                },
              ),
              SizedBox(
                width: 1.0,
                height: Sizes.inline_break,
                child: DecoratedBox(
                  decoration:
                      BoxDecoration(color: Theme.of(context).dividerColor),
                ),
              ),
              InkWell(
                child: SizedBox(
                  child: Icon(
                    Icons.share,
                    size: Sizes.card_btn_size,
                  ),
                ),
                onTap: () async {
                  await sharePost(post.id, post.text, post.imageUrl);
                },
              ),
            ],
          ),
        ),
        SizedBox(
          height: 14.0,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Theme.of(context).dividerColor),
          ),
        ),
      ],
    );
  }

  // Sharing a post with a shortened url
  sharePost(String postId, String postText, String imageUrl) async {
    var postLink = await DynamicLinks.createPostDynamicLink(
        {'postId': postId, 'text': postText, 'imageUrl': imageUrl});
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
    //Constants.youtubeControllers[widget.post.id].dispose();
    videoPlayerController.dispose();
    chewieController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _loadAudioByteData();
    super.initState();

    checkIfContainsHashtag();
    checkIfContainsMention();

    if (Constants.youtubeControllers.containsKey(widget.post.id)) {
      Constants.youtubeControllers.remove(widget.post.id);
    }
    Constants.youtubeControllers.putIfAbsent(
        widget.post.id,
        () => YoutubePlayerController(
              initialVideoId: widget.post.youtubeId ?? '',
              flags: YoutubePlayerFlags(
                autoPlay: false,
                mute: false,
              ),
            ));

    setCurrentGame();
    if (widget.post.text.length > Sizes.postExcerpt) {
      firstHalf = widget.post.text.substring(0, Sizes.postExcerpt);
      secondHalf = widget.post.text
          .substring(Sizes.postExcerpt, widget.post.text.length);
    } else {
      firstHalf = widget.post.text;
      secondHalf = "";
    }
    if (widget.post.video != null) {
      videoPlayerController = VideoPlayerController.network(widget.post.video)
        ..initialize().then((_) {
          // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
          chewieController = ChewieController(
            videoPlayerController: videoPlayerController,
            autoPlay: false,
            looping: false,
          );

          setState(() {
            playerWidget = Chewie(
              controller: chewieController,
            );
          });
        });
    }
  }

  Future<void> likeBtnHandler(Post post) async {
    setState(() {
      isLikeEnabled = false;
    });
    if (isLiked == true && isDisliked == false) {
      await postsRef
          .doc(post.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .delete();
      await postsRef.doc(post.id).update({'likes': FieldValue.increment(-1)});

      await NotificationHandler.removeNotification(
          post.authorId, post.id, 'like');
      setState(() {
        isLiked = false;
        //post.likesCount = likesNo;
      });
    } else if (isDisliked == true && isLiked == false) {
      await postsRef
          .doc(post.id)
          .collection('dislikes')
          .doc(Constants.currentUserID)
          .delete();
      await postsRef
          .doc(post.id)
          .update({'dislikes': FieldValue.increment(-1)});

      setState(() {
        isDisliked = false;
        //post.disLikesCount = dislikesNo;
      });
      await postsRef
          .doc(post.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .set({'timestamp': FieldValue.serverTimestamp()});
      await postsRef.doc(post.id).update({'likes': FieldValue.increment(1)});

      setState(() {
        isLiked = true;
        //post.likesCount = likesNo;
      });

      await NotificationHandler.sendNotification(post.authorId, 'New Post Like',
          Constants.currentUser.username + ' likes your post', post.id, 'like');
    } else if (isLiked == false && isDisliked == false) {
      await postsRef
          .doc(post.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .set({'timestamp': FieldValue.serverTimestamp()});
      await postsRef.doc(post.id).update({'likes': FieldValue.increment(1)});
      setState(() {
        isLiked = true;
        //post.likesCount = likesNo;
      });

      await NotificationHandler.sendNotification(post.authorId, 'New Post Like',
          Constants.currentUser.username + ' likes your post', post.id, 'like');
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
          .doc(post.id)
          .collection('dislikes')
          .doc(Constants.currentUserID)
          .delete();
      await postsRef
          .doc(post.id)
          .update({'dislikes': FieldValue.increment(-1)});
      setState(() {
        isDisliked = false;
        //post.disLikesCount = dislikesNo;
      });
    } else if (isLiked == true && isDisliked == false) {
      await postsRef
          .doc(post.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .delete();
      await postsRef.doc(post.id).update({'likes': FieldValue.increment(-1)});
      setState(() {
        isLiked = false;
        //post.likesCount = likesNo;
      });
      await postsRef
          .doc(post.id)
          .collection('dislikes')
          .doc(Constants.currentUserID)
          .set({'timestamp': FieldValue.serverTimestamp()});
      await postsRef.doc(post.id).update({'dislikes': FieldValue.increment(1)});

      setState(() {
        isDisliked = true;
        //post.disLikesCount = dislikesNo;
      });
    } else if (isDisliked == false && isLiked == false) {
      await postsRef
          .doc(post.id)
          .collection('dislikes')
          .doc(Constants.currentUserID)
          .set({'timestamp': FieldValue.serverTimestamp()});
      await postsRef.doc(post.id).update({'dislikes': FieldValue.increment(1)});

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
        .doc(post.id)
        .collection('likes')
        ?.doc(Constants.currentUserID)
        ?.get();
    DocumentSnapshot dislikedSnapshot = await postsRef
        .doc(post.id)
        .collection('dislikes')
        ?.doc(Constants.currentUserID)
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
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: new AlertDialog(
                      title: new Text('Are you sure?'),
                      content:
                          new Text('Do you really want to delete this post?'),
                      actions: <Widget>[
                        new GestureDetector(
                          onTap: () => Navigator.of(context).pop(false),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("NO"),
                          ),
                        ),
                        SizedBox(height: 16),
                        new GestureDetector(
                          onTap: () {
                            DatabaseService.deletePost(this.widget.post.id);
                            (context as Element).rebuild();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("YES"),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
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

  Future mentionedUserProfile() async {
    //print('mention: $_mentionText');
    User user =
        await DatabaseService.getUserWithUsername(_mentionText.substring(1));
    Navigator.of(context)
        .pushNamed('/user-profile', arguments: {'userId': user.id});
    //print(user.id);
  }

  checkIfContainsHashtag() {
    var words = widget.post.text.split(' ');
    //print(words.length);
    for (String word in words) {
      //print('word: $word');
      _hashtagText = words.length > 0 && word.startsWith('#') ? word : '';
      break;
    }
  }

  checkIfContainsMention() {
    var words = widget.post.text.split(' ');

    for (String word in words) {
      //print('word: $word');
      _mentionText = words.length > 0 && word.startsWith('@') ? word : '';
      //if (_mentionText.length > 1) _mentionText = _mentionText.substring(1);
      break;
    }
  }

  Future hashtagScreen() async {
    //print('hashtagText: $_hashtagText');
    Hashtag hashtag = await DatabaseService.getHashtagWithText(_hashtagText);

    Navigator.of(context)
        .pushNamed('/hashtag-posts', arguments: {'hashtag': hashtag});
    //print(hashtag.id);
  }

  dropDownOptions() {
    if (HomeScreen.isBottomSheetVisible) {
      Navigator.pop(context);
    } else {
      HomeScreen.showMyBottomSheet(context);
    }

    setState(() {
      HomeScreen.isBottomSheetVisible = !HomeScreen.isBottomSheetVisible;
    });
  }

  void setCurrentGame() async {
    currentGame = await DatabaseService.getGameWithGameName(widget.post.game);
  }

  _onLongPressedPost(BuildContext context) async {
    var postLink = await DynamicLinks.createPostDynamicLink({
      'postId': widget.post.id,
      'text': widget.post.text,
      'imageUrl': widget.post.imageUrl
    });
    var text = ClipboardData(text: '$postLink');
    Clipboard.setData(text);
    //AppUtil().showToast('Post copied to clipboard');
  }
}
