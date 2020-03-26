import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extended_image/extended_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/utils/Loader.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'dart:math' show Random;
import 'dart:ui' as ui;

class ImageMessageOverlay extends StatefulWidget {

  final String uri;
  final String otherUid;

  ImageMessageOverlay({this.uri, this.otherUid});

  @override
  _ImageMessageState createState() =>
      _ImageMessageState(uri: uri, otherUid: otherUid);
}

class _ImageMessageState extends State<ImageMessageOverlay> {
  bool _loading = false;

//  final GlobalKey<ExtendedImageEditorState> editorKey = GlobalKey<ExtendedImageEditorState>();
//  AspectRatio _aspectRatio = AspectRatio(aspectRatio: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent.withOpacity(.3),
      body:  _editBtnOverlay(
        context,
        Image.file(
          File(uri),
          fit: BoxFit.scaleDown,
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
        ),

//          ExtendedImage.file(
//            File(uri),
//            fit: BoxFit.contain,
//            mode: ExtendedImageMode.editor,
//            extendedImageEditorKey: editorKey,
//            initEditorConfigHandler: (state) {
//              return EditorConfig(
//                  maxScale: 8.0,
//                  cropRectPadding: EdgeInsets.all(20.0),
//                  hitTestSize: 20.0,
//                  cropAspectRatio: _aspectRatio.aspectRatio);
//            },
//          )
      ),
    );
  }

  final String uri;
  final String otherUid;
  final Firestore _firestore = Firestore.instance;

  var _url;

  _ImageMessageState({
    this.uri,
    this.otherUid,
  });

  Stack _editBtnOverlay(BuildContext context, Widget child) {
    return Stack(
      alignment: Alignment(0, .9),
      children: <Widget>[
        child,
        OutlineButton(
            child: Text(
              "Send",
              style: TextStyle(color: Colors.blue),
            ),
            onPressed: () async{
              await uploadFile(File(uri), context);
              await sendMessage();
              setState(() {
                _loading = false;
              });
              Navigator.of(context).pushNamed('conversation', arguments: {'otherUid': otherUid});
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

  Future uploadFile(File file, BuildContext context) async {
    if (file == null) return;
    setState(() {
      _loading = true;
    });

//    ByteData byteData = await editorKey.currentState.image.toByteData(format: ui.ImageByteFormat.rawUnmodified);
//    File croppedFile = File(file.path);
//    croppedFile = await croppedFile.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    print((file));


    StorageReference storageReference = FirebaseStorage.instance
        .ref()
        .child('image_messages/').child(randomAlphaNumeric(20));
    StorageUploadTask uploadTask = storageReference.putFile(file);

    await uploadTask.onComplete;
    print('File Uploaded');
    _url = await storageReference.getDownloadURL();
  }

  sendMessage() async {

    await _firestore
        .collection('chats')
        .document(Constants.currentUserID)
        .collection('conversations')
        .document(otherUid)
        .collection('messages')
        .add({
      'sender': Constants.currentUserID,
      'image': _url,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'image'
    });

    await _firestore
        .collection('chats')
        .document(otherUid)
        .collection('conversations')
        .document(Constants.currentUserID)
        .collection('messages')
        .add({
      'sender': Constants.currentUserID,
      'image': _url,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'image'
    });
  }
}
