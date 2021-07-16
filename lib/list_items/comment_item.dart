import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/flutter_icons.dart';
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
import 'package:glitcher/widgets/bottom_sheets/comment_bottom_sheet.dart';
import 'package:glitcher/widgets/caching_image.dart';
import 'package:just_audio/just_audio.dart';

class CommentItem extends StatefulWidget {
  final Post post;
  final Comment comment;
  final User commenter;
  final bool isReply;
  final Comment parentComment;

  CommentItem(
      {Key key,
      @required this.post,
      @required this.comment,
      @required this.commenter,
      @required this.isReply,
      this.parentComment})
      : super(key: key);
  @override
  _CommentItemState createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  bool isLiked = false;
  bool isLikeEnabled = true;
  bool isDisliked = false;
  bool isDislikedEnabled = true;
  var likes = [];
  var dislikes = [];

  bool repliesVisible = false;

  List<Comment> replies = [];

  ScrollController scrollController = ScrollController();

  List<User> repliers = [];

  final number = ValueNotifier(0);

  AudioPlayer audioPlayer = AudioPlayer();

  @override
  Widget build(BuildContext context) {
//    print(
//        'user: ${widget.commenter.username} and comment: ${widget.comment.text}');
    return SafeArea(
      child: Column(
        children: <Widget>[
          commentListTile(context),
        ],
      ),
    );
  }

