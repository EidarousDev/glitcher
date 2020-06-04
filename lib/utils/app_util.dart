import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/widgets/fluttertoast.dart';

import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUtil {
  static final AppUtil _instance = new AppUtil.internal();
  static bool networkStatus;

  AppUtil.internal();

  factory AppUtil() {
    return _instance;
  }

  bool isNetworkWorking() {
    return networkStatus;
  }

  static launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  showToast(String msg) {
    FlutterToast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 1,
        textcolor: '#ffffff');
  }

  static Future chooseImage() async {
    File image = await ImagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    return image;
  }

  static chooseVideo() async {
    await ImagePicker.pickVideo(source: ImageSource.gallery);
  }

  static Future uploadFile(File file, BuildContext context, String path) async {
    if (file == null) return;

    StorageReference storageReference =
        FirebaseStorage.instance.ref().child(path);

    StorageUploadTask uploadTask = storageReference.putFile(file);

    await uploadTask.onComplete;
    print('File Uploaded');
    String url = await storageReference.getDownloadURL();

    return url;
  }

  void customSnackBar(GlobalKey<ScaffoldState> _scaffoldKey, String msg,
      {double height = 30, Color backgroundColor = Colors.black}) {
    if (_scaffoldKey == null || _scaffoldKey.currentState == null) {
      return;
    }
    _scaffoldKey.currentState.hideCurrentSnackBar();
    final snackBar = SnackBar(
      backgroundColor: backgroundColor,
      content: Text(
        msg,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  String getSocialLinks(String url) {
    if (url != null && url.isNotEmpty) {
      url = url.contains("https://www") || url.contains("http://www")
          ? url
          : url.contains("www") &&
                  (!url.contains('https') && !url.contains('http'))
              ? 'https://' + url
              : 'https://www.' + url;
    } else {
      return null;
    }
    print('Launching URL : $url');
    return url;
  }
}
