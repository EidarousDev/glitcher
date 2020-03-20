import 'package:flutter/material.dart';
import 'package:glitcher/models/comment_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/utils/constants.dart';
import 'package:glitcher/utils/functions.dart';

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
                child: widget.commenter.profileImageUrl != null
                    ? CircleAvatar(
                        radius: 30.0,
                        backgroundImage: NetworkImage(widget.commenter
                            .profileImageUrl), // no matter how big it is, it won't overflow
                      )
                    : CircleAvatar(
                        backgroundImage:
                            AssetImage('assets/images/default_profile.png'),
                      ),
                onTap: () {
                  Navigator.of(context).pushNamed('/user-profile', arguments: {
                    'userId': widget.comment.commenterID,
                  });
                }),
            title: InkWell(
              child: widget.commenter.name == null
                  ? ''
                  : RichText(
                      text: TextSpan(
                        // Note: Styles for TextSpans must be explicitly defined.
                        // Child text spans will inherit styles from parent
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Constants.darkPrimary,
                        ),
                        children: <TextSpan>[
                          TextSpan(text: '${widget.commenter.name}'),
                          TextSpan(
                              text: ' @${widget.commenter.username}',
                              style: TextStyle(color: Constants.darkGrey)),
                          TextSpan(
                              text:
                                  ' - ${Functions.formatCommentsTimestamp(widget.comment.timestamp)}',
                              style: TextStyle(color: Constants.darkAccent)),
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
                ? ''
                : Wrap(
                    children: <Widget>[Text('${widget.comment.text}')],
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
                    color: currentTheme == AvailableThemes.LIGHT_THEME
                        ? Constants.lightLineBreak
                        : Constants.darkLineBreak),
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
}