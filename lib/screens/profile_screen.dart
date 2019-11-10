import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:glitcher/screens/fullscreen_overaly.dart';
import 'package:glitcher/utils/Loader.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ScreenState { to_edit, viewing, to_save }

class ProfileScreen extends StatefulWidget {
  FirebaseUser currentUser;
  ProfileScreen({this.currentUser});

  @override
  _ProfileScreenState createState() =>
      _ProfileScreenState(currentUser: currentUser);
}

class _ProfileScreenState extends State<ProfileScreen> {
  var _coverImageUrl;
  var _profileImageUrl;
  var _coverImageFile;
  var _profileImageFile;
  var _screenState = ScreenState.to_edit;
  double _coverHeight = 200;

  String _descText = 'Description here';
  String _nameText = 'Username';
  var _descEditingController = TextEditingController()
    ..text = 'Description here';
  var _nameEditingController = TextEditingController()..text = '';
  Firestore _firestore = Firestore.instance;

  FirebaseUser currentUser;

  var userData;

  int _followers = 0;

  int _following = 0;

  bool _loading = false;

  _ProfileScreenState({this.currentUser});

  Future chooseImage(int whichImage) async {
    await ImagePicker.pickImage(source: ImageSource.gallery).then((image) {
      setState(() {
        if (whichImage == 1) {
          _coverImageFile = image;
          if (_coverImageFile != null) _coverImageUrl = null;
        } else {
          _profileImageFile = image;
          if (_profileImageFile != null) _profileImageUrl = null;
        }
      });
    });
  }

