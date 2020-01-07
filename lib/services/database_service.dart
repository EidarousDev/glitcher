import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glitcher/Models/user_model.dart';
import 'package:glitcher/models/post_model.dart';
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

  // This function is used to get the author info of each post
  static Future<User> getUserWithId(String userId) async {
    DocumentSnapshot userDocSnapshot = await usersRef.document(userId).get();
    if (userDocSnapshot.exists) {
      return User.fromDoc(userDocSnapshot);
    }
    return User();
  }
}