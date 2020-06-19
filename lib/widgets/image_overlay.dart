import 'dart:io';

import 'package:flutter/material.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:photo_view/photo_view.dart';

class ImageOverlay extends StatelessWidget {
  final String imageUrl;
  final File imageFile;
  final String btnText;
  final Function btnFunction;
  const ImageOverlay(
      {Key key, this.imageUrl, this.imageFile, this.btnText, this.btnFunction})
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
        this.btnText,
        this.btnFunction);
  }
}

imageOverlay(
    BuildContext context, Widget child, String btnText, Function btnFunction) {
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
      actions: <Widget>[
        PopupMenuButton<String>(
          onSelected: handleClick,
          itemBuilder: (BuildContext context) {
            return {btnText ?? ''}.map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          },
        ),
      ],
    ),
    body: Stack(
      children: <Widget>[
        child,
      ],
    ),
  );
}

void handleClick(String value) {
  switch (value) {
    case (Strings.SAVE_IMAGE):
      break;
  }
}

Future<bool> _onBackPressed() {}
