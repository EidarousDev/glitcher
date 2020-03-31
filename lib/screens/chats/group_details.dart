import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/models/group_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
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

  var _url;

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
                    onPressed: () {
                      chooseImage();
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

  Future uploadFile(File file, BuildContext context) async {
    if (file == null) return;

    print((file));

    StorageReference storageReference = FirebaseStorage.instance
        .ref()
        .child('group_chats_images/')
        .child(randomAlphaNumeric(20));
    StorageUploadTask uploadTask = storageReference.putFile(file);

    await uploadTask.onComplete;
    print('File Uploaded');
    _url = await storageReference.getDownloadURL();
  }

  Future chooseImage() async {
    await ImagePicker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 52,
            maxHeight: 400,
            maxWidth: 600)
        .then((image) {
      showDialog(
          barrierDismissible: true,
          child: Container(
            width: Sizes.sm_profile_image_w,
            height: Sizes.sm_profile_image_h,
            child: ImageOverlay(
              imageFile: image,
              btnText: 'Upload',
              btnFunction: () async {
                await uploadFile(image, context);

                await chatGroupsRef
                    .document(groupId)
                    .updateData({'image': _url});

                getGroup();

                Navigator.of(context).pop();
              },
            ),
          ),
          context: context);
    });
  }

  @override
  bool get wantKeepAlive => true;
}
