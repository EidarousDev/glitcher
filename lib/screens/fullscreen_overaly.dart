import 'dart:io';

import 'package:flutter/material.dart';

class FullScreenOverlay extends StatelessWidget {
  final String url;
  final int type;

  FullScreenOverlay({this.url, this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent.withOpacity(.3),
      body: type == 1
          ? Image.network(
              url,
              fit: BoxFit.scaleDown,
              height: double.infinity,
              width: double.infinity,
              alignment: Alignment.center,
            )
          : type == 2
              ? Image.file(
                  File(url),
                  fit: BoxFit.scaleDown,
                  height: double.infinity,
                  width: double.infinity,
                  alignment: Alignment.center,
                )
              : Image.asset(
                  url,
                  fit: BoxFit.scaleDown,
                  height: double.infinity,
                  width: double.infinity,
                  alignment: Alignment.center,
                ),
    );
  }
}
