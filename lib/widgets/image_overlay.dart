import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageOverlay extends StatelessWidget {
  final String imageUrl;
  const ImageOverlay({Key key, this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return imageOverlay(
      context,
      PhotoView(
        imageProvider: NetworkImage(imageUrl),
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: PhotoViewComputedScale.contained * 2,
        enableRotation: true,
        loadingChild: Center(child: CircularProgressIndicator()),
        backgroundDecoration:
            BoxDecoration(color: Colors.transparent.withOpacity(.3)),
      ),
    );
  }
}

Stack imageOverlay(BuildContext context, Widget child) {
  return Stack(
    alignment: Alignment(0, .9),
    children: <Widget>[
      child,
      OutlineButton(
          child: Text(
            "Download Image",
            style: TextStyle(color: Colors.blue),
          ),
          onPressed: () {
            //Download Image
          },
          borderSide: BorderSide(
            color: Colors.blue, //Color of the border
            style: BorderStyle.solid, //Style of the border
            width: 1.5, //width of the border
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0))),
    ],
  );
}
