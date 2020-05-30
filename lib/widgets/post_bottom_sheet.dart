import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/custom_widgets.dart';

class PostBottomSheet {
  Widget postOptionIcon(BuildContext context, Post post) {
    return customInkWell(
        radius: BorderRadius.circular(20),
        context: context,
        onPressed: () {
          _openbottomSheet(context, post);
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

  void _openbottomSheet(BuildContext context, Post post) async {
    bool isMyPost = Constants.currentUserID == post.authorId;
    await showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
            padding: EdgeInsets.only(top: 5, bottom: 0),
            height: Sizes.fullHeight(context) * (isMyPost ? .25 : .44),
            width: Sizes.fullWidth(context),
            decoration: BoxDecoration(
              color: switchColor(
                  MyColors.lightButtonsBackground, MyColors.darkAccent),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: _postOptions(context, isMyPost, post));
      },
    );
  }

  Widget _postOptions(BuildContext context, bool isMyPost, Post post) {
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
        _widgetBottomSheetRow(
          context,
          Icon(Icons.link),
          text: 'Copy link to post',
        ),
        isMyPost
            ? _widgetBottomSheetRow(
                context,
                Icon(Icons.favorite),
                text: 'Pin to profile',
              )
            : _widgetBottomSheetRow(
                context,
                Icon(Icons.android),
                text: 'Not interested in this',
              ),
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
                context,
                Icon(Icons.indeterminate_check_box),
                text: 'Unfollow ${post.authorId}',
              ),
        isMyPost
            ? Container()
            : _widgetBottomSheetRow(
                context,
                Icon(Icons.volume_mute),
                text: 'Mute ${post.authorId}',
              ),
        isMyPost
            ? Container()
            : _widgetBottomSheetRow(
                context,
                Icon(Icons.block),
                text: 'Block ${post.authorId}',
              ),
        isMyPost
            ? Container()
            : _widgetBottomSheetRow(
                context,
                Icon(Icons.report),
                text: 'Report Post',
              ),
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

  void _deletePost(BuildContext context, String postId) {
    print('deleting post!');
    // CLose bottom sheet
    Navigator.of(context).pop();
  }
}
