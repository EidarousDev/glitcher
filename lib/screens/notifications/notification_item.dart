import 'package:flutter/material.dart';
import 'package:glitcher/models/notification_model.dart' as notification_model;
import 'package:glitcher/services/notification_handler.dart';


class NotificationItem extends StatefulWidget {
  final notification_model.Notification notification;

  NotificationItem({Key key, @required this.notification})
      : super(key: key);
  @override
  _NotificationItemState createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  NotificationHandler notificationHandler = NotificationHandler();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        child: _buildPost(widget.notification),
        onTap: () {},
      ),
    );
  }

  _buildPost(notification_model.Notification notification) {
    return null;
  }

  @override
  void initState() {
    super.initState();
  }


}
