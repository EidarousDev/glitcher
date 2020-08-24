import 'dart:io';

import 'package:flutter/material.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/widgets/custom_widgets.dart';
import 'package:image_picker/image_picker.dart';

class CreateBottomIcon extends StatefulWidget {
  final TextEditingController textEditingController;
  final Function(File) onImageIconSelected;
  final Function(File) onVideoIconSelected;
  final bool isComment;
  CreateBottomIcon(
      {Key key,
      this.textEditingController,
      this.onImageIconSelected,
      this.onVideoIconSelected,
      this.isComment})
      : super(key: key);

  @override
  _CreateBottomIconState createState() => _CreateBottomIconState();
}

class _CreateBottomIconState extends State<CreateBottomIcon> {
  bool reachToWarning = false;
  bool reachToOver = false;
  Color wordCountColor;
  String tweet = '';

  @override
  void initState() {
    wordCountColor = Colors.blue;
    widget.textEditingController.addListener(updateUI);
    super.initState();
  }

  void updateUI() {
    setState(() {
      tweet = widget.textEditingController.text;
      if (widget.textEditingController.text != null &&
          widget.textEditingController.text.isNotEmpty) {
        if (widget.textEditingController.text.length > 259 &&
            widget.textEditingController.text.length < Sizes.maxPostChars) {
          wordCountColor = Colors.orange;
        } else if (widget.textEditingController.text.length >=
            Sizes.maxPostChars) {
          wordCountColor = Theme.of(context).errorColor;
        } else {
          wordCountColor = Colors.blue;
        }
      }
    });
  }

  Widget _bottomIconWidget() {
    return Container(
      width: Sizes.fullWidth(context),
      height: 50,
      decoration: BoxDecoration(
          border:
              Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          color: Theme.of(context).backgroundColor),
      child: Row(
        children: <Widget>[
          !widget.isComment
              ? IconButton(
                  onPressed: () {
                    setImage(ImageSource.gallery);
                  },
                  icon: Icon(Icons.image),
                  color: MyColors.darkPrimary,
                )
              : Container(),
          !widget.isComment
              ? IconButton(
                  onPressed: () {
                    setImage(ImageSource.camera);
                  },
                  icon: Icon(
                    Icons.camera_alt,
                    color: MyColors.darkPrimary,
                  ))
              : Container(),
//          IconButton(
//              onPressed: () {
//                setVideo();
//              },
//              icon: Icon(
//                Icons.videocam,
//                color: MyColors.darkPrimary,
//              )),
          Expanded(
              child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                child: tweet != null && tweet.length > Sizes.maxPostChars
                    ? Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: customText(
                            '${Sizes.maxPostChars - tweet.length}',
                            style:
                                TextStyle(color: Theme.of(context).errorColor)),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          CircularProgressIndicator(
                            value: getTweetLimit(),
                            backgroundColor: Colors.grey,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(wordCountColor),
                          ),
                          tweet.length > 259
                              ? customText(
                                  '${Sizes.maxPostChars - tweet.length}',
                                  style: TextStyle(color: wordCountColor))
                              : customText('',
                                  style: TextStyle(color: wordCountColor))
                        ],
                      )),
          ))
        ],
      ),
    );
  }

  void setImage(ImageSource source) {
    ImagePicker.pickImage(source: source, imageQuality: 20).then((File file) {
      setState(() {
        // _image = file;
        widget.onImageIconSelected(file);
      });
    });
  }

  void setVideo() async {
    ImagePicker imagePicker = ImagePicker();
    await imagePicker.getVideo(source: ImageSource.gallery).then((value) async {
      print(value.path);
      File file = File(value.path);
      setState(() {
        widget.onVideoIconSelected(file);
        print('file video xx $file');
      });
    });
  }

  double getTweetLimit() {
    if (tweet == null || tweet.isEmpty) {
      return 0.0;
    }
    if (tweet.length > Sizes.maxPostChars) {
      return 1.0;
    }
    var length = tweet.length;
    var val = length * 100 / (Sizes.maxPostChars * 100.0);
    return val;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _bottomIconWidget(),
    );
  }
}
