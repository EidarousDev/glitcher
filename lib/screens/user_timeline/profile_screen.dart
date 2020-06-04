import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/common_widgets/circular_clipper.dart';
import 'package:glitcher/common_widgets/gradient_appbar.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/screens/fullscreen_overaly.dart';
import 'package:glitcher/screens/posts/post_item.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/notification_handler.dart';
import 'package:glitcher/utils/Loader.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:glitcher/services/auth.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/caching_image.dart';
import 'package:glitcher/widgets/image_overlay.dart';

enum ScreenState { to_edit, to_follow, to_save, to_unfollow }

class ProfileScreen extends StatefulWidget {
  final String userId;

  ProfileScreen(this.userId);

  @override
  _ProfileScreenState createState() => _ProfileScreenState(userId);
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _coverImageUrl;
  var _profileImageUrl;
  var _coverImageFile;
  var _profileImageFile;
  double _coverHeight = 200;

  String _descText = 'Description here';
  String _nameText = 'Username';
  var _descEditingController = TextEditingController()
    ..text = 'Description here';
  var _textEditingController = TextEditingController()..text = '';

  String userId;

  var userData;

  int _followers = 0;

  int _following = 0;

  bool _loading = false;
  bool _isBtnEnabled = true;

  FirebaseUser currentUser;

  bool isFollowing = false;
  bool isFriend = false;

  List<Post> _posts = [];

  Timestamp lastVisiblePostSnapShot;

  ScrollController _scrollController = ScrollController();

  bool _postsReady = false;

  bool isEditingName = false;
  bool isEditingDesc = false;

  _ProfileScreenState(this.userId);

