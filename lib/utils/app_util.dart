import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/widgets/fluttertoast.dart';

import 'package:image_picker/image_picker.dart';

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

  void showToast(String msg) {
    FlutterToast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 1,
        textcolor: '#ffffff');
  }

  static Future chooseImage() async {
    File image = await ImagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100);
    return image;

  }

 static chooseVideo() async {
    await ImagePicker.pickVideo(source: ImageSource.gallery);
  }

  static Future uploadFile(File file, BuildContext context, String path) async {
    if (file == null) return;

    StorageReference storageReference = FirebaseStorage.instance
        .ref()
        .child(path);

    StorageUploadTask uploadTask = storageReference.putFile(file);

    await uploadTask.onComplete;
    print('File Uploaded');
    String url = await storageReference.getDownloadURL();

    return url;
  }
}
