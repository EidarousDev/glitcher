import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/notification_handler.dart';
import 'package:glitcher/services/permissions_service.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:glitcher/widgets/bottom_sheets/profile_image_edit_bottom_sheet.dart';
import 'package:glitcher/widgets/caching_image.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';
import 'package:random_string/random_string.dart';

class NewGroup extends StatefulWidget {
  @override
  _NewGroupState createState() => _NewGroupState();
}

class _NewGroupState extends State<NewGroup>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  List<User> friendsData = [];
  List<bool> chosens = [];
  List<Map<String, dynamic>> chosenUsers;

  TextEditingController textEditingController = TextEditingController();

  ScrollController _scrollController;

  File _imageFile;

  String _imageUrl;

  String _groupId;

  getFriends() async {
    List<User> friends = await DatabaseService.getAllMyFriends();

    for (int i = 0; i < friends.length; i++) {
      User user =
          await DatabaseService.getUserWithId(friends[i].id, checkLocal: true);

      setState(() {
        friendsData.add(user);
        chosens.add(false);
      });
    }

    return friends;
  }

  @override
  void initState() {
    super.initState();
    getFriends();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: MyColors.darkPrimary,
        child: Icon(
          Icons.done,
        ),
        onPressed: () async {
          chosenUsers = [];
          for (int i = 0; i < chosens.length; i++) {
            if (chosens[i]) {
              chosenUsers
                  .add({'user_id': friendsData[i].id, 'is_admin': false});
            }
          }

          chosenUsers
              .add({'user_id': Constants.currentUserID, 'is_admin': true});

          _groupId = randomAlphaNumeric(20);

          _imageUrl = await AppUtil.uploadFile(
              _imageFile, context, 'group_chat_images/$_groupId');
          await addGroup();
          await addGroupToUsers();
          Navigator.of(context).pushNamed('/chats');
        },
      ),
      appBar: AppBar(
          flexibleSpace: gradientAppBar(),
//        elevation: 4,
          leading: IconButton(
            icon: Icon(
              Icons.keyboard_backspace,
            ),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/chats');
            },
          ),
          title: Text('New Group')

//        TextField(
//          decoration: InputDecoration.collapsed(
//            hintText: 'Search',
//          ),
//        ),
          ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 50,
            leading: Container(),
            flexibleSpace: Container(
              color: MyColors.darkBG,
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () async {
                          bool isGranted = await PermissionsService()
                              .requestStoragePermission(context,
                                  onPermissionDenied: () {
                            print('Permission has been denied');
                          });

                          if (isGranted) {
                            ImageEditBottomSheet bottomSheet =
                                ImageEditBottomSheet();
                            bottomSheet.optionIcon(context);
                            _imageFile = await AppUtil.chooseImage();
                          } else {
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Info'),
                                    content: Text(
                                        'You must grant this storage access to be able to use this feature.'),
                                    actions: <Widget>[
                                      MaterialButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('OK'),
                                      )
                                    ],
                                  );
                                });
                          }
                        },
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white,
                          child: _imageFile == null
                              ? Icon(Icons.camera_alt)
                              : null,
                          backgroundImage:
                              _imageFile != null ? FileImage(_imageFile) : null,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Expanded(
                      flex: 10,
                      child: TextField(
                        autofocus: true,
                        cursorColor: MyColors.darkPrimary,
                        controller: textEditingController,
                        decoration: InputDecoration.collapsed(
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          hintText: 'Group name',
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              ListView.separated(
                physics: NeverScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                padding: EdgeInsets.all(10),
                separatorBuilder: (BuildContext context, int index) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      height: 0.5,
                      width: MediaQuery.of(context).size.width / 1.3,
                      child: Divider(),
                    ),
                  );
                },
                itemCount: friendsData.length,
                itemBuilder: (BuildContext context, int index) {
                  //User user = groups[index];
                  return ListTile(
                    contentPadding: EdgeInsets.all(0),
                    leading: Stack(
                      children: <Widget>[
                        CacheThisImage(
                          imageUrl:
                              friendsData.elementAt(index).profileImageUrl,
                          imageShape: BoxShape.circle,
                          width: 50.0,
                          height: 50.0,
                          defaultAssetImage: Strings.default_group_image,
                        ),
                        Positioned(
                          bottom: 0.0,
                          left: 6.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            height: 11,
                            width: 11,
                            child: Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: friendsData.elementAt(index).online ==
                                          'online'
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                height: 7,
                                width: 7,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      friendsData.elementAt(index).username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(friendsData.elementAt(index).description),
                    trailing: Checkbox(
                        checkColor: Colors.white,
                        activeColor: MyColors.darkPrimary,
                        value: chosens[index],
                        onChanged: (value) {
                          setState(() {
                            chosens[index] = value;
                          });
                          print(value);
                        }),
                  );
                },
              )
            ]),
          )
        ],
      ),
    );
  }

  addGroup() async {
    await chatGroupsRef.doc(_groupId).set({
      'name': textEditingController.text,
      'image': _imageUrl,
      'timestamp': FieldValue.serverTimestamp()
    });

    for (Map<String, dynamic> user in chosenUsers) {
      chatGroupsRef.doc(_groupId).collection('users').doc(user['user_id']).set({
        'is_admin': user['is_admin'],
        'timestamp': FieldValue.serverTimestamp()
      });
    }
  }

  addGroupToUsers() async {
    for (Map<String, dynamic> user in chosenUsers) {
      await usersRef
          .doc(user['user_id'])
          .collection('chat_groups')
          .doc(_groupId)
          .set({'timestamp': FieldValue.serverTimestamp()});

      await NotificationHandler.sendNotification(
          user['user_id'],
          'New chat group',
          'You\'ve been added to a new chat group "${textEditingController.text}"',
          _groupId,
          'new_group');
    }
  }

  @override
  bool get wantKeepAlive => true;
}
