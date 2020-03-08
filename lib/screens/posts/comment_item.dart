import 'package:flutter/material.dart';
import 'package:glitcher/models/comment_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/constants.dart';
import 'package:glitcher/widgets/comment_bubble.dart';

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
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 25.0,
            backgroundColor: Colors.grey,
            backgroundImage: widget.commenter.profileImageUrl != null
                ? NetworkImage(widget.commenter.profileImageUrl)
                : AssetImage('assets/images/default_profile.png'),
          ),
          Align(
            alignment: Alignment
                .topLeft, //Change this to Alignment.topRight or Alignment.topLeft
            child: CustomPaint(
              painter: CommentBubble(
                  color: currentTheme == AvailableThemes.LIGHT_THEME
                      ? Constants.lightAccent
                      : Constants.darkAccent,
                  alignment: Alignment.bottomLeft),
              child: Container(
                padding: EdgeInsets.fromLTRB(8.0, 4.0, 4.0, 4.0),
                margin: EdgeInsets.all(10),
                child: Column(
                  children: <Widget>[
                    InkWell(
                      child: Text('@${widget.commenter.username}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Constants.darkPrimary)),
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed('/user-profile', arguments: {
                          'userId': widget.comment.commenterID,
                        });
                      },
                    ),
                    SizedBox(
                      height: 8.0,
                    ),
                    Text(widget.comment.text),
                  ],
                ),
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
