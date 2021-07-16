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
  int isFollower;
  int isFollowing;
  int isFriend;

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
      this.search,
      this.isFollower,
      this.isFollowing,
      this.isFriend});

  factory User.fromDoc(DocumentSnapshot doc) {
    return User(
        id: doc.id,
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

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': this.id,
      'name': this.name,
      'username': this.username,
      'profile_url': this.profileImageUrl,
      'cover_url': this.coverImageUrl,
      'description': this.description,
      'following': this.following,
      'followers': this.followers,
      'friends': this.friends,
      'followed_games': this.followedGames,
      'is_follower': this.isFollower ?? 0,
      'is_following': this.isFollowing ?? 0,
      'is_friend': this.isFriend ?? 0,
    };
    return map;
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      username: map['username'],
      profileImageUrl: map['profile_url'],
      coverImageUrl: map['cover_url'],
      description: map['description'],
      following: map['following'],
      followers: map['followers'],
      friends: map['friends'],
      followedGames: map['followed_games'],
      isFollower: map['is_follower'],
      isFollowing: map['is_following'],
      isFriend: map['is_friend'],
    );
  }
}
