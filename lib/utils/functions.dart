import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glitcher/screens/home/home.dart';
import 'package:glitcher/screens/login_page.dart';
import 'package:glitcher/utils/sound_manager.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

import 'constants.dart';

void changeTheme(BuildContext context) {
  if (currentTheme == AvailableThemes.LIGHT_THEME) {
    DynamicTheme.of(context).setThemeData(Constants.darkTheme);
    currentTheme = AvailableThemes.DARK_THEME;
  } else {
    DynamicTheme.of(context).setThemeData(Constants.lightTheme);
    currentTheme = AvailableThemes.LIGHT_THEME;
  }
}

// Play audio
void playSound(String fileName) {
  SoundManager soundManager = new SoundManager();
  soundManager.playLocal(fileName).then((onValue) {
    //do something?
  });
}

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

  static void getCurrentUser() async {
    try {
      currentUser = await _auth.currentUser();
      if (currentUser != null) {
        //Navigator.pushNamed(context, HomePage.id);
        print("User logged: " + currentUser.email);
      } else {
        moveUserTo(widget: LoginPage(), routeId: HomePage.id);
      }
    } catch (e) {
      print(e);
    }
  }

  /* Alert Error - SnackBar */
  static void showInSnackBar(BuildContext context,
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
      backgroundColor: Colors.blue,
      duration: Duration(seconds: 3),
    ));
  }

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
        time = timestamp.toDate().toString();
      }
    }

    return time;
  }
}
