import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glitcher/screens/home/home.dart';
import 'package:glitcher/screens/login_page.dart';

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
}
