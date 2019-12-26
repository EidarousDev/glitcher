import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/utils/Loader.dart';
import 'package:image_picker/image_picker.dart';

class FullScreenOverlay extends StatefulWidget {

  final String url;
  final int type;
  final int whichImage;
  final String userId;

  FullScreenOverlay({this.url, this.type, this.whichImage, this.userId});

  @override
  _FullscreenOverlayState createState() =>
      _FullscreenOverlayState(url: url, type: type, whichImage: whichImage, userId: userId);
}

class _FullscreenOverlayState extends State<FullScreenOverlay> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent.withOpacity(.3),
      body: type == 1
          ? _editBtnOverlay(
        context,
        Image.network(
          url,
          fit: BoxFit.scaleDown,
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
        ),
      )
          : type == 2
          ? _editBtnOverlay(
        context,
        Image.file(
          File(url),
          fit: BoxFit.scaleDown,
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
        ),
      )
          : _editBtnOverlay(
        context,
        Image.asset(
          url,
          fit: BoxFit.scaleDown,
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
        ),
      ),
    );
  }

  final String url;
  final int type;
  final int whichImage;
  final String userId;
  final Firestore _firestore = Firestore.instance;
  File _file;

  var _url;

  _FullscreenOverlayState({
    this.url,
    this.type,
    this.whichImage,
    this.userId,
  });

  Stack _editBtnOverlay(BuildContext context, Widget child) {
    return Stack(
      alignment: Alignment(0, .9),
      children: <Widget>[
        child,
        OutlineButton(
            child: Text(
              "Edit",
              style: TextStyle(color: Colors.blue),
            ),
            onPressed: () {
              chooseImage(whichImage, context);
            },
            borderSide: BorderSide(
              color: Colors.blue, //Color of the border
              style: BorderStyle.solid, //Style of the border
              width: 1.5, //width of the border
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0))),
        _loading
        ? Center(child:  LoaderTwo(),)
        : Container(
          width: 0,
          height: 0,
        ),
      ],
    );
  }

  Future chooseImage(int whichImage, BuildContext context) async {
    await ImagePicker.pickImage(source: ImageSource.gallery).then((image) {
      if (whichImage == 1) {
        _file = image;
        uploadFile('cover_img', _file, context);
      } else {
        _file = image;
        uploadFile('profile_img', _file, context);
      }
    });
  }

  Future uploadFile(String parentFolder, var file, BuildContext context) async {
    if (file == null) return;
    setState(() {
      _loading = true;
    });
    print((file));
    StorageReference storageReference = FirebaseStorage.instance
        .ref()
        .child('$parentFolder/$userId');
    StorageUploadTask uploadTask = storageReference.putFile(file);

    await uploadTask.onComplete;
    print('File Uploaded');
    storageReference.getDownloadURL().then((fileURL) {
      if (parentFolder == 'profile_img') {
        setState(() {
          _url = fileURL;
        });

        _firestore
            .collection('users')
            .document(userId)
            .updateData({'profile_url': _url}).then((onValue){
          setState(() {
            _file = null;
            _loading = false;
            Navigator.pop(context, _url);
          });

        });
      } else if (parentFolder == 'cover_img') {
        setState(() {
          _url = fileURL;
        });

        _firestore
            .collection('users')
            .document(userId)
            .updateData({'cover_url': _url}).then((onValue){
          setState(() {
            _file = null;
            _loading = false;
            Navigator.pop(context, _url);
          });

        });
      }
      //print(_uploadedFileURL);
    });
  }
}
