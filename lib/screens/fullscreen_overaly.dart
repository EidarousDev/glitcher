import 'dart:io';

import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/utils/Loader.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenOverlay extends StatefulWidget {
  final String url;
  final int type;
  final int whichImage;
  final String userId;

  FullScreenOverlay({this.url, this.type, this.whichImage, this.userId});

  @override
  _FullscreenOverlayState createState() => _FullscreenOverlayState(
      url: url, type: type, whichImage: whichImage, userId: userId);
}

class _FullscreenOverlayState extends State<FullScreenOverlay> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent.withOpacity(.3),
      body: type == 1
          ? _editBtnOverlay(
              context,
              PhotoView(
                imageProvider: NetworkImage(url),
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.contained * 2,
                enableRotation: true,
                loadingChild: Center(child: CircularProgressIndicator()),
                backgroundDecoration:
                    BoxDecoration(color: Colors.transparent.withOpacity(.3)),
              ),
            )
          : type == 2
              ? _editBtnOverlay(
                  context,
                  Image.file(
                    File(url),
                    fit: BoxFit.scaleDown,
                    height: double.infinity,
                    width: double.infinity,
                    alignment: Alignment.center,
                  ),
                )
              : _editBtnOverlay(
                  context,
                  Image.asset(
                    url,
                    fit: BoxFit.scaleDown,
                    height: double.infinity,
                    width: double.infinity,
                    alignment: Alignment.center,
                  ),
                ),
    );
  }

  final String url;
  final int type;
  final int whichImage;
  final String userId;

  _FullscreenOverlayState({
    this.url,
    this.type,
    this.whichImage,
    this.userId,
  });

  Stack _editBtnOverlay(BuildContext context, Widget child) {
    return Stack(
      alignment: Alignment(0, .9),
      children: <Widget>[
        child,
        OutlineButton(
            child: Text(
              "Edit",
              style: TextStyle(color: Colors.blue),
            ),
            onPressed: () async{

              File image = await AppUtil.chooseImage();

              setState(() {
                _loading = true;
              });

              String url;
              if (whichImage == 1) {
                url = await AppUtil.uploadFile(image, context, 'cover_img/$userId');

                updateCoverImage(url);
              } else {
                url = await AppUtil.uploadFile(image, context, 'profile_img/$userId');

                updateProfileImage(url);
              }

              setState(() {
                image = null;
                _loading = false;
                Navigator.pop(context, url);
              });

            },
            borderSide: BorderSide(
              color: Colors.blue, //Color of the border
              style: BorderStyle.solid, //Style of the border
              width: 1.5, //width of the border
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0))),
        _loading
            ? Center(
                child: LoaderTwo(),
              )
            : Container(
                width: 0,
                height: 0,
              ),
      ],
    );
  }

  updateProfileImage(String url) async{
    await usersRef
        .document(userId)
        .updateData({'profile_url': url});
  }

  updateCoverImage(String url) async{
    await usersRef
        .document(userId)
        .updateData({'cover_url': url});
  }

}
