import 'dart:io';

import 'package:flutter/material.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:chewie/chewie.dart';

class CreatePostVideo extends StatefulWidget {
  final File video;
  final Function onCrossIconPressed;
  final Chewie playerWidget; //Video player

  const CreatePostVideo(
      {Key key, this.video, this.playerWidget, this.onCrossIconPressed})
      : super(key: key);

  @override
  _CreatePostVideoState createState() =>
      _CreatePostVideoState(video, onCrossIconPressed);
}

class _CreatePostVideoState extends State<CreatePostVideo> {
  final File video;
  final Function onCrossIconPressed;

  _CreatePostVideoState(this.video, this.onCrossIconPressed);

  setVideoFile() {}

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: video == null
          ? Container()
          : Stack(
              children: <Widget>[
                Container(
                  alignment: Alignment.topRight,
                  child: Container(
                      height: 220,
                      width: Sizes.fullWidth(context) * .8,
                      child: widget.playerWidget),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: EdgeInsets.all(0),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.black54),
                    child: IconButton(
                      padding: EdgeInsets.all(0),
                      iconSize: 20,
                      onPressed: onCrossIconPressed,
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                )
              ],
            ),
    );
  }
}
