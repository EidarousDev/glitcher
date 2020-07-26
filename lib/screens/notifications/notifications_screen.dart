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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: gradientAppBar(),
        leading: Builder(
            builder: (context) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Icon(IconData(58311, fontFamily: 'MaterialIcons')),
                  ),
                )),
        title: Text("Notifications"),
        centerTitle: true,
      ),
      body: _notifications.length > 0
          ? SingleChildScrollView(
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemCount: _notifications.length,
                itemBuilder: (BuildContext context, int index) {
                  notification_model.Notification notification =
                      _notifications[index];

                  return FutureBuilder(
                      future:
                          DatabaseService.getUserWithId(notification.sender),
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
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
    );
  }

  _setupFeed() async {
    List<notification_model.Notification> notifications =
        await DatabaseService.getNotifications();
    setState(() {
      _notifications = notifications;
    });
  }

  loadUserData(String senderUserId) async {
    DatabaseService.getUserWithId(senderUserId);
  }

  makeAllNotificationsSeen() {}

  @override
  void initState() {
    super.initState();
    _setupFeed();
  }
}
