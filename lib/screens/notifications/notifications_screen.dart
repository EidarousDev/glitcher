import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/list_items/notification_item.dart';
import 'package:glitcher/models/notification_model.dart' as notification_model;
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/widgets/drawer.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<notification_model.Notification> _notifications = [];
  ScrollController _scrollController = ScrollController();

  Timestamp lastVisibleNotificationSnapShot;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: gradientAppBar(),
          leading: Builder(
              builder: (context) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: Icon(
                          const IconData(58311, fontFamily: 'MaterialIcons')),
                    ),
                  )),
          title: Text("Notifications"),
          centerTitle: true,
        ),
        body: _notifications.length > 0
            ? SingleChildScrollView(
                controller: _scrollController,
                child: ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemCount: _notifications.length,
                  itemBuilder: (BuildContext context, int index) {
                    notification_model.Notification notification =
                        _notifications[index];

                    return FutureBuilder(
                        future: DatabaseService.getUserWithId(
                            notification.sender,
                            checkLocally: true),
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          if (!snapshot.hasData) {
                            return SizedBox.shrink();
                          }
                          User sender = snapshot.data;
                          return Column(
                            children: <Widget>[
                              NotificationItem(
                                key: ValueKey(notification.id),
                                notification: notification,
                                image: sender.profileImageUrl,
                                senderName: sender.username,
                                counter: 0,
                              ),
                              Divider(height: .5, color: MyColors.darkLineBreak)
                            ],
                          );
                        });
                  },
                ),
              )
            : Center(
                child: Text(
                'No notifications yet',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              )),
        drawer: BuildDrawer(),
      ),
    );
  }

  _setupFeed() async {
    List<notification_model.Notification> notifications =
        await DatabaseService.getNotifications();
    setState(() {
      _notifications = notifications;
      this.lastVisibleNotificationSnapShot = notifications.last.timestamp;
    });
  }

  void nextNotifications() async {
    var notifications = await DatabaseService.getNextNotifications(
        lastVisibleNotificationSnapShot);
    if (notifications.length > 0) {
      setState(() {
        notifications.forEach((element) => _notifications.add(element));
        this.lastVisibleNotificationSnapShot = _notifications.last.timestamp;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController
      ..addListener(() {
        if (_scrollController.offset >=
                _scrollController.position.maxScrollExtent &&
            !_scrollController.position.outOfRange) {
          print('reached the bottom');
          nextNotifications();
        } else if (_scrollController.offset <=
                _scrollController.position.minScrollExtent &&
            !_scrollController.position.outOfRange) {
          print("reached the top");
        } else {}
      });
    _setupFeed();
  }

  Future<bool> _onBackPressed() {
    /// Navigate back to home page
    Navigator.of(context).pushReplacementNamed('/home');
  }
}
