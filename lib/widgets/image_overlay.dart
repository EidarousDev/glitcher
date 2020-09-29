import 'dart:io';

import 'package:flutter/material.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:photo_view/photo_view.dart';

class ImageOverlay extends StatelessWidget {
  final String imageUrl;
  final File imageFile;
  final List<IconData> btnIcons;
  final List<Function> btnFunctions;
  const ImageOverlay(
      {Key key,
      this.imageUrl,
      this.imageFile,
      this.btnIcons,
      this.btnFunctions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return imageOverlay(
        context,
        PhotoView(
          imageProvider:
              imageUrl != null ? NetworkImage(imageUrl) : FileImage(imageFile),
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.contained * 2,
          enableRotation: true,
          loadingChild: Center(child: CircularProgressIndicator()),
          backgroundDecoration:
              BoxDecoration(color: Colors.transparent.withOpacity(.3)),
        ),
        this.btnIcons,
        this.btnFunctions);
  }
}

imageOverlay(BuildContext context, Widget child, List<IconData> btnIcons,
    List<Function> btnFunctions) {
  return Scaffold(
    appBar: AppBar(
        title: Text(""),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
        actions: btnList(btnIcons, btnFunctions)),
    body: Stack(
      children: <Widget>[
        child,
      ],
    ),
  );
}

void handleClick(String value) {}

List<Widget> btnList(List<IconData> btnIcons, List<Function> btnFunctions) {
  List<Widget> btnList = [];
  for (int i = 0; i < btnIcons.length; i++) {
    btnList.add(IconButton(
      icon: Icon(
        btnIcons[i],
        color: Colors.white,
      ),
      onPressed: btnFunctions[i],
    ));
  }

  return btnList;
}

Future<bool> _onBackPressed() {}
