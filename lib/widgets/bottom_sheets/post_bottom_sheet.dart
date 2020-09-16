import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/font_awesome.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/notification_handler.dart';
import 'package:glitcher/services/share_link.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/custom_loader.dart';
import 'package:glitcher/widgets/custom_widgets.dart';

class PostBottomSheet {
  Widget postOptionIcon(BuildContext context, Post post) {
    return customInkWell(
        radius: BorderRadius.circular(20),
        context: context,
        onPressed: () {
          _openBottomSheet(context, post);
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

  double calculateHeightRatio(bool isMyPost) {
    double ratio = 1.0;
    if (!isMyPost && Constants.routesStack.top() != '/post') {
      ratio = 0.375;
    } else if (!isMyPost && Constants.routesStack.top() == '/post') {
      ratio = 0.3;
    } else if (isMyPost && Constants.routesStack.top() != '/post') {
      ratio = 0.375;
    } else if (isMyPost && Constants.routesStack.top() == '/post') {
      ratio = 0.31;
    }
    return ratio;
  }

  void _openBottomSheet(BuildContext context, Post post) async {
    print('route: ${Constants.routesStack.top()}');
    User user = await DatabaseService.getUserWithId(post.authorId);
    bool isMyPost = Constants.currentUserID == post.authorId;
    await showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
            padding: EdgeInsets.only(top: 5, bottom: 0),
            height: Sizes.fullHeight(context) * calculateHeightRatio(isMyPost),
            width: Sizes.fullWidth(context),
            decoration: BoxDecoration(
              color: switchColor(
                  MyColors.lightButtonsBackground, MyColors.darkAccent),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: _postOptions(context, isMyPost, post, user));
      },
    );
  }

  Widget _postOptions(
      BuildContext context, bool isMyPost, Post post, User user) {
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
        Constants.routesStack.top() != '/post'
            ? _widgetBottomSheetRow(context, Icon(Icons.remove_red_eye),
                text: 'Preview Post', onPressed: () async {
                if (Constants.routesStack.top() == '/post')
                  return;
                else {
                  Navigator.of(context).pushNamed('/post', arguments: {
                    'post': post,
                  });
                }
              })
            : Container(),
        InkWell(
          onTap: () async {
            var postLink = await DynamicLinks.createPostDynamicLink({
              'postId': post.id,
              'text': post.text,
              'imageUrl': post.imageUrl
            });
            var text = ClipboardData(text: '$postLink');
            Clipboard.setData(text);
            //AppUtil().showToast('Post copied to clipboard');
          },
          child: _widgetBottomSheetRow(
            context,
            Icon(Icons.link),
            text: 'Copy link to post',
          ),
        ),
        Constants.routesStack.top() == '/bookmarks'
            ? _widgetBottomSheetRow(
                context,
                Icon(Icons.close),
                text: 'Remove post from bookmarks',
                onPressed: () async {
                  await DatabaseService.removePostFromBookmarks(post.id);
                  Constants.routesStack.pop();
                  Navigator.of(context).pushReplacementNamed('/bookmarks');
                },
              )
//            Container()
            : _widgetBottomSheetRow(
                context,
                Icon(Icons.bookmark),
                text: 'Bookmark this post',
                onPressed: () {
                  _bookmarkPost(post.id, context);
                },
              ),
        isMyPost
            ? _widgetBottomSheetRow(
                context,
                Icon(Icons.edit),
                text: 'Edit this post',
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed('/edit-post', arguments: {'post': post});
                },
              )
            : Container(),
        isMyPost
            ? _widgetBottomSheetRow(
                context,
                Icon(Icons.delete_forever),
                text: 'Delete Post',
                onPressed: () {
                  _deletePost(
                    context,
                    post.id,
                  );
                },
                isEnable: true,
              )
            : Container(),
        isMyPost
            ? Container()
            : _widgetBottomSheetRow(
                context, Icon(Icons.indeterminate_check_box),
                text: 'Unfollow ${user.username}', onPressed: () async {
                unfollowUser(context, user);
              }),

//        isMyPost
//            ? Container()
//            : _widgetBottomSheetRow(
//                context,
//                Icon(Icons.block),
//                text: 'Block ${user.username}',
//              ),
//        isMyPost
//            ? Container()
//            :
        !isMyPost
            ? _widgetBottomSheetRow(context, Icon(Icons.report),
                text: 'Report Post', onPressed: () async {
                Navigator.of(context).pushNamed('/report-post', arguments: {
                  'post_author': post.authorId,
                  'post_id': post.id
                });
              })
            : Container(),
      ],
    );
  }

  Widget _widgetBottomSheetRow(BuildContext context, Icon icon,
      {String text, Function onPressed, bool isEnable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Flex(
        direction: Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.center,
        verticalDirection: VerticalDirection.down,
        children: [
          Expanded(
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
                        color:
                            isEnable ? MyColors.darkPrimary : MyColors.darkGrey,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _deletePost(BuildContext context, String postId) async {
    await showDialog(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: new AlertDialog(
          title: new Text('Are you sure?'),
          content: new Text('Do you really want to delete this post?'),
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
                await DatabaseService.deletePost(postId);
                Navigator.of(context).pop();
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
    Constants.routesStack.pop();
    Navigator.of(context).pushReplacementNamed('/home');
    print('deleting post!');
  }

  void unfollowUser(BuildContext context, User user) async {
    await showDialog(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: new AlertDialog(
          title: new Text('Are you sure?'),
          content: new Text('Do you really want to unfollow ${user.username}?'),
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
                Navigator.of(context).push(CustomScreenLoader());

                await DatabaseService.unfollowUser(user.id);
                await NotificationHandler.removeNotification(
                    user.id, Constants.currentUserID, 'follow');
                Navigator.of(context).pop();
                Navigator.of(context).pop();
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
    Navigator.of(context).pushReplacementNamed('/home');
    print('deleting post!');
  }

  void _bookmarkPost(String postId, BuildContext context) async {
    await DatabaseService.addPostToBookmarks(postId);
    Navigator.of(context).pop();
  }
}
