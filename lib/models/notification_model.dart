import 'package:cloud_firestore/cloud_firestore.dart';

class Notification {
  final String id;
  final String title;
  final String body;
  final String icon;
  final bool seen;
  final Timestamp timestamp;
  final String sender;
  final String postId;

  Notification(
      {this.id,
        this.title,
        this.body,
        this.icon,
        this.seen,
        this.timestamp,
        this.sender,
        this.postId});

  factory Notification.fromDoc(DocumentSnapshot doc) {
    return Notification(
        id: doc.documentID,
        title: doc['title'],
        body: doc['body'],
        icon: doc['icon'],
        seen: doc['seen'],
        timestamp: doc['timestamp'],
        sender: doc['sender'],
        postId: doc['postId']);
  }
}