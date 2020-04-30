import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';


class ImageOverlay extends StatelessWidget {
  final String imageUrl;
  final File imageFile;
  final String btnText;
  final Function btnFunction;
  const ImageOverlay({Key key, this.imageUrl, this.imageFile, this.btnText, this.btnFunction}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return imageOverlay(
      context,
      PhotoView(
        imageProvider: imageUrl != null ? NetworkImage(imageUrl) : FileImage(imageFile),
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: PhotoViewComputedScale.contained * 2,
        enableRotation: true,
        loadingChild: Center(child: CircularProgressIndicator()),
        backgroundDecoration:
            BoxDecoration(color: Colors.transparent.withOpacity(.3)),
      ),
      this.btnText,
      this.btnFunction
    );
  }
}

Stack imageOverlay(BuildContext context, Widget child, String btnText, Function btnFunction) {
  return Stack(
    alignment: Alignment(0, .9),
    children: <Widget>[
      child,
      btnText != null ? OutlineButton(
          child: Text(
            btnText,
            style: TextStyle(color: Colors.blue),
          ),
          onPressed: () {            
            btnFunction();
          },
          borderSide: BorderSide(
            color: Colors.blue, //Color of the border
            style: BorderStyle.solid, //Style of the border
            width: 1.5, //width of the border
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0))): Container(),
    ],
  );
}
