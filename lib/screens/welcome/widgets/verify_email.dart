import 'package:flutter/material.dart';

Future<void> showVerifyEmailSentDialog(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      // return object of type Dialog
      return AlertDialog(
        title: new Text("Verify your account"),
        content: new Text("Link to verify account has been sent to your email"),
        actions: <Widget>[
          new FlatButton(
            child: new Text("Dismiss"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
