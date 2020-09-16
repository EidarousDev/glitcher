import 'dart:io';
import 'dart:math';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
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

  showToast(String msg) {
    FlutterToast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 1,
        textcolor: '#ffffff');
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
}
