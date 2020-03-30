import 'package:flutter/material.dart';

class MyDialog extends StatefulWidget {
  final DialogType dialogType;
  //final BuildContext context;
  final Function confirmFunction;
  final bool isBarrierDismissible;
  final String headerText;
  final String bodyText;
  final String cancelBtn;
  final String yestBtn;

  const MyDialog(
      {Key key,
      this.dialogType,
      this.confirmFunction,
      this.isBarrierDismissible,
      this.headerText,
      this.bodyText,
      this.cancelBtn,
      this.yestBtn})
      : super(key: key);

  @override
  _MyDialogState createState() => _MyDialogState();
}

enum DialogType { ONE_BUTTON, TWO_BUTTONS }

class _MyDialogState extends State<MyDialog> {
  @override
  Widget build(BuildContext context) {
    return widget.dialogType == DialogType.ONE_BUTTON
        ? Container()
        : twoButtonsDialog(
            widget.confirmFunction,
            isBarrierDismissible: widget.isBarrierDismissible,
            headerText: widget.headerText,
            bodyText: widget.bodyText,
            cancelBtn: widget.cancelBtn,
            yestBtn: widget.yestBtn,
          );
  }

  Future<Widget> twoButtonsDialog(confirmFunction,
      {bool isBarrierDismissible = true,
      String headerText = "Confirm",
      String bodyText = "Are you sure you want to do this?",
      String cancelBtn = "CANCEL",
      String yestBtn = "YES"}) {
    return showDialog(
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
}
