import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String username;
  final String profileImageUrl;
  final String email;
  final String description;
  final dynamic online;
  final int notificationsNumber;

  User(
      {this.id,
      this.name,
      this.username,
      this.profileImageUrl,
      this.email,
      this.description,
      this.online,
      this.notificationsNumber});

  factory User.fromDoc(DocumentSnapshot doc) {
    return User(
        id: doc.documentID,
        name: doc['name'],
        username: doc['username'],
        profileImageUrl: doc['profile_url'],
        email: doc['email'],
        description: doc['description'] ?? '',
        online: doc['online'],
        notificationsNumber: doc['notificationsNumber']);
  }
}