  void loadUserData() async {
    setState(() {
      _loading = true;
    });
    await _firestore
        .collection('users')
        .document(currentUser.uid)
        .get()
        .then((onValue) {
      setState(() {
        userData = onValue.data;
        _nameText = onValue.data['name'];
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

  Future uploadFile(String parentFolder, var fileName) async {
    if (fileName == null) return;

    _loading = true;
    print((fileName));
    StorageReference storageReference = FirebaseStorage.instance
        .ref()
        .child('$parentFolder/${currentUser.uid}');
    StorageUploadTask uploadTask = storageReference.putFile(fileName);

    await uploadTask.onComplete;
    print('File Uploaded');
    storageReference.getDownloadURL().then((fileURL) {
      if (parentFolder == 'profile_img') {
        setState(() {
          _profileImageUrl = fileURL;
        });

        _firestore
            .collection('users')
            .document(currentUser.uid)
            .updateData({'profile_url': _profileImageUrl});
      } else if (parentFolder == 'cover_img') {
        setState(() {
          _coverImageUrl = fileURL;
        });

        _firestore
            .collection('users')
            .document(currentUser.uid)
            .updateData({'cover_url': _coverImageUrl});
      }
      setState(() {
        _profileImageFile = null;
        _coverImageFile = null;
        _loading = false;
      });

      //print(_uploadedFileURL);
    });
  }

  void edit() {
    setState(() {
      _screenState = ScreenState.to_save;
      _nameEditingController..text = _nameText;
      _descEditingController..text = _descText;
    });
  }

  Future save() async {

    setState(() {
      _screenState = ScreenState.to_edit;
      _descText = _descEditingController.text;
      _nameText = _nameEditingController.text;

      userData['name'] = _nameText;
      userData['description'] = _descText;

      _firestore
          .collection('users')
          .document(currentUser.uid)
          .updateData(userData);

      if (_profileImageFile != null) {
        uploadFile('profile_img', _profileImageFile);
      }
      if (_coverImageFile != null) {
        uploadFile('cover_img', _coverImageFile);
      }
    });
  }

  Widget profileOverlay(Widget child, double size) {
    if (_screenState == ScreenState.to_edit) {
      return child;
    }

    return Stack(
      alignment: Alignment(0, 0),
      children: <Widget>[
        child,
        Container(
          child: Icon(FontAwesome.getIconData('camera')),
          height: size,
          width: size,
          decoration: new BoxDecoration(
            color: const Color(0x000000).withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        )
      ],
    );
  }

  Widget coverOverlay(Widget child, double size) {
    if (_screenState == ScreenState.to_edit) {
      return child;
    }
    return Stack(
      alignment: Alignment.bottomRight,
      children: <Widget>[
        child,
        Container(
          margin: EdgeInsets.all(10),
          child: Icon(FontAwesome.getIconData('camera')),
          height: size,
          width: size,
          decoration: new BoxDecoration(
            color: const Color(0x000000).withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        )
      ],
    );
  }

  Stack _profileAndCover() {
    return Stack(
      alignment: Alignment(0, 0),
      children: <Widget>[
        GestureDetector(
          onTap: _screenState == ScreenState.to_save
              ? () {
                  chooseImage(1);
                }
              : () async {
                  if (_coverImageUrl != null) {
                    var result = await showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (_) => FullScreenOverlay(
                              url: _coverImageUrl,
                              type: 1,
                              whichImage: 1,
                              currentUser: currentUser,
                            ));
                    setState(() {
                      if (result != null) {
                        _coverImageUrl = result;
                      }
                    });
                  } else if (_coverImageFile != null) {
                    var result = await showDialog(
                        context: context,
                        builder: (_) => FullScreenOverlay(
                              url: _coverImageFile,
                              type: 2,
                              whichImage: 1,
                              currentUser: currentUser,
                            ));
                    setState(() {
                      if (result != null) {
                        _coverImageUrl = result;
                      }
                    });
                  } else {
                    var result = await showDialog(
                        context: context,
                        builder: (_) => FullScreenOverlay(
                              url: 'images/default_cover.jpg',
                              type: 3,
                              whichImage: 1,
                              currentUser: currentUser,
                            ));
                    setState(() {
                      if (result != null) {
                        _coverImageUrl = result;
                      }
                    });
                  }
                },
          child: _coverImageUrl == null
              ? _coverImageFile == null
                  ? Image.asset(
                      'images/default_cover.jpg',
                      fit: BoxFit.fill,
                      width: MediaQuery.of(context).size.width,
                      height: _coverHeight,
                    )
                  : Image.file(
                      _coverImageFile,
                      fit: BoxFit.fill,
                      width: MediaQuery.of(context).size.width,
                      height: _coverHeight,
                    )
              : Image.network(
                  _coverImageUrl,
                  fit: BoxFit.fill,
                  width: MediaQuery.of(context).size.width,
                  height: _coverHeight,
                ),
        ),
        GestureDetector(
            onTap: _screenState == ScreenState.to_save
                ? () {
                    chooseImage(2);
                  }
                : () async {
                    if (_profileImageUrl != null) {
                      var result = await showDialog(
                          context: context,
                          builder: (_) => FullScreenOverlay(
                                url: _profileImageUrl,
                                type: 1,
                                whichImage: 2,
                                currentUser: currentUser,
                              ));
                      setState(() {
                        if (result != null) {
                          _profileImageUrl = result;
                        }
                      });
                    } else if (_profileImageFile != null) {
                      var result = await showDialog(
                          context: context,
                          builder: (_) => FullScreenOverlay(
                                url: _profileImageFile,
                                type: 2,
                                whichImage: 2,
                                currentUser: currentUser,
                              ));
                      setState(() {
                        if (result != null) {
                          _profileImageUrl = result;
                        }
                      });
                    } else {
                      var result = await showDialog(
                          context: context,
                          builder: (_) => FullScreenOverlay(
                                url: 'images/default_profile.png',
                                type: 3,
                                whichImage: 2,
                                currentUser: currentUser,
                              ));

                      setState(() {
                        if (result != null) {
                          _profileImageUrl = result;
                        }
                      });
                    }
                  },
            child: _profileImageUrl == null
                ? _profileImageFile == null
                    ? profileOverlay(
                        CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              AssetImage('images/default_profile.png'),
                        ),
                        100)
                    : profileOverlay(
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: FileImage(_profileImageFile),
                        ),
                        100)
                : profileOverlay(
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(_profileImageUrl),
                    ),
                    100))
      ],
    );
  }

  Widget _build() {
    return SafeArea(
      child: Stack(
        alignment: Alignment(0, 0),
        children: <Widget>[
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _profileAndCover(),
                SizedBox(
                  height: 10,
                ),
                _screenState == ScreenState.to_edit
                    ? Text(
                        _nameText,
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      )
                    : Container(
                        height: 30,
                        width: 200,
                        child: TextField(
                          textAlign: TextAlign.center,
                          controller: _nameEditingController,
                          onChanged: (text) => {},
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                SizedBox(
                  height: 8,
                ),
                _screenState == ScreenState.to_edit
                    ? Text(
                        _descText,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      )
                    : Container(
                        height: 30,
                        width: 200,
                        child: TextField(
                          textAlign: TextAlign.center,
                          controller: _descEditingController,
                          onChanged: (text) => {},
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                SizedBox(
                  height: 8,
                ),
                Divider(
                  color: Colors.grey.shade400,
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
                )
              ],
            ),
          ),
          _loading
          ? LoaderTwo()
          : Container(
            width: 0,
            height: 0,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    if (userData == null) {
      loadUserData();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: _build(),
      floatingActionButton: FloatingActionButton(
        child: _screenState == ScreenState.to_edit
            ? Icon(MaterialIcons.getIconData('edit'))
            : _screenState == ScreenState.to_save
                ? Icon(MaterialIcons.getIconData('save'))
                : Icon(FontAwesome.getIconData('user-plus')),
        onPressed: _screenState == ScreenState.to_edit
            ? () {
                edit();
              }
            : () {
                save();
              },
      ),
    );
  }
}
