import 'dart:io';

import 'package:flutter/material.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:video_player/video_player.dart';

class CreatePostVideo extends StatefulWidget {
  final File video;
  final Function onCrossIconPressed;

  const CreatePostVideo({Key key, this.video, this.onCrossIconPressed})
      : super(key: key);

  @override
  _CreatePostVideoState createState() =>
      _CreatePostVideoState(video, onCrossIconPressed);
}

class _CreatePostVideoState extends State<CreatePostVideo> {
  final File video;
  final Function onCrossIconPressed;
  VideoPlayerController videoPlayerController;
  VideoPlayer playerWidget;

  _CreatePostVideoState(this.video, this.onCrossIconPressed);

  setVideoFile() {}

  @override
  void initState() {
    setState(() {
      videoPlayerController = VideoPlayerController.file(video);
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    videoPlayerController.dispose();
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
                    child: playerWidget,
                  ),
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
