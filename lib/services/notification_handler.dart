import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/constants.dart';

class NotificationHandler {
  void receiveNotification(BuildContext context) {
    StreamSubscription iosSubscription;
    FirebaseMessaging _fcm = FirebaseMessaging();

    if (Platform.isIOS) {
      iosSubscription = _fcm.onIosSettingsRegistered.listen((data) {
        // save the token  OR subscribe to a topic here
      });

      _fcm.requestNotificationPermissions(IosNotificationSettings());
    }

    _fcm.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        makeNotificationSeen(message['data']['id']);

        final SnackBar snackBar = SnackBar(
          content: Text(
            message['notification']['title'],
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          action: SnackBarAction(
            label: 'GO',
            textColor: Colors.white,
            onPressed: () {},
          ),
        );

        Scaffold.of(context).showSnackBar(snackBar);

        showNotification(message);
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        makeNotificationSeen(message['data']['id']);
        Navigator.of(context).pushNamed('/post', arguments: {
          'postId': message['data']['postId'],
          'commentsNo': 5
        });
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        makeNotificationSeen(message['data']['id']);
        Navigator.of(context).pushNamed('/post', arguments: {
          'postId': message['data']['postId'],
          'commentsNo': 5
        });
      },
    );
  }

  void sendNotification (String receiverId, String title, String body, String postId) async{
    usersRef.document(receiverId).collection('notifications').add({
      'title': title,
      'body': body,
      'seen': false,
      'timestamp': FieldValue.serverTimestamp(),
      'sender': Constants.currentUserID,
      'postId': postId
    });

    //To increment notificationsNumber
    User user = await DatabaseService.getUserWithId(receiverId);
    usersRef.document(receiverId).updateData({'notificationsNumber': user.notificationsNumber + 1});
  }

  void makeNotificationSeen(String notificationId) {
    usersRef.document(Constants.currentUserID).collection('notifications').document(notificationId).updateData({
      'seen': true,
    });
  }

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  void configLocalNotification() {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void showNotification(Map<String, dynamic> message) async {
    configLocalNotification();

    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      Platform.isAndroid
          ? 'com.eidarousdev.glitcher'
          : 'com.eidarousdev.glitcher',
      'glitcher',
      'your channel description',
      enableVibration: true,
      importance: Importance.Max,
      priority: Priority.High,
      autoCancel: true
      
    );
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0,
        message['notification']['title'].toString(),
        message['notification']['body'].toString(),
        platformChannelSpecifics,
        payload: json.encode(message));
  }

  clearNotificationsNumber() async{
    await DatabaseService.getUserWithId(Constants.currentUserID);
    usersRef.document(Constants.currentUserID).updateData({'notificationsNumber': 0});
  }
}
