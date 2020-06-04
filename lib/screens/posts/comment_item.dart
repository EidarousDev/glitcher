import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/models/comment_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/caching_image.dart';

class CommentItem extends StatefulWidget {
  final Comment comment;
  final User commenter;

  CommentItem({Key key, @required this.comment, @required this.commenter})
      : super(key: key);
  @override
  _CommentItemState createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  @override
  Widget build(BuildContext context) {
    print(
        'user: ${widget.commenter.username} and comment: ${widget.comment.text} ');
    return SafeArea(
      child: Column(
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

  @override
  void initState() {
    super.initState();
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
