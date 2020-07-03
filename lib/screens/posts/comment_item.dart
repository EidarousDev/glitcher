import 'dart:typed_data';

import 'package:audiofileplayer/audiofileplayer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/font_awesome.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/models/comment_model.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/notification_handler.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/caching_image.dart';

class CommentItem extends StatefulWidget {
  final Post post;
  final Comment comment;
  final User commenter;
  final bool isReply;

  CommentItem(
      {Key key,
      @required this.post,
      @required this.comment,
      @required this.commenter,
      @required this.isReply})
      : super(key: key);
  @override
  _CommentItemState createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  int _spawnedAudioCount = 0;
  ByteData _likeSFX;
  ByteData _dislikeSFX;

  bool isLiked = false;
  bool isLikeEnabled = true;
  bool isDisliked = false;
  bool isDislikedEnabled = true;
  var likes = [];
  var dislikes = [];

  bool repliesVisible = false;

  List<Comment> replies = [];

  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    print(
        'user: ${widget.commenter.username} and comment: ${widget.comment.text}');
    return SafeArea(
      child: Column(
        children: <Widget>[
          commentListTile(context),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              height: 1.0,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: Constants.currentTheme == AvailableThemes.LIGHT_THEME
                        ? MyColors.lightLineBreak
                        : MyColors.darkLineBreak),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget commentListTile(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ListTile(
            leading: InkWell(
                child: CacheThisImage(
                  imageUrl: widget.commenter.profileImageUrl,
                  imageShape: BoxShape.circle,
                  width: Sizes.sm_profile_image_w,
                  height: Sizes.sm_profile_image_h,
                  defaultAssetImage: Strings.default_profile_image,
                ),
                onTap: () {
                  Navigator.of(context).pushNamed('/user-profile', arguments: {
                    'userId': widget.comment.commenterID,
                  });
                }),
            title: InkWell(
              child: widget.commenter.username == null
                  ? Text('')
                  : RichText(
                      text: TextSpan(
                        // Note: Styles for TextSpans must be explicitly defined.
                        // Child text spans will inherit styles from parent
                        style: TextStyle(
                          fontSize: 15.0,
                          color: MyColors.darkPrimary,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                              text: ' @${widget.commenter.username}',
                              style: TextStyle(
                                  color: switchColor(MyColors.lightPrimary,
                                      MyColors.darkPrimary))),
                          TextSpan(
                              text:
                                  ' - ${Functions.formatCommentsTimestamp(widget.comment.timestamp)}',
                              style: TextStyle(
                                  color: switchColor(
                                      MyColors.darkGrey, MyColors.darkGrey))),
                        ],
                      ),
                    ),
              onTap: () {
                Navigator.of(context).pushNamed('/user-profile', arguments: {
                  'userId': widget.comment.commenterID,
                });
              },
            ),
            subtitle: widget.comment.text == null
                ? Text('')
                : Text.rich(
                    TextSpan(
                        text: '',
                        children: widget.comment.text.split(' ').map((w) {
                          return w.startsWith('@') && w.length > 1
                              ? TextSpan(
                                  text: ' ' + w,
                                  style: TextStyle(color: Colors.blue),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => mentionedUserProfile(w),
                                )
                              : TextSpan(text: ' ' + w);
                        }).toList()),
                  ),
            isThreeLine: true,
          ),
          !widget.isReply
              ? InkWell(
                  onTap: () {
                    setState(() {
                      repliesVisible = !repliesVisible;
                    });
                  },
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        repliesVisible
                            ? 'hide replies'
                            : 'view ${widget.comment.repliesCount} replies',
                        style: TextStyle(color: MyColors.darkPrimary),
                      ),
                    ),
                  ),
                )
              : Container(),
          !widget.isReply
              ? Expanded(
                  flex: 5,
                  child: Container(
                    height: 200,
                    child: ListView.builder(
                        itemCount: replies.length,
                        physics: NeverScrollableScrollPhysics(),
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemBuilder: (BuildContext context, int index) {
                          return CommentItem(
                            post: widget.post,
                            comment: widget.comment,
                            commenter: widget.commenter,
                            isReply: true,
                          );
                        }),
                  ),
                )
              : Container(),
          Container(
            height: Sizes.inline_break,
            color: Constants.currentTheme == AvailableThemes.LIGHT_THEME
                ? MyColors.lightCardBG
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
                                size: Sizes.small_card_btn_size,
                                color: MyColors.darkPrimary,
                              )
                            : Icon(
                                FontAwesome.getIconData('thumbs-o-up'),
                                size: Sizes.small_card_btn_size,
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Text(
                          widget.comment.likesCount == null
                              ? 0.toString()
                              : widget.comment.likesCount.toString(),
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
                      await likeBtnHandler(widget.post, widget.comment);
                    }
                  },
                ),
                SizedBox(
                  width: 1.0,
                  height: Sizes.inline_break,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color:
                            Constants.currentTheme == AvailableThemes.LIGHT_THEME
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
                                size: Sizes.small_card_btn_size,
                                color: MyColors.darkPrimary,
                              )
                            : Icon(
                                FontAwesome.getIconData('thumbs-o-down'),
                                size: Sizes.small_card_btn_size,
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Text(
                          widget.comment.disLikesCount == null
                              ? 0.toString()
                              : widget.comment.disLikesCount.toString(),
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
                      await dislikeBtnHandler(widget.post, widget.comment);
                    }
                  },
                ),
                SizedBox(
                  width: 1.0,
                  height: Sizes.inline_break,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color:
                            Constants.currentTheme == AvailableThemes.LIGHT_THEME
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
                          size: Sizes.small_card_btn_size,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Text(
                          widget.comment.repliesCount == null
                              ? 0.toString()
                              : widget.comment.repliesCount.toString(),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).pushNamed('/add-reply', arguments: {
                      'postId': widget.post,
                      'comment': widget.comment,
                      'user': widget.commenter
                    });
                  },
                ),
                SizedBox(
                  width: 1.0,
                  height: Sizes.inline_break,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color:
                            Constants.currentTheme == AvailableThemes.LIGHT_THEME
                                ? MyColors.lightInLineBreak
                                : MyColors.darkLineBreak),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> likeBtnHandler(Post post, Comment comment) async {
    setState(() {
      isLikeEnabled = false;
    });
    if (isLiked == true && isDisliked == false) {
      await postsRef
          .document(post.id)
          .collection('comments')
          .document(comment.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .delete();
      await postsRef
          .document(post.id)
          .collection('comments')
          .document(comment.id)
          .updateData({'likes': FieldValue.increment(-1)});
      setState(() {
        isLiked = false;
        //post.likesCount = likesNo;
      });
    } else if (isDisliked == true && isLiked == false) {
      await postsRef
          .document(post.id)
          .collection('comments')
          .document(comment.id)
          .collection('dislikes')
          .document(Constants.currentUserID)
          .delete();
      await postsRef
          .document(post.id)
          .collection('comments')
          .document(comment.id)
          .updateData({'dislikes': FieldValue.increment(-1)});

      setState(() {
        isDisliked = false;
        //post.disLikesCount = dislikesNo;
      });
      await postsRef
          .document(post.id)
          .collection('comments')
          .document(comment.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .document(post.id)
          .collection('comments')
          .document(comment.id)
          .updateData({'likes': FieldValue.increment(1)});

      setState(() {
        isLiked = true;
        //post.likesCount = likesNo;
      });

      await NotificationHandler.sendNotification(
          post.authorId,
          'New Comment Like',
          Constants.loggedInUser.username + ' likes your comment',
          post.id,
          'like');
    } else if (isLiked == false && isDisliked == false) {
      await postsRef
          .document(post.id)
          .collection('comments')
          .document(comment.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .document(post.id)
          .collection('comments')
          .document(comment.id)
          .updateData({'likes': FieldValue.increment(1)});
      setState(() {
        isLiked = true;
        //post.likesCount = likesNo;
      });

      await NotificationHandler.sendNotification(
          post.authorId,
          'New Comment Like',
          Constants.loggedInUser.username + ' likes your comment',
          post.id,
          'like');
    } else {
      throw Exception('Unconditional Event Occurred!');
    }
    var commentMeta =
        await DatabaseService.getCommentMeta(post.id, widget.comment.id);
    setState(() {
      widget.comment.likesCount = commentMeta['likes'];
      widget.comment.disLikesCount = commentMeta['dislikes'];
      isLikeEnabled = true;
    });

    print(
        'likes = ${commentMeta['likes']} and dislikes = ${commentMeta['dislikes']}');
  }

  Future<void> dislikeBtnHandler(Post post, Comment comment) async {
    setState(() {
      isDislikedEnabled = false;
    });
    if (isDisliked == true && isLiked == false) {
      await postsRef
          .document(post.id)
          .collection('comments')
          .document(comment.id)
          .collection('dislikes')
          .document(Constants.currentUserID)
          .delete();
      await postsRef
          .document(post.id)
          .collection('comments')
          .document(comment.id)
          .updateData({'dislikes': FieldValue.increment(-1)});
      setState(() {
        isDisliked = false;
        //post.disLikesCount = dislikesNo;
      });
    } else if (isLiked == true && isDisliked == false) {
      await postsRef
          .document(post.id)
          .collection('comments')
          .document(comment.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .delete();
      await postsRef
          .document(post.id)
          .collection('comments')
          .document(comment.id)
          .updateData({'likes': FieldValue.increment(-1)});
      setState(() {
        isLiked = false;
        //post.likesCount = likesNo;
      });
      await postsRef
          .document(post.id)
          .collection('comments')
          .document(comment.id)
          .collection('dislikes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .document(post.id)
          .collection('comments')
          .document(comment.id)
          .updateData({'dislikes': FieldValue.increment(1)});

      setState(() {
        isDisliked = true;
        //post.disLikesCount = dislikesNo;
      });
    } else if (isDisliked == false && isLiked == false) {
      await postsRef
          .document(post.id)
          .collection('comments')
          .document(comment.id)
          .collection('dislikes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .document(post.id)
          .collection('comments')
          .document(comment.id)
          .updateData({'dislikes': FieldValue.increment(1)});

      setState(() {
        isDisliked = true;
        //post.disLikesCount = dislikesNo;
      });
    } else {
      throw Exception('Unconditional Event Occurred.');
    }

    var commentMeta = await DatabaseService.getCommentMeta(post.id, comment.id);

    setState(() {
      widget.comment.likesCount = commentMeta['likes'];
      widget.comment.disLikesCount = commentMeta['dislikes'];
      isDislikedEnabled = true;
    });

    print(
        'likes = ${commentMeta['likes']} and dislikes = ${commentMeta['dislikes']}');
  }

  void initLikes(String postId, Comment comment) async {
    DocumentSnapshot likedSnapshot = await postsRef
        .document(postId)
        .collection('comments')
        .document(comment.id)
        .collection('likes')
        ?.document(Constants.currentUserID)
        ?.get();
    DocumentSnapshot dislikedSnapshot = await postsRef
        .document(postId)
        .collection('comments')
        .document(comment.id)
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

  void _loadAudioByteData() async {
    _likeSFX = await rootBundle.load(Strings.like_sound);
    _dislikeSFX = await rootBundle.load(Strings.dislike_sound);
  }

  loadReplies(String postId, String commentId) async {
    List<Comment> replies =
        await DatabaseService.getCommentReplies(postId, commentId);
    setState(() {
      this.replies = replies;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadAudioByteData();
    initLikes(widget.post.id, widget.comment);
    loadReplies(widget.post.id, widget.comment.id);
  }

  mentionedUserProfile(String w) async {
    //TODO: Implement Mentioned user profile - Get UID from string then pass it to the navigator
    String username = w.substring(1);
    User user = await DatabaseService.getUserWithUsername(username);
    Navigator.of(context)
        .pushNamed('/user-profile', arguments: {'userId': user.id});
    print(w);
  }
}
