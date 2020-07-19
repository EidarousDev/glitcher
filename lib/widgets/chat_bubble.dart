import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/screens/chats/audio_message_player.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:random_string/random_string.dart';

import 'image_overlay.dart';

class ChatBubble extends StatefulWidget {
  final String message, time, username, type, replyText, replyName;
  final bool isMe, isGroup, isReply;

  ChatBubble(
      {Key key,
      @required this.message,
      @required this.time,
      @required this.isMe,
      @required this.isGroup,
      @required this.username,
      @required this.type,
      @required this.replyText,
      @required this.isReply,
      @required this.replyName})
      : super(key: key);

  @override
  _ChatBubbleState createState() => _ChatBubbleState();
}

typedef void OnError(Exception exception);

enum PlayerState { stopped, playing, paused }

class _ChatBubbleState extends State<ChatBubble> {
  List colors = Colors.primaries;
  static Random random = Random();
  int rNum = random.nextInt(18);

  AudioMessagePlayer audioPlayerWidget;

  @override
  void initState() {
    super.initState();
    print('Message: ${widget.message}');
    audioPlayerWidget = AudioMessagePlayer(url: widget.message);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isMe ? Theme.of(context).accentColor : Colors.grey[200];
    final align =
        widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = widget.isMe
        ? BorderRadius.only(
            topLeft: Radius.circular(5.0),
            bottomLeft: Radius.circular(5.0),
            bottomRight: Radius.circular(10.0),
          )
        : BorderRadius.only(
            topRight: Radius.circular(5.0),
            bottomLeft: Radius.circular(10.0),
            bottomRight: Radius.circular(5.0),
          );
    return Column(
      crossAxisAlignment: align,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.all(3.0),
          padding: const EdgeInsets.all(5.0),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width / 1.3,
            minWidth: 20.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              widget.isMe
                  ? SizedBox()
                  : widget.isGroup
                      ? Padding(
                          padding: EdgeInsets.fromLTRB(5, 5, 5, 0),
                          child: Text(
                            widget.username,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors[rNum],
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        )
                      : SizedBox(),
              widget.isGroup
                  ? widget.isMe ? SizedBox() : SizedBox(height: 5)
                  : SizedBox(),
              widget.isReply
                  ? Container(
                      decoration: BoxDecoration(
                        color: !widget.isMe ? Colors.grey[50] : Colors.blue[50],
                        borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      ),
                      constraints: BoxConstraints(
                        minHeight: 25,
                        maxHeight: 100,
                        minWidth: 80,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(5),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              child: Text(
                                widget.isMe ? "You" : widget.replyName,
                                style: TextStyle(
                                  color: Theme.of(context).accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                textAlign: TextAlign.left,
                              ),
                              alignment: Alignment.centerLeft,
                            ),
                            SizedBox(height: 2),
                            Container(
                              child: Text(
                                widget.replyText,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                ),
                                maxLines: 2,
                              ),
                              alignment: Alignment.centerLeft,
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox(width: 2),
              widget.isReply ? SizedBox(height: 5) : SizedBox(),
              Padding(
                padding: EdgeInsets.all(widget.type == "text" ? 5 : 0),
                child: widget.type == "text"
                    ? !widget.isReply
                        ? Text(
                            widget.message,
                            style: TextStyle(
                              color: widget.isMe ? Colors.white : Colors.black,
                            ),
                          )
                        : Container(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.message,
                              style: TextStyle(
                                color:
                                    widget.isMe ? Colors.white : Colors.black,
                              ),
                            ),
                          )
                    : widget.type == 'image'
                        ? GestureDetector(
                            onTap: () {
                              showDialog(
                                  barrierDismissible: true,
                                  child: Container(
                                    width: Sizes.sm_profile_image_w,
                                    height: Sizes.sm_profile_image_h,
                                    child: ImageOverlay(
                                      imageUrl: widget.message,
                                      btnText: 'Download',
                                      btnFunction: () {
                                        downloadImage(widget.message, randomAlphaNumeric(20));
                                      },
                                    ),
                                  ),
                                  context: context);
                            },
                            child: Image.network(
                              "${widget.message}",
                              height: 130,
                              width: MediaQuery.of(context).size.width / 1.3,
                              fit: BoxFit.cover,
                            ),
                          )
                        : widget.type == 'audio'
                            ? audioPlayerWidget
                            : Container(),
              ),
            ],
          ),
        ),
        Padding(
          padding: widget.isMe
              ? EdgeInsets.only(
                  right: 10,
                  bottom: 10.0,
                )
              : EdgeInsets.only(
                  left: 10,
                  bottom: 10.0,
                ),
          child: Text(
            widget.time,
            style: TextStyle(
              color: switchColor(Colors.black54, Colors.white70),
              fontSize: 10.0,
            ),
          ),
        ),
      ],
    );
  }
}
