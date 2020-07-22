import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/models/group_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:glitcher/widgets/bottom_sheets/profile_image_edit_bottom_sheet.dart';
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

  _GroupDetailsState(this.groupId);

  @override
  void initState() {
    super.initState();
    getGroup();
  }

  getGroup() async {
    Group group = await DatabaseService.getGroupWithId(groupId);
    setState(() {
      _group = group;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        appBar: AppBar(),
        body: Column(
          children: <Widget>[
            Stack(
              children: <Widget>[
                Image.network(
                  _group?.image,
                  fit: BoxFit.fill,
                  width: MediaQuery.of(context).size.width,
                  height: 300,
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () async{
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
                                String url = await AppUtil.uploadFile(image, context, 'group_chats_images/$groupId');

                                await chatGroupsRef
                                    .document(groupId)
                                    .updateData({'image': url});

                                getGroup();

                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                          context: context);
                    },
                  ),
                )
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _editing
                    ? Container(
                        width: 200,
                        child: TextField(
                          textAlign: TextAlign.center,
                          controller: _textEditingController,
                        ),
                      )
                    : Text(
                        _group.name,
                        style: TextStyle(fontSize: 24),
                      ),
                SizedBox(
                  width: 10,
                ),
                !_editing
                    ? IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          setState(() {
                            _editing = !_editing;
                            _textEditingController.text = _group.name;
                          });
                        },
                      )
                    : RawMaterialButton(
                        elevation: 2.0,
                        fillColor: Colors.white30,
                        shape: CircleBorder(),
                        child: Icon(
                          Icons.done,
                        ),
                        onPressed: () async {
                          await chatGroupsRef.document(groupId).updateData(
                              {'name': _textEditingController.text});

                          getGroup();

                          setState(() {
                            print('To save group name');
                            setState(() {
                              _editing = false;
                            });
                          });
                        },
                      ),
              ],
            )
          ],
        ));
  }

  @override
  bool get wantKeepAlive => true;
}