  Widget commentListTile(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ListTile(
            leading: InkWell(
                child: CacheThisImage(
                  imageUrl: widget.commenter.profileImageUrl,
                  imageShape: BoxShape.circle,
                  width: widget.isReply
                      ? Sizes.vsm_profile_image_w
                      : Sizes.sm_profile_image_w,
                  height: widget.isReply
                      ? Sizes.vsm_profile_image_w
                      : Sizes.sm_profile_image_h,
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
            trailing: ValueListenableBuilder<int>(
              valueListenable: number,
              builder: (context, value, child) {
                return CommentBottomSheet().commentOptionIcon(
                    context, widget.post, widget.comment, widget.parentComment);
              },
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
                      child: (widget.comment.repliesCount != null &&
                              widget.comment.repliesCount != 0)
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                !repliesVisible
                                    ? 'view ${widget.comment.repliesCount} replies'
                                    : 'hide replies',
                                style: TextStyle(color: MyColors.darkPrimary),
                              ),
                            )
                          : Container(),
                    ),
                  ),
                )
              : Container(),
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
                                size: Sizes.small_card_btn_size,
                                color: MyColors.darkPrimary,
                              )
                            : Icon(
                                FontAwesome.thumbs_o_up,
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
                      audioPlayer
                          .setAsset(
                            Strings.like_sound,
                          )
                          .then((value) => audioPlayer.play());
                      if (!widget.isReply) {
                        await likeBtnHandler(widget.post, widget.comment);
                      } else {
                        await repliesLikeBtnHandler(widget.post, widget.comment,
                            widget.parentComment.id);
                      }
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
                                size: Sizes.small_card_btn_size,
                                color: MyColors.darkPrimary,
                              )
                            : Icon(
                                FontAwesome.thumbs_o_down,
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
                      audioPlayer
                          .setAsset(
                            Strings.dislike_sound,
                          )
                          .then((value) => audioPlayer.play());

                      if (!widget.isReply) {
                        await dislikeBtnHandler(widget.post, widget.comment);
                      } else {
                        await repliesDislikeBtnHandler(widget.post,
                            widget.comment, widget.parentComment.id);
                      }
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
                    print('Mention reply : ${widget.commenter.username}');

                    Navigator.of(context).pushNamed('/add-reply', arguments: {
                      'post': widget.post,
                      'comment': widget.isReply
                          ? widget.parentComment
                          : widget.comment,
                      'user': widget.commenter,
                      'mention': widget.isReply
                          ? '@${widget.commenter.username} '
                          : '',
                    });
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            height: 1.0,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Theme.of(context).dividerColor),
            ),
          ),
          !widget.isReply && repliesVisible
              ? Flexible(
                  fit: FlexFit.loose,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 40.0),
                    child: ListView.builder(
                        controller: scrollController,
                        itemCount: replies.length,
                        physics: NeverScrollableScrollPhysics(),
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemBuilder: (BuildContext context, int index) {
                          return CommentItem(
                            post: widget.post,
                            comment: replies[index],
                            parentComment: widget.comment,
                            commenter: repliers[index],
                            isReply: true,
                          );
                        }),
                  ),
                )
              : Container(),
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
          .doc(post.id)
          .collection('comments')
          .doc(comment.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .delete();

      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(comment.id)
          .update({'likes': FieldValue.increment(-1)});
      setState(() {
        isLiked = false;
        //post.likesCount = likesNo;
      });
    } else if (isDisliked == true && isLiked == false) {
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(comment.id)
          .collection('dislikes')
          .doc(Constants.currentUserID)
          .delete();
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(comment.id)
          .update({'dislikes': FieldValue.increment(-1)});

      setState(() {
        isDisliked = false;
        //post.disLikesCount = dislikesNo;
      });
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(comment.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .set({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(comment.id)
          .update({'likes': FieldValue.increment(1)});

      setState(() {
        isLiked = true;
        //post.likesCount = likesNo;
      });

      await NotificationHandler.sendNotification(
          post.authorId,
          'New Comment Like',
          Constants.currentUser.username + ' likes your comment',
          post.id,
          'like');
    } else if (isLiked == false && isDisliked == false) {
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(comment.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .set({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(comment.id)
          .update({'likes': FieldValue.increment(1)});
      setState(() {
        isLiked = true;
        //post.likesCount = likesNo;
      });

      await NotificationHandler.sendNotification(
          post.authorId,
          'New Comment Like',
          Constants.currentUser.username + ' likes your comment',
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
          .doc(post.id)
          .collection('comments')
          .doc(comment.id)
          .collection('dislikes')
          .doc(Constants.currentUserID)
          .delete();
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(comment.id)
          .update({'dislikes': FieldValue.increment(-1)});
      setState(() {
        isDisliked = false;
        //post.disLikesCount = dislikesNo;
      });
    } else if (isLiked == true && isDisliked == false) {
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(comment.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .delete();
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(comment.id)
          .update({'likes': FieldValue.increment(-1)});
      setState(() {
        isLiked = false;
        //post.likesCount = likesNo;
      });
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(comment.id)
          .collection('dislikes')
          .doc(Constants.currentUserID)
          .set({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(comment.id)
          .update({'dislikes': FieldValue.increment(1)});

      setState(() {
        isDisliked = true;
        //post.disLikesCount = dislikesNo;
      });
    } else if (isDisliked == false && isLiked == false) {
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(comment.id)
          .collection('dislikes')
          .doc(Constants.currentUserID)
          .set({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(comment.id)
          .update({'dislikes': FieldValue.increment(1)});

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
        .doc(postId)
        .collection('comments')
        .doc(comment.id)
        .collection('likes')
        ?.doc(Constants.currentUserID)
        ?.get();
    DocumentSnapshot dislikedSnapshot = await postsRef
        .doc(postId)
        .collection('comments')
        .doc(comment.id)
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

  Future<void> repliesLikeBtnHandler(
      Post post, Comment comment, String parentCommentId) async {
    setState(() {
      isLikeEnabled = false;
    });
    if (isLiked == true && isDisliked == false) {
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .delete();

      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .update({'likes': FieldValue.increment(-1)});
      setState(() {
        isLiked = false;
        //post.likesCount = likesNo;
      });
    } else if (isDisliked == true && isLiked == false) {
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .collection('dislikes')
          .doc(Constants.currentUserID)
          .delete();
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .update({'dislikes': FieldValue.increment(-1)});

      setState(() {
        isDisliked = false;
        //post.disLikesCount = dislikesNo;
      });
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .set({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .update({'likes': FieldValue.increment(1)});

      setState(() {
        isLiked = true;
        //post.likesCount = likesNo;
      });

      await NotificationHandler.sendNotification(
          post.authorId,
          'New Comment Like',
          Constants.currentUser.username + ' likes your comment',
          post.id,
          'like');
    } else if (isLiked == false && isDisliked == false) {
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .set({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .update({'likes': FieldValue.increment(1)});
      setState(() {
        isLiked = true;
        //post.likesCount = likesNo;
      });

      await NotificationHandler.sendNotification(
          post.authorId,
          'New Comment Like',
          Constants.currentUser.username + ' likes your comment',
          post.id,
          'like');
    } else {
      throw Exception('Unconditional Event Occurred!');
    }
    var replyMeta = await DatabaseService.getReplyMeta(
        post.id, parentCommentId, widget.comment.id);
    setState(() {
      widget.comment.likesCount = replyMeta['likes'];
      widget.comment.disLikesCount = replyMeta['dislikes'];
      isLikeEnabled = true;
    });

    print(
        'likes = ${replyMeta['likes']} and dislikes = ${replyMeta['dislikes']}');
  }

  Future<void> repliesDislikeBtnHandler(
      Post post, Comment comment, String parentCommentId) async {
    setState(() {
      isDislikedEnabled = false;
    });
    if (isDisliked == true && isLiked == false) {
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .collection('dislikes')
          .doc(Constants.currentUserID)
          .delete();
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .update({'dislikes': FieldValue.increment(-1)});
      setState(() {
        isDisliked = false;
        //post.disLikesCount = dislikesNo;
      });
    } else if (isLiked == true && isDisliked == false) {
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .collection('likes')
          .doc(Constants.currentUserID)
          .delete();
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .update({'likes': FieldValue.increment(-1)});
      setState(() {
        isLiked = false;
        //post.likesCount = likesNo;
      });
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .collection('dislikes')
          .doc(Constants.currentUserID)
          .set({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .update({'dislikes': FieldValue.increment(1)});

      setState(() {
        isDisliked = true;
        //post.disLikesCount = dislikesNo;
      });
    } else if (isDisliked == false && isLiked == false) {
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .collection('dislikes')
          .doc(Constants.currentUserID)
          .set({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .doc(post.id)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(comment.id)
          .update({'dislikes': FieldValue.increment(1)});

      setState(() {
        isDisliked = true;
        //post.disLikesCount = dislikesNo;
      });
    } else {
      throw Exception('Unconditional Event Occurred.');
    }

    var replyMeta = await DatabaseService.getReplyMeta(
        post.id, parentCommentId, comment.id);

    setState(() {
      widget.comment.likesCount = replyMeta['likes'];
      widget.comment.disLikesCount = replyMeta['dislikes'];
      isDislikedEnabled = true;
    });

    print(
        'likes = ${replyMeta['likes']} and dislikes = ${replyMeta['dislikes']}');
  }

  void repliesInitLikes(
      String postId, Comment comment, String parentCommentId) async {
    DocumentSnapshot likedSnapshot = await postsRef
        .doc(postId)
        .collection('comments')
        .doc(parentCommentId)
        .collection('replies')
        .doc(comment.id)
        .collection('likes')
        ?.doc(Constants.currentUserID)
        ?.get();

    DocumentSnapshot dislikedSnapshot = await postsRef
        .doc(postId)
        .collection('comments')
        .doc(parentCommentId)
        .collection('replies')
        .doc(comment.id)
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

  loadReplies(String postId, String commentId) async {
    List<Comment> replies =
        await DatabaseService.getCommentReplies(postId, commentId);
    if (mounted) {
      setState(() {
        this.replies = replies;
      });
    }

    this.replies.forEach((element) async {
      User user = await DatabaseService.getUserWithId(element.commenterID,
          checkLocal: true);
      if (mounted) {
        setState(() {
          this.repliers.add(user);
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (!widget.isReply) {
      initLikes(widget.post.id, widget.comment);
      loadReplies(widget.post.id, widget.comment.id);
    } else {
      repliesInitLikes(widget.post.id, widget.comment, widget.parentComment.id);
    }

    ///Set up listener here
    scrollController.addListener(() {
      if (scrollController.offset >=
              scrollController.position.maxScrollExtent &&
          !scrollController.position.outOfRange) {
        print('reached the bottom');
        //nextComments();
      } else if (scrollController.offset <=
              scrollController.position.minScrollExtent &&
          !scrollController.position.outOfRange) {
        print("reached the top");
      } else {}
    });
  }

  mentionedUserProfile(String w) async {
    String username = w.substring(1);
    User user = await DatabaseService.getUserWithUsername(username);
    Navigator.of(context)
        .pushNamed('/user-profile', arguments: {'userId': user.id});
    print(w);
  }
}
