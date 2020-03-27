import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/constants/constants.dart';

class AddCommentScreen extends StatefulWidget {
  final String username;
  final String userId;
  final String postId;
  final String profileImageUrl;

  const AddCommentScreen(
      {Key key,
      this.username,
      this.userId,
      this.postId,
      this.profileImageUrl = null})
      : super(key: key);
  @override
  _AddCommentScreenState createState() => _AddCommentScreenState();
}

class _AddCommentScreenState extends State<AddCommentScreen> {
  String _commentText;

  /// Comment Text
  var _commentTextController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text('New Comment'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.send,
              color: Colors.white,
            ),
            onPressed: () {
              DatabaseService.addComment(widget.postId, _commentText);
              Navigator.pop(context);
            },
          ),
        ],
        leading: IconButton(
          icon: Icon(
            Icons.clear,
            color: Constants.darkGrey,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: <Widget>[
          RichText(
            text: TextSpan(
              // Note: Styles for TextSpans must be explicitly defined.
              // Child text spans will inherit styles from parent
              style: TextStyle(
                fontSize: 15.0,
                color: Constants.darkPrimary,
              ),
              children: <TextSpan>[
                TextSpan(text: 'Replying to '),
                TextSpan(
                  text: ' @${widget.username}',
                  style: TextStyle(color: Constants.darkGrey),
                  recognizer: new TapGestureRecognizer()
                    ..onTap = () => Navigator.of(context)
                            .pushNamed('/user-profile', arguments: {
                          'userId': widget.userId,
                        }),
                ),
              ],
            ),
          ),
          Container(
            height: 350,
            child: TextFormField(
              maxLength: 250,
              maxLines: 10,
              maxLengthEnforced: true,
              autofocus: true,
              minLines: 1,
              controller: _commentTextController,
              onChanged: (value) {
                setState(() {
                  _commentText = value;
                });
              },
              decoration: InputDecoration(
                fillColor: Constants.darkBG,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 25.0, horizontal: 12.0),
                hintText: 'Leave your comment',
                filled: true,
                prefixIcon: InkWell(
                    child: widget.profileImageUrl != null
                        ? CircleAvatar(
                            radius: 30.0,
                            backgroundImage: NetworkImage(
                                loggedInProfileImageURL), // no matter how big it is, it won't overflow
                          )
                        : CircleAvatar(
                            backgroundImage:
                                AssetImage('assets/images/default_profile.png'),
                          ),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed('/user-profile', arguments: {
                        'userId': widget.userId,
                      });
                    }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentTextController.dispose();
    super.dispose();
  }
}
