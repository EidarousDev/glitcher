import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String username;
  final String profileImageUrl;
  final String email;
  final String description;
  final int followersCount;
  final int followingCount;
  final int friendsCount;
  final dynamic online;
  final int notificationsNumber;

  User(
      {this.id,
      this.name,
      this.username,
      this.profileImageUrl,
      this.email,
      this.description,
      this.followersCount,
      this.followingCount,
      this.friendsCount,
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
        followersCount: doc['followers'],
        followingCount: doc['following'],
        friendsCount: doc['friendsCount'],
        online: doc['online'],
        notificationsNumber: doc['notificationsNumber']);
  }
}
