import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
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
  String _nameText = 'Ahmed Nabil';
  var _descEditingController = TextEditingController()
    ..text = 'Description here';
  var _nameEditingController = TextEditingController()..text = 'Ahmed Nabil';
  Firestore _firestore = Firestore.instance;

  FirebaseUser currentUser;

  var userData;
  _ProfileScreenState({this.currentUser});

  Future chooseImage(int whichImage) async {
    await ImagePicker.pickImage(source: ImageSource.gallery).then((image) {
      setState(() {
        if (whichImage == 1) {
          setState(() {
            _coverImageFile = image;
            _coverImageUrl = null;
          });
        } else {
          setState(() {
            _profileImageFile = image;
            _profileImageUrl = null;
          });
        }

        //print(_profileImage.toString());
      });
    });
  }

  void loadUserData() async {
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

        _profileImageFile = null;
        _coverImageFile = null;
      });
    });
  }

  Future uploadFile(String parentFolder, var fileName) async {
    if (fileName == null) return;

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
      _profileImageFile = null;
      _coverImageFile = null;
      //print(_uploadedFileURL);
    });
  }

  void edit() {
    setState(() {
      _screenState = ScreenState.to_save;
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
        _coverImageUrl == null
            ? _coverImageFile == null
                ? Container(
                    width: MediaQuery.of(context).size.width,
                    height: _coverHeight,
                    child: GestureDetector(
                      onTap: _screenState == ScreenState.to_save
                          ? () {
                              chooseImage(1);
                            }
                          : () {},
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: Image(
                          width: MediaQuery.of(context).size.width,
                          image: AssetImage('images/default_cover.jpg'),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: MediaQuery.of(context).size.width,
                    height: _coverHeight,
                    child: GestureDetector(
                      onTap: _screenState == ScreenState.to_save
                          ? () {
                              chooseImage(1);
                            }
                          : () {},
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: Image(
                          width: MediaQuery.of(context).size.width,
                          image: FileImage(_coverImageFile),
                        ),
                      ),
                    ),
                  )
            : Container(
                width: MediaQuery.of(context).size.width,
                height: _coverHeight,
                child: GestureDetector(
                  onTap: _screenState == ScreenState.to_save
                      ? () {
                          chooseImage(1);
                        }
                      : () {},
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: Image(
                      width: MediaQuery.of(context).size.width,
                      image: NetworkImage(_coverImageUrl),
                    ),
                  ),
                ),
              ),
        GestureDetector(
            onTap: _screenState == ScreenState.to_save
                ? () {
                    chooseImage(2);
                  }
                : () {},
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
    if (userData == null) {
      loadUserData();
    }
    return SafeArea(
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
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                )
              : Container(
                  height: 30,
                  width: 200,
                  child: TextField(
                    textAlign: TextAlign.center,
                    controller: _nameEditingController,
                    onChanged: (text) => {},
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
        ],
      ),
    );
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
