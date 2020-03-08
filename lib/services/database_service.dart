import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glitcher/models/game_model.dart';
import 'package:glitcher/models/message_model.dart';
import 'package:glitcher/models/notification_model.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/utils/constants.dart';

class DatabaseService {
  // This function is used to get the recent posts (unfiltered)
  static Future<List<Post>> getPosts() async {
    QuerySnapshot postSnapshot = await postsRef
        .orderBy('timestamp', descending: true)
        .limit(10)
        .getDocuments();
    List<Post> posts =
        postSnapshot.documents.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  static Future<List<Notification>> getNotifications() async {
    QuerySnapshot notificationSnapshot = await usersRef
        .document(Constants.currentUserID)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .getDocuments();
    List<Notification> notifications = notificationSnapshot.documents
        .map((doc) => Notification.fromDoc(doc))
        .toList();
    return notifications;
  }

  // This function is used to get the recent posts (unfiltered)
  static Future<List<Post>> getNextPosts(
      Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot postSnapshot = await postsRef
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(10)
        .getDocuments();
    List<Post> posts =
        postSnapshot.documents.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  // This function is used to get the author info of each post
  static Future<User> getUserWithId(String userId) async {
    DocumentSnapshot userDocSnapshot = await usersRef.document(userId).get();
    if (userDocSnapshot.exists) {
      return User.fromDoc(userDocSnapshot);
    }
    return User();
  }

  // This function is used to get the recent messages (unfiltered)
  static Future<List<Message>> getMessages(
      String userId, String otherUserId) async {
    QuerySnapshot msgSnapshot = await chatsRef
        .document(userId)
        .collection('conversations')
        .document(otherUserId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .getDocuments();
    List<Message> messages =
        msgSnapshot.documents.map((doc) => Message.fromDoc(doc)).toList();
    return messages;
  }

  static getGames() async{
    QuerySnapshot gameSnapshot = await gamesRef
        .orderBy('fullName', descending: true)
        .limit(10)
        .getDocuments();
    List<Game> games = gameSnapshot.documents
        .map((doc) => Game.fromDoc(doc))
        .toList();
    return games;
  }

  static getGameNames() async{
    Constants.games = [];
    QuerySnapshot gameSnapshot = await gamesRef
        .orderBy('fullName', descending: true)
        .getDocuments();
    List<Game> games = gameSnapshot.documents
            .map((doc) => Game.fromDoc(doc))
            .toList();

    for(var game in games){
      Constants.games.add(game.fullName);
    }
  }
}
