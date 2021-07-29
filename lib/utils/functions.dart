import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/models/hashtag_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
//import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/constants.dart';

saveToken() async {
  if (Constants.currentUserID == null) return;
  var token;
  if (Platform.isIOS || Platform.isMacOS) {
    token = await FirebaseMessaging.instance.getAPNSToken();
  } else {
    print(await FirebaseMessaging.instance.getToken());
    token = await FirebaseMessaging.instance.getToken();
  }
  await usersRef
      .doc(Constants.currentUserID)
      .collection('tokens')
      .doc(token)
      .set({'modifiedAt': FieldValue.serverTimestamp(), 'signed': true});
}

List<String> searchList(String text) {
  List<String> list = [];
  for (int i = 1; i <= text.length; i++) {
    list.add(text.substring(0, i).toLowerCase());
  }
  return list;
}

String validateUsername(String value) {
  String _errorMsgUsername = '';
  String pattern =
      r'^(?=.{4,20}$)(?![_.])(?!.*[_.]{2})[a-zA-Z0-9._]+(?<![_.])$';
  RegExp regExp = new RegExp(pattern);
  if (value.length == 0) {
    //AppUtil().showToast("Username is Required");
    _errorMsgUsername = "Username is Required";
  } else if (!regExp.hasMatch(value)) {
    //AppUtil().showToast("Invalid Username");
    _errorMsgUsername = "Invalid Username";
  } else {
    _errorMsgUsername = null;
  }
  print('errorMsgUsername = $_errorMsgUsername');
  return _errorMsgUsername;
}

downloadImage(String url, String name) async {
  var response = await get(Uri.parse(url));
  var firstPath = '/sdcard/download/';
  var filePathAndName = firstPath + '$name.jpg';
  File file2 = new File(filePathAndName);
  file2.writeAsBytesSync(response.bodyBytes);
}

void setFavouriteFilter(BuildContext context, int favouriteFilter) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  Constants.favouriteFilter = favouriteFilter;
  await prefs.setInt('favouriteFilter', favouriteFilter);
}

Future getFavouriteFilter() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getInt('favouriteFilter') ?? 0;
}

Future<List> getHashtags() async {
  print('currentUID = ${Constants.currentUserID}');
  List<Hashtag> hashtags = await DatabaseService.getHashtags();

  return hashtags;
}

// Pick Image
pickImage(ImageSource source) async {
  PickedFile selected = await ImagePicker.platform.pickImage(source: source);
  return File(selected
      .path); // Assign it later to File imageFile variable usign setState((){});.
}

Color switchColor(Color lightColor, Color darkColor) {
  //print('current theme: ${Constants.currentTheme}');
  return Constants.isDarkTheme ? darkColor : lightColor;
}

// Crop Image
// cropImage(File imageFile) async {
//   File cropped = await ImageCropper.cropImage(
//       sourcePath: imageFile.path, compressQuality: 50);
//   return cropped ??
//       imageFile; // Assign it later to File imageFile variable usign setState((){});.
// }

/// push Home Screen and kill the current screen
void pushHomeScreen(BuildContext context) {
  Navigator.of(context).pushReplacementNamed('/home');
}

void twoButtonsDialog(BuildContext context, confirmFunction,
    {bool isBarrierDismissible = true,
    String headerText = "Confirm",
    String bodyText = "Are you sure you want to do this?",
    String cancelBtn = "CANCEL",
    String yestBtn = "YES"}) {
  showDialog(
    context: context,
    barrierDismissible: isBarrierDismissible,
    builder: (BuildContext context) {
      // return object of type Dialog
      return AlertDialog(
        title: new Text(headerText),
        content: new Text(bodyText),
        actions: <Widget>[
          new FlatButton(
            child: new Text(cancelBtn),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          new FlatButton(
            child: new Text(yestBtn),
            onPressed: () async {
              confirmFunction();
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

void moveUserTo(
    {BuildContext context, Widget widget, String routeId, User currentUser}) {
  Navigator.of(context).push<String>(
    new MaterialPageRoute(
      settings: RouteSettings(name: '/$routeId'),
      builder: (context) => widget,
    ),
  );
}

class Functions {
  static User currentUser;
  static final _auth = FirebaseAuth.instance;

  static void getUserCountryInfo() async {
    String url = 'http://ip-api.com/json';
    var response = await http.get(Uri.parse(url));
    String body = response.body;
    Constants.country = jsonDecode(body)['country'];
    DatabaseService.updateUserCountry();
    print('Country: ${Constants.country}');
  }

  /* Alert Error - SnackBar */

  /// Format Time
  static String formatTimestamp(Timestamp timestamp) {
    if (timestamp == null) return '';

    var now = Timestamp.now().toDate();
    var date = new DateTime.fromMillisecondsSinceEpoch(
        timestamp.millisecondsSinceEpoch);
    var diff = now.difference(date);
    var time = '';

    if (diff.inSeconds <= 60) {
      time = 'now';
    } else if (diff.inMinutes > 0 && diff.inMinutes < 60) {
      if (diff.inMinutes == 1) {
        time = 'A minute ago';
      } else {
        time = diff.inMinutes.toString() + ' minutes ago';
      }
    } else if (diff.inHours > 0 && diff.inHours < 24) {
      if (diff.inHours == 1) {
        time = 'An hour ago';
      } else {
        time = diff.inHours.toString() + ' hours ago';
      }
    } else if (diff.inDays > 0 && diff.inDays < 7) {
      if (diff.inDays == 1) {
        time = 'Yesterday';
      } else {
        time = diff.inDays.toString() + ' DAYS AGO';
      }
    } else {
      if (diff.inDays == 7) {
        time = 'A WEEK AGO';
      } else {
        /// Show in Format => 21-05-2019 10:59 AM
        final df = new DateFormat('dd-MM-yyyy hh:mm a');
        time = df.format(date);
      }
    }

    return time;
  }

  /// Format Time For Comments
  static String formatCommentsTimestamp(Timestamp timestamp) {
    var now = Timestamp.now().toDate();
    var date = new DateTime.fromMillisecondsSinceEpoch(
        timestamp.millisecondsSinceEpoch);
    var diff = now.difference(date);
    var time = '';

    if (diff.inSeconds <= 60) {
      time = 'now';
    } else if (diff.inMinutes > 0 && diff.inMinutes < 60) {
      if (diff.inMinutes == 1) {
        time = '1m';
      } else {
        time = diff.inMinutes.toString() + 'm';
      }
    } else if (diff.inHours > 0 && diff.inHours < 24) {
      if (diff.inHours == 1) {
        time = '1h';
      } else {
        time = diff.inHours.toString() + 'h';
      }
    } else if (diff.inDays > 0) {
      if (diff.inDays == 1) {
        time = '1d';
      } else {
        time = diff.inDays.toString() + 'd';
      }
    }

    return time;
  }
}
