import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glitcher/screens/home/home.dart';
import 'package:glitcher/screens/login_page.dart';

class Functions {
  static void moveUserTo(
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
