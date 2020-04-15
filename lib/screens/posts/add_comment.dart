import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/services/notification_handler.dart';

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
  _AddCommentScreenState createState() =>
      _AddCommentScreenState(postId: postId);
}

class _AddCommentScreenState extends State<AddCommentScreen> {
  String postId;
  _AddCommentScreenState({@required this.postId});
  Post post;

  String _commentText = '';

  /// Comment Text
  var _commentTextController = TextEditingController();
  var words = [];

  NotificationHandler notificationHandler =
      NotificationHandler(); // to split the characters for the mention user feature
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
            onPressed: () async {
              if (_commentTextController.text.isNotEmpty) {
                DatabaseService.addComment(
                    widget.postId, _commentTextController.text);

                post = await DatabaseService.getPostWithId(postId);

                await notificationHandler.sendNotification(
                    post.authorId,
                    Constants.loggedInUser.username + ' commented on your post',
                    _commentTextController.text,
                    postId);

                checkIfContainsMention(_commentTextController.text);

                Navigator.pop(context);
              } else {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (BuildContext context) {
                    // return object of type Dialog
                    return AlertDialog(
                      content: new Text("A comment can't be empty!"),
                      actions: <Widget>[
                        new FlatButton(
                          child: new Text("Ok"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
        ],
        leading: IconButton(
          icon: Icon(
            Icons.clear,
            color: MyColors.darkGrey,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 15,
          ),
          RichText(
            text: TextSpan(
              // Note: Styles for TextSpans must be explicitly defined.
              // Child text spans will inherit styles from parent
              style: TextStyle(
                fontSize: 15.0,
                color: MyColors.darkPrimary,
              ),
              children: <TextSpan>[
                TextSpan(text: 'Replying to '),
                TextSpan(
                  text: ' @${widget.username}',
                  style: TextStyle(color: MyColors.darkGrey),
                  recognizer: new TapGestureRecognizer()
                    ..onTap = () => Navigator.of(context)
                            .pushNamed('/user-profile', arguments: {
                          'userId': widget.userId,
                        }),
                ),
              ],
            ),
          ),
          Column(children: <Widget>[
            TextFormField(
              maxLength: 250,
              maxLines: 10,
              maxLengthEnforced: true,
              autofocus: true,
              minLines: 1,
              controller: _commentTextController,
              onChanged: (value) {
                setState(() {
                  words = value.split(' ');
                  _commentText = words.length > 0 &&
                          words[words.length - 1].startsWith('@')
                      ? words[words.length - 1]
                      : '';
                  //_commentText = value;
                });
              },
              decoration: InputDecoration(
                fillColor: MyColors.darkBG,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 25.0, horizontal: 12.0),
                hintText: 'Leave your comment',
                filled: true,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                      child: widget.profileImageUrl != null
                          ? CircleAvatar(
                              radius: 30.0,
                              backgroundImage: NetworkImage(
                                  loggedInProfileImageURL), // no matter how big it is, it won't overflow
                            )
                          : CircleAvatar(
                              backgroundImage: AssetImage(
                                  'assets/images/default_profile.png'),
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
            _commentText.length > 1
                ? ListView.builder(
                    itemCount: Constants.userFriends.length,
                    itemBuilder: (context, index) {
                      String s = Constants.userFriends[index].username;
                      print('username:' + s);
                      if (('@' + s).contains(_commentText))
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                                Constants.userFriends[index].profileImageUrl),
                          ),
                          title: Text(Constants.userFriends[index].username),
                          onTap: () {
                            String tmp =
                                _commentText.substring(1, _commentText.length);
                            setState(() {
                              _commentText = '';
                              _commentTextController.text += s
                                  .substring(
                                      s.indexOf(tmp) + tmp.length, s.length)
                                  .replaceAll(' ', '_');
                            });
                          },
                        );

                      return SizedBox();
                    },
                    shrinkWrap: true,
                  )
                : SizedBox(),
          ]),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentTextController.dispose();
    super.dispose();
  }

  void checkIfContainsMention(String comment) async {
    comment.split(' ').forEach((word) async {
      if (word.startsWith('@')) {
        User user =
            await DatabaseService.getUserWithUsername(word.substring(1));

        await notificationHandler.sendNotification(
            user.id,
            'New post mention',
            Constants.loggedInUser.username + ' mentioned you in a post',
            postId);
      }
    });
  }
}
