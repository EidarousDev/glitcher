import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glitcher/models/message_model.dart';
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
}
