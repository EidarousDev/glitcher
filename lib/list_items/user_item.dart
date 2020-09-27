import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:glitcher/widgets/caching_image.dart';
import 'package:glitcher/widgets/custom_loader.dart';

class UserItem extends StatefulWidget {
  final User user;

  UserItem({Key key, this.user}) : super(key: key);

  @override
  _UserItemState createState() => _UserItemState();
}

class _UserItemState extends State<UserItem> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListTile(
        onTap: () {
          Navigator.of(context).pushNamed('/user-profile', arguments: {
            'userId': widget.user.id,
          });
        },
        contentPadding: EdgeInsets.all(10),
        leading: InkWell(
            child: CacheThisImage(
              imageUrl: widget.user.profileImageUrl,
              imageShape: BoxShape.circle,
              width: Sizes.md_profile_image_w,
              height: Sizes.md_profile_image_h,
              defaultAssetImage: Strings.default_profile_image,
            ),
            onTap: () {
              Navigator.of(context).pushNamed('/user-profile', arguments: {
                'userId': widget.user.id,
              });
            }),
        title: Text(widget.user.username),
        trailing: widget.user.id != Constants.currentUserID
            ? ButtonTheme(
                height: 20,
                minWidth: 40,
                child: MaterialButton(
                  height: 30,
                  onPressed: () {
                    followUnfollow();
                  },
                  textColor: Colors.white,
                  color: MyColors.badgeColor,
                  child: Text(followBtnText == null ? '' : followBtnText),
                ),
              )
            : null,
      ),
    );
  }

  String followBtnText;
  String snackbarText;

  followUnfollow() async {
    Navigator.of(context).push(CustomScreenLoader());

    DocumentSnapshot user = await usersRef
        .document(Constants.currentUserID)
        .collection('following')
        .document(widget.user.id)
        .get();

    if (user.exists) {
      await DatabaseService.unfollowUser(widget.user.id);
      setState(() {
        followBtnText = 'Follow';
      });
    } else {
      await DatabaseService.followUser(widget.user.id);
      setState(() {
        followBtnText = 'Unfollow';
      });
    }
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    checkStates();
  }

  checkStates() async {
    DocumentSnapshot user = await usersRef
        .document(Constants.currentUserID)
        .collection('following')
        .document(widget.user.id)
        .get();

    if (user.exists) {
      if (mounted) {
        setState(() {
          followBtnText = 'Unfollow';
        });
      }
    } else {
      if (mounted) {
        setState(() {
          followBtnText = 'Follow';
        });
      }
    }
  }
}
