import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/models/comment_model.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/notification_handler.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/custom_widgets.dart';

class CommentBottomSheet {
  Widget commentOptionIcon(
      BuildContext context, Post post, Comment comment, Comment parentComment) {
    return customInkWell(
        radius: BorderRadius.circular(20),
        context: context,
        onPressed: () {
          _openBottomSheet(context, post, comment, parentComment);
        },
        child: Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_drop_down),
        ));
  }

  void _openBottomSheet(BuildContext context, Post post, Comment comment,
      Comment parentComment) async {
    User user = await DatabaseService.getUserWithId(comment.commenterID);
    bool isMyComment = Constants.currentUserID == comment.commenterID;
    await showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
            padding: EdgeInsets.only(top: 5, bottom: 0),
            height: Sizes.fullHeight(context) * (isMyComment ? .25 : .44),
            width: Sizes.fullWidth(context),
            decoration: BoxDecoration(
              color: switchColor(
                  MyColors.lightButtonsBackground, MyColors.darkAccent),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: _commentOptions(
                context, isMyComment, post, comment, parentComment, user));
      },
    );
  }

  Widget _commentOptions(BuildContext context, bool isMyComment, Post post,
      Comment comment, Comment parentComment, User user) {
    return Column(
      children: <Widget>[
        Container(
          width: Sizes.fullWidth(context) * .1,
          height: 5,
          decoration: BoxDecoration(
            color: switchColor(MyColors.lightPrimary, Colors.white70),
            borderRadius: BorderRadius.all(
              Radius.circular(10),
            ),
          ),
        ),
        isMyComment
            ? _widgetBottomSheetRow(
                context,
                Icon(Icons.edit),
                text: 'Edit Comment',
                onPressed: () {
                  if (parentComment == null) {
                    Navigator.of(context).pushNamed('/edit-comment',
                        arguments: {
                          'post': post,
                          'user': user,
                          'comment': comment
                        });
                  } else {
                    Navigator.of(context).pushNamed('/edit-reply', arguments: {
                      'post': post,
                      'comment': parentComment,
                      'reply': comment,
                      'user': user
                    });
                  }
                },
                isEnable: true,
              )
            : Container(),
        isMyComment
            ? _widgetBottomSheetRow(
                context,
                Icon(Icons.delete_forever),
                text: 'Delete Comment',
                onPressed: () {
                  _deleteComment(context, post.id, comment.id,
                      parentComment == null ? null : parentComment.id);
                },
                isEnable: true,
              )
            : Container(),
        isMyComment
            ? Container()
            : _widgetBottomSheetRow(
                context,
                Icon(Icons.indeterminate_check_box),
                text: 'Unfollow ${user.username}',
              ),
        isMyComment
            ? Container()
            : _widgetBottomSheetRow(
                context,
                Icon(Icons.volume_mute),
                text: 'Mute ${user.username}',
              ),
        isMyComment
            ? Container()
            : _widgetBottomSheetRow(
                context,
                Icon(Icons.block),
                text: 'Block ${user.username}',
              ),
//        isMyComment
//            ? Container()
//            : _widgetBottomSheetRow(
//                context,
//                Icon(Icons.report),
//                text: 'Report Post',
//              ),
      ],
    );
  }

  Widget _widgetBottomSheetRow(BuildContext context, Icon icon,
      {String text, Function onPressed, bool isEnable = false}) {
    return Expanded(
      child: customInkWell(
        context: context,
        onPressed: () {
          if (onPressed != null)
            onPressed();
          else {
            Navigator.pop(context);
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: <Widget>[
              icon,
              SizedBox(
                width: 15,
              ),
              customText(
                text,
                context: context,
                style: TextStyle(
                  color: isEnable ? MyColors.darkPrimary : MyColors.darkGrey,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _deleteComment(BuildContext context, String postId, String commentId,
      String parentCommentId) async {
    await showDialog(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: new AlertDialog(
          title: new Text('Are you sure?'),
          content: new Text('Do you really want to delete this comment?'),
          actions: <Widget>[
            new GestureDetector(
              onTap: () =>
                  // CLose bottom sheet
                  Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("NO"),
              ),
            ),
            SizedBox(height: 16),
            new GestureDetector(
              onTap: () async {
                await DatabaseService.deleteComment(
                    postId, commentId, parentCommentId);

                await NotificationHandler.removeNotification(
                    (await DatabaseService.getPostWithId(postId)).authorId,
                    postId,
                    'comment');

                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/post', arguments: {
                  'post': await DatabaseService.getPostWithId(postId)
                });
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
    Navigator.of(context).pop();
    print('deleting comment!');
  }

  void _bookmarkPost(String postId) async {
    await DatabaseService.addPostToBookmarks(postId);
  }
}
