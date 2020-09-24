import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String username;
  final String profileImageUrl;
  final String coverImageUrl;
  final String email;
  final String description;
  final dynamic online;
  final int violations;
  final int following;
  final int followers;
  final int friends;
  final int followedGames;
  final bool isAccountPrivate;
  final int notificationsNumber;
  final List search;

  User(
      {this.id,
      this.name,
      this.username,
      this.profileImageUrl,
      this.coverImageUrl,
      this.email,
      this.description,
      this.online,
      this.violations,
      this.following,
      this.followers,
      this.friends,
      this.followedGames,
      this.isAccountPrivate,
      this.notificationsNumber,
      this.search});

  factory User.fromDoc(DocumentSnapshot doc) {
    return User(
        id: doc.documentID,
        name: doc['name'],
        username: doc['username'],
        profileImageUrl: doc['profile_url'],
        coverImageUrl: doc['cover_url'],
        email: doc['email'],
        description: doc['description'] ?? '',
        online: doc['online'],
        violations: doc['violations'],
        following: doc['following'],
        followers: doc['followers'],
        friends: doc['friends'],
        followedGames: doc['followed_games'],
        isAccountPrivate: doc['is_account_private'],
        notificationsNumber: doc['notificationsNumber'],
        search: doc['search']);
  }
}