  @override
  void initState() {
    super.initState();

    ///Set up listener here
    _scrollController
      ..addListener(() {
        if (_scrollController.offset >=
                _scrollController.position.maxScrollExtent &&
            !_scrollController.position.outOfRange) {
          print('reached the bottom');
          nextPosts();
        } else if (_scrollController.offset <=
                _scrollController.position.minScrollExtent &&
            !_scrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });

    checkUser();
  }

  void checkUser() async {
    currentUser = await Auth().getCurrentUser();

    if (this.userId != currentUser.uid) {
      DocumentSnapshot followSnapshot = await firestore
          .collection('users')
          .document(currentUser.uid)
          .collection('following')
          .document(userId)
          .get();

      setState(() {
        isFollowing = followSnapshot.exists;
      });

      DocumentSnapshot friendSnapshot = await firestore
          .collection('users')
          .document(currentUser.uid)
          .collection('friends')
          .document(userId)
          .get();

      setState(() {
        isFriend = friendSnapshot.exists;
      });
    }

    if (userData == null) {
      loadUserData();
      loadPosts();
    }
  }

  void nextPosts() async {
    var posts;
    posts = await DatabaseService.getNextPosts(lastVisiblePostSnapShot);

    if (posts.length > 0) {
      setState(() {
        posts.forEach((element) => _posts.add(element));
        this.lastVisiblePostSnapShot = posts.last.timestamp;
      });
    }
  }

  void loadUserData() async {
    setState(() {
      _loading = true;
    });
    print('profileUserID = ${widget.userId}');
    await firestore.collection('users').document(userId).get().then((onValue) {
      setState(() {
        userData = onValue.data;
        _nameText = onValue.data['username'];
        _descText = onValue.data['description'];
        _profileImageUrl = onValue.data['profile_url'];
        _coverImageUrl = onValue.data['cover_url'];
        _followers = onValue.data['followers'];
        _following = onValue.data['following'];

        _profileImageFile = null;
        _coverImageFile = null;
        _loading = false;
      });
    });
  }

  save() async {
    setState(() {
      _loading = true;
      _isBtnEnabled = false;
      _descText = _descEditingController.text;
      _nameText = _textEditingController.text;
    });

    userData['name'] = _nameText;
    userData['description'] = _descText;

    usersRef.document(userId).updateData(userData);

    String url;

    if (_profileImageFile != null) {
      url = await AppUtil.uploadFile(
        _profileImageFile,
        context,
        'profile_img/$userId',
      );

      setState(() {
        _profileImageUrl = url;
      });

      usersRef.document(userId).updateData({'profile_url': _profileImageUrl});
    }
    if (_coverImageFile != null) {
      url = await AppUtil.uploadFile(
          _coverImageFile, context, 'cover_img/$userId');

      setState(() {
        _coverImageUrl = url;
      });

      usersRef.document(userId).updateData({'cover_url': _coverImageUrl});
    }

    setState(() {
      _profileImageFile = null;
      _coverImageFile = null;
      _loading = false;
      _isBtnEnabled = true;
    });
  }

  Stack _profileAndCover() {
    return Stack(
      alignment: Alignment(0, 0),
      children: <Widget>[
        Container(
          transform: Matrix4.translationValues(0.0, -50.0, 0.0),
          child: Hero(
            tag: _coverImageUrl != null
                ? _coverImageUrl
                : Strings.default_post_image,
            child: ClipShadowPath(
                clipper: CircularClipper(),
                shadow: Shadow(blurRadius: 20.0),
                child: GestureDetector(
                  onTap: () {
                    if (userId == Constants.currentUserID)
                      coverEdit();
                    else {
                      coverDownload();
                    }
                  },
                  child: CacheThisImage(
                    imageUrl: _coverImageUrl,
                    imageShape: BoxShape.rectangle,
                    width: double.infinity,
                    height: 400.0,
                    defaultAssetImage: Strings.default_profile_image,
                  ),
                )),
          ),
        ),
        Positioned.fill(
          bottom: 10.0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: RawMaterialButton(
                padding: EdgeInsets.all(1.0),
                elevation: 12.0,
                onPressed: () => () {},
                shape: CircleBorder(),
                fillColor: Colors.white,
                child: GestureDetector(
                  onTap: () {
                    if (userId == Constants.currentUserID)
                      profileEdit();
                    else {
                      profileDownload();
                    }
                  },
                  child: CacheThisImage(
                    imageUrl: _profileImageUrl,
                    imageShape: BoxShape.circle,
                    width: Sizes.lg_profile_image_w,
                    height: Sizes.lg_profile_image_h,
                    defaultAssetImage: Strings.default_profile_image,
                  ),
                )),
          ),
        ),
        userId != Constants.currentUserID
            ? Positioned(
                bottom: 0.0,
                left: 20.0,
                child: IconButton(
                  onPressed: isFollowing
                      ? () {
                          unfollowUser();
                        }
                      : () {
                          followUser();
                        },
                  icon: !isFollowing
                      ? Icon(FontAwesome.getIconData('user-plus'))
                      : Icon(FontAwesome.getIconData('user-times')),
                  iconSize: 25.0,
                  color: switchColor(MyColors.lightButtonsBackground,
                      MyColors.darkPrimaryTappedBtn),
                ),
              )
            : Container(),
        isFriend
            ? Positioned(
                bottom: 0.0,
                right: 25.0,
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/conversation',
                        arguments: {'otherUid': userId});
                  },
                  icon: Icon(Icons.chat),
                  iconSize: 25.0,
                  color: switchColor(MyColors.lightButtonsBackground,
                      MyColors.darkPrimaryTappedBtn),
                ),
              )
            : Container(),
      ],
    );
  }

  Widget _build() {
    return Stack(
      alignment: Alignment(0, 0),
      children: <Widget>[
        SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _profileAndCover(),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  !isEditingName
                      ? Text(
                          _nameText,
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        )
                      : Container(
                          width: 200,
                          child: TextField(
                            controller: _textEditingController,
                          )),
                  userId == Constants.currentUserID ? !isEditingName
                      ? IconButton(
                          icon: Icon(Icons.edit, size: 18,),
                          onPressed: () {
                            setState(() {
                              isEditingName = true;
                              _textEditingController.text = _nameText;
                            });
                          })
                      : IconButton(
                          icon: Icon(Icons.done, size: 18,),
                          onPressed: () {
                            setState(() {
                              isEditingName = false;
                              _nameText = _textEditingController.text;
                            });

                            updateName();
                          }) : Container(),
                ],
              ),
              SizedBox(
                height: 8,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  !isEditingDesc
                      ? Text(
                          _descText,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        )
                      : Container(
                          width: 200,
                          child: TextField(
                            controller: _textEditingController,
                          )),
                  userId == Constants.currentUserID ? !isEditingDesc
                      ? IconButton(
                          icon: Icon(Icons.edit, size: 18,),
                          onPressed: () {
                            setState(() {
                              isEditingDesc = true;
                              _textEditingController.text = _descText;
                            });
                          })
                      : IconButton(
                          icon: Icon(Icons.done, size: 18,),
                          onPressed: () {
                            setState(() {
                              isEditingDesc = false;
                              _descText = _textEditingController.text;
                            });
                            updateDesc();
                          }) : Container(),
                ],
              ),
              SizedBox(
                height: 8,
              ),
              SizedBox(
                height: 8,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Text(
                        'Followers',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(_followers.toString())
                    ],
                  ),
                  SizedBox(
                    width: 50,
                  ),
                  Column(
                    children: <Widget>[
                      Text(
                        'Following',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Text(_following.toString())
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: 8,
              ),
              Divider(
                color: switchColor(
                    MyColors.lightLineBreak, MyColors.darkLineBreak),
              ),
              _postsReady == true
                  ? ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      scrollDirection: Axis.vertical,
                      itemCount: _posts.length,
                      shrinkWrap: true,
                      itemBuilder: (BuildContext context, int index) {
                        Post post = _posts[index];
                        return FutureBuilder(
                            future:
                                DatabaseService.getUserWithId(post.authorId),
                            builder:
                                (BuildContext context, AsyncSnapshot snapshot) {
                              if (!snapshot.hasData) {
                                return SizedBox.shrink();
                              }
                              User author = snapshot.data;
                              return PostItem(post: post, author: author);
                            });
                      },
                    )
                  : Container(),
            ],
          ),
        ),
        Positioned(
          top: 0.0,
          left: 0.0,
          right: 0.0,
          child: AppBar(
            backgroundColor: Colors.transparent,
          ),
        ),
        _loading
            ? LoaderTwo()
            : Container(
                width: 0,
                height: 0,
              ),
      ],
    );
  }

  updateName() async {
    await usersRef.document(userId).updateData({'username': _nameText});
  }

  updateDesc() async {
    await usersRef.document(userId).updateData({'description': _descText});
  }

  loadPosts() async {
    List<Post> posts;
    posts = await DatabaseService.getUserPosts(userId);
    setState(() {
      _posts = posts;
      this.lastVisiblePostSnapShot = posts.last.timestamp;
      _postsReady = true;
    });
  }

  void followUser() async {
    setState(() {
      _isBtnEnabled = false;
      _loading = true;
    });

    FieldValue timestamp = FieldValue.serverTimestamp();

    await usersRef
        .document(userId)
        .collection('followers')
        .document(Constants.currentUserID)
        .setData({
      'timestamp': FieldValue.serverTimestamp(),
    });

    await usersRef.document(userId).updateData({
      'followers': FieldValue.increment(1),
    });

    await firestore
        .collection('users')
        .document(Constants.currentUserID)
        .updateData({
      'following': FieldValue.increment(1),
    });

    await usersRef
        .document(Constants.currentUserID)
        .collection('following')
        .document(userId)
        .setData({
      'timestamp': timestamp,
    });

    DocumentSnapshot doc = await usersRef
        .document(userId)
        .collection('following')
        .document(Constants.currentUserID)
        .get();

    if (doc.exists) {
      await usersRef
          .document(Constants.currentUserID)
          .collection('friends')
          .document(userId)
          .setData({'timestamp': FieldValue.serverTimestamp()});

      await usersRef
          .document(Constants.currentUserID)
          .updateData({'friends': FieldValue.increment(1)});

      await usersRef
          .document(userId)
          .collection('friends')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});

      await usersRef
          .document(userId)
          .updateData({'friends': FieldValue.increment(1)});

      NotificationHandler.sendNotification(
          userId,
          '${Constants.loggedInUser.username} followed you',
          'You are now friends',
          Constants.currentUserID,
          'follow');
    } else {
      NotificationHandler.sendNotification(
          userId,
          '${Constants.loggedInUser.username} followed you',
          'Follow him back to be friends',
          Constants.currentUserID,
          'follow');
    }

    setState(() {
      _loading = false;
      _isBtnEnabled = true;
      //AppUtil().showToast('You started following ' + _nameText);
      _followers++;
      isFollowing = true;
    });

    checkUser();
  }

  void unfollowUser() async {
    setState(() {
      _isBtnEnabled = false;
      _loading = true;
    });
    await usersRef
        .document(Constants.currentUserID)
        .collection('following')
        .document(userId)
        .delete();

    await usersRef.document(Constants.currentUserID).updateData({
      'following': FieldValue.increment(-1),
    });

    await usersRef
        .document(userId)
        .collection('followers')
        .document(Constants.currentUserID)
        .delete();

    await usersRef.document(userId).updateData({
      'followers': FieldValue.increment(-1),
    });

    DocumentSnapshot doc = await usersRef
        .document(Constants.currentUserID)
        .collection('friends')
        .document(userId)
        .get();

    if (doc.exists) {
      await usersRef
          .document(Constants.currentUserID)
          .collection('friends')
          .document(userId)
          .delete();

      await usersRef
          .document(Constants.currentUserID)
          .updateData({'friends': FieldValue.increment(-1)});
    }

    DocumentSnapshot doc2 = await usersRef
        .document(userId)
        .collection('friends')
        .document(Constants.currentUserID)
        .get();

    if (doc2.exists) {
      await usersRef
          .document(userId)
          .collection('friends')
          .document(Constants.currentUserID)
          .delete();

      await usersRef
          .document(userId)
          .updateData({'friends': FieldValue.increment(-1)});
    }

    setState(() {
      _followers--;
      _loading = false;
      _isBtnEnabled = true;
      isFollowing = false;
    });

    checkUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _build(),
    );
  }

  coverEdit() async {
    if (_coverImageUrl == null && _coverImageFile == null) {
      File image = await AppUtil.chooseImage();
      setState(() {
        _coverImageFile = image;
        _coverImageUrl = null;
      });

      String url = await AppUtil.uploadFile(
          _coverImageFile, context, 'cover_img/$userId');
      setState(() {
        _coverImageUrl = url;
        _coverImageFile = null;
      });
    }

    await showDialog(
        barrierDismissible: true,
        child: Container(
          width: Sizes.sm_profile_image_w,
          height: Sizes.sm_profile_image_h,
          child: ImageOverlay(
            imageUrl: _coverImageUrl,
            imageFile: _coverImageFile,
            btnText: 'Edit',
            btnFunction: () async {
              File image = await AppUtil.chooseImage();
              setState(() {
                _coverImageFile = image;
                _coverImageUrl = null;
              });

              String url =
              await AppUtil.uploadFile(_coverImageFile, context, 'cover_img/$userId');
              setState(() {
                _coverImageUrl = url;
                _coverImageFile = null;
              });

              await usersRef.document(userId).updateData({'cover_url': _coverImageUrl});

              Navigator.of(context).pop();
            },
          ),
        ),
        context: context);

  }

  profileEdit() async {
    if (_profileImageUrl == null && _profileImageFile == null) {
      File image = await AppUtil.chooseImage();
      setState(() {
        _profileImageFile = image;
        _profileImageUrl = null;
      });

      String url = await AppUtil.uploadFile(
          _profileImageFile, context, 'cover_img/$userId');
      setState(() {
        _profileImageUrl = url;
        _profileImageFile = null;
      });
    }

    showDialog(
        barrierDismissible: true,
        child: Container(
          width: Sizes.sm_profile_image_w,
          height: Sizes.sm_profile_image_h,
          child: ImageOverlay(
            imageUrl: _profileImageUrl,
            imageFile: _profileImageFile,
            btnText: 'Edit',
            btnFunction: () async {
              File image = await AppUtil.chooseImage();
              setState(() {
                _profileImageFile = image;
                _profileImageUrl = null;
              });

              String url = await AppUtil.uploadFile(
                  _profileImageFile, context, 'profile_img/$userId');
              setState(() {
                _profileImageUrl = url;
                _profileImageFile = null;
              });
              
              await usersRef.document(userId).updateData({'profile_url': _profileImageUrl});

              Navigator.of(context).pop();
            },
          ),
        ),
        context: context);
  }

  coverDownload() async {
    if (_coverImageUrl == null && _coverImageFile == null)
      return;
    else {
      showDialog(
          barrierDismissible: true,
          child: Container(
            width: Sizes.sm_profile_image_w,
            height: Sizes.sm_profile_image_h,
            child: ImageOverlay(
              imageUrl: _coverImageUrl,
              imageFile: _coverImageFile,
              btnText: 'Download',
              btnFunction: () async {
                //TODO implement download function

                Navigator.of(context).pop();
              },
            ),
          ),
          context: context);
    }
  }

  profileDownload() async {
    if (_profileImageUrl == null && _profileImageFile == null)
      return;
    else {
      showDialog(
          barrierDismissible: true,
          child: Container(
            width: Sizes.sm_profile_image_w,
            height: Sizes.sm_profile_image_h,
            child: ImageOverlay(
              imageUrl: _profileImageUrl,
              imageFile: _profileImageFile,
              btnText: 'Download',
              btnFunction: () async {
                //TODO implement download function

                Navigator.of(context).pop();
              },
            ),
          ),
          context: context);
    }
  }
}
