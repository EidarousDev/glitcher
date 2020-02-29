import 'package:flutter/material.dart';
import 'package:glitcher/models/notification_model.dart' as notification_model;
import 'package:glitcher/screens/posts/new_comment.dart';
import 'package:glitcher/services/notification_handler.dart';
import 'package:glitcher/utils/constants.dart';
import 'package:glitcher/utils/functions.dart';

class NotificationItem extends StatefulWidget {
  final notification_model.Notification notification;
  final String image;
  final String senderName;
  final int counter;

  NotificationItem(
      {Key key,
      @required this.notification,
      this.image,
      this.senderName,
      this.counter})
      : super(key: key);

  @override
  _NotificationItemState createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  NotificationHandler notificationHandler = NotificationHandler();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0),
      child: InkWell(
        child: _buildItem(widget.notification),
        onTap: () {},
      ),
    );
  }

  _buildItem(notification_model.Notification notification) {
    return Container(
      color: notification.seen? Constants.darkBG : Constants.darkAccent,
      child: Container(
        padding: EdgeInsets.all(7),
        child: ListTile(
          contentPadding: EdgeInsets.all(0),
          leading: CircleAvatar(
            backgroundImage: NetworkImage(
              "${widget.image}",
            ),
            radius: 25,
          ),
          title: Text(
            "${widget.senderName}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text("${widget.notification.body}"),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              SizedBox(height: 10),
              Text(
                "${Functions.formatTimestamp(widget.notification.timestamp)}"
                ,
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 11,
                ),
              ),
              SizedBox(height: 5),
              widget.counter == 0
                  ? SizedBox()
                  : Container(
                      padding: EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 11,
                        minHeight: 11,
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: 1, left: 5, right: 5),
                        child: Text(
                          "${widget.counter}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ],
          ),
          onTap: () {
            NotificationHandler notificationHandler = NotificationHandler();
            notificationHandler.makeNotificationSeen(widget.notification.id);

            Navigator.of(context).pushNamed('/post', arguments: {
              'postId': this.widget.notification.postId,
              'commentsNo': 5
            });

          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }
}
