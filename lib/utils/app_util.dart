import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/models/hashtag_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/notification_handler.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUtil {
  static final AppUtil _instance = new AppUtil.internal();
  static bool networkStatus;

  AppUtil.internal();

  factory AppUtil() {
    return _instance;
  }

  static englishOnly(String input) {
    String pattern = r'^(?:[a-zA-Z]|\P{L})+$';
    RegExp regex = RegExp(pattern, unicode: true);
    print(regex.hasMatch(input));
    return regex.hasMatch(input);
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

  static randomIndices(List list, {int requiredRandoms = 10}) {
    Random r = Random();
    List randoms = List();

    for (int i = 0; i < requiredRandoms; i++) {
      int random = r.nextInt(list.length);

      while (randoms.contains(random)) {
        random = r.nextInt(list.length);
      }
      randoms.add(list[random]);
    }

    return randoms;
  }

  static showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: MyColors.darkPrimary,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  static void showSnackBar(BuildContext context,
      GlobalKey<ScaffoldState> _scaffoldKey, String value) {
    FocusScope.of(context).requestFocus(new FocusNode());
    _scaffoldKey.currentState?.removeCurrentSnackBar();
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            fontFamily: "WorkSansSemiBold"),
      ),
      backgroundColor: MyColors.darkPrimary,
      duration: Duration(seconds: 3),
    ));
  }

  static void showFixedSnackBar(BuildContext context,
      GlobalKey<ScaffoldState> _scaffoldKey, String value) {
    FocusScope.of(context).requestFocus(new FocusNode());
    _scaffoldKey.currentState?.removeCurrentSnackBar();
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            fontFamily: "WorkSansSemiBold"),
      ),
      backgroundColor: MyColors.darkPrimary,
      duration: Duration(hours: 1),
    ));
  }

  static Future chooseImage({ImageSource source = ImageSource.gallery}) async {
    File image = await ImagePicker.pickImage(source: source, imageQuality: 80);
    print('File size: ${image.lengthSync()}');
    print('path: ${image.path}');
    return image;
  }

  static chooseVideo() async {
    await ImagePicker.pickVideo(source: ImageSource.gallery);
  }

  static Future uploadFile(File file, BuildContext context, String path,
      {List<String> groupMembersIds}) async {
    if (file == null) return;

    StorageReference storageReference =
        FirebaseStorage.instance.ref().child(path);
    print('storage path: $path');
    StorageUploadTask uploadTask;

    if (path.contains('group')) {
      Map<String, String> members = {};
      for (String id in groupMembersIds) {
        print('Member: $id');
        members.putIfAbsent(id, () => id);
      }
      uploadTask = storageReference.putFile(
        file,
        StorageMetadata(
          contentLanguage: 'en',
          customMetadata: members,
        ),
      );
    } else {
      uploadTask = storageReference.putFile(file);
    }

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

  static sendSupportEmail(String subject) async {
    final Email email = Email(
      body:
          '\n\n\n\nPlease don\'t remove this line (${Constants.currentUserID})',
      subject: subject,
      recipients: ['support@gl1tch3r.com'],
      isHTML: false,
    );

    await FlutterEmailSender.send(email);
  }

  static checkIfContainsMention(String text, String postId) async {
    text.split(' ').forEach((word) async {
      if (word.startsWith('@')) {
        User user =
            await DatabaseService.getUserWithUsername(word.substring(1));

        await NotificationHandler.sendNotification(
            user.id,
            'New mention',
            Constants.currentUser.username + ' mentioned you',
            postId,
            'mention');
      }
    });
  }

  static Future checkIfContainsHashtag(
      String text, String postId, bool newHashtag) async {
    text.split(' ').forEach((word) async {
      if (word.startsWith('#')) {
        Hashtag hashtag = await DatabaseService.getHashtagWithText(word);

        if (newHashtag) {
          String hashtagId = randomAlphaNumeric(20);
          await hashtagsRef.document(hashtagId).setData(
              {'text': word, 'timestamp': FieldValue.serverTimestamp()});

          await hashtagsRef
              .document(hashtagId)
              .collection('posts')
              .document(postId)
              .setData({'timestamp': FieldValue.serverTimestamp()});
        } else {
          await hashtagsRef
              .document(hashtag.id)
              .collection('posts')
              .document(postId)
              .setData({'timestamp': FieldValue.serverTimestamp()});
        }

        return hashtag;
      } else
        return null;
    });
  }

  static void alertDialog(
      BuildContext context, String heading, String message, String okBtn) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(heading),
            content: Text(message),
            actions: <Widget>[
              MaterialButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(okBtn),
              )
            ],
          );
        });
  }

  static downloadFromFirebaseStorage(String url, String name) async {
    var response = await get(url);
    var firstPath = '/sdcard/download/';
    var contentDisposition = response.headers['content-disposition'];
    String fileName = contentDisposition
        .split('filename*=utf-8')
        .last
        .replaceAll(RegExp('%20'), ' ')
        .replaceAll(RegExp('%2C|\''), '');
    var filePathAndName = firstPath + fileName;
    File file2 = new File(filePathAndName);
    file2.writeAsBytesSync(response.bodyBytes);
  }
}
