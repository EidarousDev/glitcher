import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/models/group_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/notification_handler.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:glitcher/widgets/bottom_sheets/profile_image_edit_bottom_sheet.dart';
import 'package:glitcher/widgets/caching_image.dart';
import 'package:glitcher/widgets/custom_loader.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';
import 'package:glitcher/widgets/image_overlay.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math' show Random;
import 'package:random_string/random_string.dart';

class GroupDetails extends StatefulWidget {
  final groupId;

  GroupDetails(this.groupId);

  @override
  _GroupDetailsState createState() => _GroupDetailsState(groupId);
}

class _GroupDetailsState extends State<GroupDetails>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  List<User> friendsData;

  Group _group;
  String groupId;

  bool _editing = false;

  TextEditingController _textEditingController = TextEditingController();

  List<String> groupMembersIds = [];

  _GroupDetailsState(this.groupId);

  @override
  void initState() {
    super.initState();
    getGroup();
    getGroupMembersIds();
  }

  getGroup() async {
    Group group = await DatabaseService.getGroupWithId(groupId);
    setState(() {
      _group = group;
    });
  }

  getGroupMembersIds() async {
    List<String> usersIds = [];
    QuerySnapshot usersSnapshot = await chatGroupsRef
        .document(widget.groupId)
        .collection('users')
        .getDocuments();
    usersSnapshot.documents.forEach((doc) {
      usersIds.add(doc.documentID);
    });

    //print('member: ${usersIds[0]}');
    setState(() {
      groupMembersIds = usersIds;
    });
  }

  editImage() async {
    ImageEditBottomSheet bottomSheet = ImageEditBottomSheet();
    bottomSheet.optionIcon(context);
    File image = await AppUtil.chooseImage();
    showDialog(
        barrierDismissible: true,
        child: Container(
          width: Sizes.sm_profile_image_w,
          height: Sizes.sm_profile_image_h,
          child: ImageOverlay(
            imageFile: image,
            btnText: 'Upload',
            btnFunction: () async {
              String url = await AppUtil.uploadFile(
                  image, context, 'group_chat_images/$groupId',
                  groupMembersIds: groupMembersIds);

              await chatGroupsRef.document(groupId).updateData({'image': url});

              getGroup();

              Navigator.of(context).pop();
            },
          ),
        ),
        context: context);
  }

  exitGroup() {
    showDialog(
      context: context,
      builder: (context) => Container(
        height: 100,
        width: 100,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AlertDialog(
            title: Text('Are you sure?'),
            content: Text('Do you want to exit this group?'),
            actions: <Widget>[
              GestureDetector(
                onTap: () async {
                  Navigator.of(context).push(CustomScreenLoader());

                  await DatabaseService.removeGroupMember(
                      groupId, Constants.currentUserID);

                  Navigator.of(context).pop();

                  Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                },
                child: Text("Yes"),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("NO"),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        appBar: AppBar(
          flexibleSpace: gradientAppBar(),
          title: Text(_group.name),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Stack(
                children: <Widget>[
                  GestureDetector(
                    onTap: () async {
                      editImage();
                    },
                    child: CacheThisImage(
                      imageUrl: _group?.image,
                      imageShape: BoxShape.rectangle,
                      height: 300,
                      defaultAssetImage: Strings.default_profile_image,
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(
                          Icons.person_add,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          Navigator.pushNamed(context, '/group-members',
                              arguments: {'groupId': groupId});
                        },
                      ),
                    ),
                  ),
                  gameName(),
                  gameEditButton(),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                decoration: BoxDecoration(
                  color: MyColors.darkPrimary,
                  border: Border.all(color: MyColors.darkAccent, width: 3),
                  boxShadow: <BoxShadow>[],
                ),
                child: ListTile(
                  onTap: () async {
                    exitGroup();
                  },
                  title: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.white),
                      SizedBox(
                        width: 20,
                      ),
                      Text(
                        'Exit group',
                        style: TextStyle(fontSize: 18),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ));
  }

  gameName() {
    return _editing
        ? Positioned.fill(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 80, bottom: 8),
                child: TextField(
                  cursorColor: MyColors.darkPrimary,
                  style: TextStyle(fontSize: 30),
                  textAlign: TextAlign.left,
                  controller: _textEditingController,
                ),
              ),
            ),
          )
        : Positioned.fill(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _group.name,
                  style: TextStyle(fontSize: 30),
                ),
              ),
            ),
          );
  }

  gameEditButton() {
    return !_editing
        ? Positioned.fill(
            child: Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _editing = !_editing;
                    _textEditingController.text = _group.name;
                  });
                },
              ),
            ),
          )
        : Positioned.fill(
            child: Align(
              alignment: Alignment.bottomRight,
              child: RawMaterialButton(
                elevation: 2.0,
                fillColor: Colors.white,
                shape: CircleBorder(),
                child: Icon(
                  Icons.done,
                  color: Colors.black,
                ),
                onPressed: () async {
                  await chatGroupsRef
                      .document(groupId)
                      .updateData({'name': _textEditingController.text});

                  getGroup();

                  setState(() {
                    print('To save group name');
                    setState(() {
                      _editing = false;
                    });
                  });
                },
              ),
            ),
          );
  }

  @override
  bool get wantKeepAlive => true;
}
