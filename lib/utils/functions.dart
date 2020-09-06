import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/models/hashtag_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/constants.dart';

saveToken() async {
  String token = await FirebaseMessaging().getToken();
  usersRef
      .document(Constants.currentUserID)
      .collection('tokens')
      .document(token)
      .setData({'modifiedAt': FieldValue.serverTimestamp(), 'signed': true});
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

void setTheme(BuildContext context) async {
  if (Constants.currentTheme == AvailableThemes.LIGHT_THEME) {
    DynamicTheme.of(context).setThemeData(MyColors.darkTheme);
    Constants.currentTheme = AvailableThemes.DARK_THEME;
  } else {
    DynamicTheme.of(context).setThemeData(MyColors.lightTheme);
    Constants.currentTheme = AvailableThemes.LIGHT_THEME;
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String theme = Constants.currentTheme.toString();
  await prefs.setString('theme', theme);
}

Future getTheme() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getString('theme');
}

downloadImage(String url, String id) async {
  var response = await get(url);
  //var documentDirectory = await getApplicationSupportDirectory();
  //var firstPath = documentDirectory.path + "/Glitcher";
  //var filePathAndName = documentDirectory.path + '/Glitcher/$id.jpg';

  var firstPath = '/sdcard/download/';
  var filePathAndName = firstPath + '$id.jpg';
  //await Directory(firstPath).create(recursive: true);
  File file2 = new File(filePathAndName);
  file2.writeAsBytesSync(response.bodyBytes);

  //return File(filePathAndName);
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

Future<List> getFriends() async {
  List<User> friends =
      await DatabaseService.getFriends(Constants.currentUserID);
  return friends;
}

Future<List> getFollowing() async {
  List<User> following =
      await DatabaseService.getFollowing(Constants.currentUserID);
  return following;
}

Future<List> getFollowers() async {
  List<User> followers =
      await DatabaseService.getFollowers(Constants.currentUserID);
  return followers;
}

Future<List> getHashtags() async {
  print('currentUID = ${Constants.currentUserID}');
  List<Hashtag> hashtags = await DatabaseService.getHashtags();

  return hashtags;
}

Color switchColor(Color lightColor, Color darkColor) {
  //print('current theme: ${Constants.currentTheme}');
  return Constants.currentTheme == AvailableThemes.LIGHT_THEME
      ? lightColor
      : darkColor;
}

// Play audio
//void playSound(String fileName) {
//  SoundManager soundManager = new SoundManager();
//  soundManager.playLocal(fileName).then((onValue) {
//    //do something?
//  });
//}

// Pick Image
pickImage(ImageSource source) async {
  File selected = await ImagePicker.pickImage(source: source);
  return selected; // Assign it later to File imageFile variable usign setState((){});.
}

// Crop Image
cropImage(File imageFile) async {
  File cropped = await ImageCropper.cropImage(
      sourcePath: imageFile.path, compressQuality: 50);
  return cropped ??
      imageFile; // Assign it later to File imageFile variable usign setState((){});.
}

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
    {BuildContext context,
    Widget widget,
    String routeId,
    FirebaseUser currentUser}) {
  Navigator.of(context).push<String>(
    new MaterialPageRoute(
      settings: RouteSettings(name: '/$routeId'),
      builder: (context) => widget,
    ),
  );
}

class Functions {
  static FirebaseUser currentUser;
  static final _auth = FirebaseAuth.instance;

  static void getUserCountryInfo() async {
    String url = 'http://ip-api.com/json';
    var response = await http.get(url);
    String body = response.body;
    Constants.country = jsonDecode(body)['country'];
    print('Country: ${Constants.country}');
  }

  /* Alert Error - SnackBar */

  /// Format Time
  static String formatTimestamp(Timestamp timestamp) {
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
