import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glitcher/models/game_model.dart';
import 'package:glitcher/models/comment_model.dart';
import 'package:glitcher/models/group_model.dart';
import 'package:glitcher/models/message_model.dart';
import 'package:glitcher/models/notification_model.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/utils/data.dart';

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

  // Get Post info of a specific post
  static Future<Post> getPostWithId(String postId) async {
    DocumentSnapshot postDocSnapshot = await postsRef.document(postId).get();
    if (postDocSnapshot.exists) {
      return Post.fromDoc(postDocSnapshot);
    }
    return Post();
  }

  // Get Post Meta Info of a specific post
  static Future<Map> getPostMeta(String postId) async {
    var postMeta = Map();
    DocumentSnapshot postDocSnapshot = await postsRef.document(postId).get();
    if (postDocSnapshot.exists) {
      postMeta['likes'] = postDocSnapshot.data['likes'];
      postMeta['dislikes'] = postDocSnapshot.data['dislikes'];
      postMeta['comments'] = postDocSnapshot.data['dislikes'];
    }
    return postMeta;
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

  // This function is used to get the recent posts (filtered by followed games)
  static Future<List<Post>> getNextPostsFilteredByFollowedGames(
      Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot postSnapshot = await postsRef
        .where('game', whereIn: Constants.followedGamesNames)
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(10)
        .getDocuments();
    List<Post> posts =
        postSnapshot.documents.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  // This function is used to get the recent posts (filtered by followed gamers)
  static Future<List<Post>> getNextPostsFilteredByFollowing(
      Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot postSnapshot = await postsRef
        .where('owner', whereIn: Constants.followingIds)
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(10)
        .getDocuments();
    List<Post> posts =
        postSnapshot.documents.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  static getFriends(String userId) async {
    QuerySnapshot friendsSnapshot =
        await usersRef.document(userId).collection('friends').getDocuments();

    List<User> friends =
        friendsSnapshot.documents.map((doc) => User.fromDoc(doc)).toList();
    return friends;
  }

  // This function is used to get the recent posts (filtered by a certain game)
  static Future<List<Post>> getGamePosts(String gameName) async {
    QuerySnapshot postSnapshot = await postsRef
        .where('game', isEqualTo: gameName)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .getDocuments();
    List<Post> posts =
        postSnapshot.documents.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  // This function is used to get the recent posts (filtered by a certain game)
  static Future<List<Post>> getNextGamePosts(
      Timestamp lastVisiblePostSnapShot, String gameName) async {
    QuerySnapshot postSnapshot = await postsRef
        .where('game', isEqualTo: gameName)
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(10)
        .getDocuments();
    List<Post> posts =
        postSnapshot.documents.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  static Future<List<Post>> getPostsFilteredByFollowedGames() async {
    QuerySnapshot postSnapshot = await postsRef
        .where('game', whereIn: Constants.followedGamesNames)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .getDocuments();
    List<Post> posts =
        postSnapshot.documents.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  static Future<List<Post>> getPostsFilteredByFollowing() async {
    QuerySnapshot postSnapshot = await postsRef
        .where('owner', whereIn: Constants.followingIds)
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

  // This function is used to get the author info of each post
  static Future<User> getUserWithId(String userId) async {
    DocumentSnapshot userDocSnapshot = await usersRef.document(userId).get();
    if (userDocSnapshot.exists) {
      return User.fromDoc(userDocSnapshot);
    }
    return User();
  }

  static Future<List<String>> getGroups() async {
    QuerySnapshot snapshot = await usersRef
        .document(Constants.currentUserID)
        .collection('chat_groups')
        .getDocuments();

    List<String> groups = [];

    snapshot.documents.forEach((f) {
      groups.add(f.documentID);
    });

    return groups;
  }

  static Future<Group> getGroupWithId(String groupId) async {
    DocumentSnapshot groupDocSnapshot =
        await chatGroupsRef.document(groupId).get();
    if (groupDocSnapshot.exists) {
      return Group.fromDoc(groupDocSnapshot);
    }
    return Group();
  }

  static getFollowing() async {
    QuerySnapshot following = await usersRef
        .document(Constants.currentUserID)
        .collection('following')
        .getDocuments();

    for (DocumentSnapshot doc in following.documents) {
      Constants.followingIds.add(doc.documentID);
    }
  }

  static getFollowedGames() async {
    QuerySnapshot followedGames = await usersRef
        .document(Constants.currentUserID)
        .collection('followedGames')
        .getDocuments();

    for (DocumentSnapshot doc in followedGames.documents) {
      Game game = await getGameWithId(doc.documentID);
      Constants.followedGamesNames.add(game.fullName);
    }
  }

  // This function is used to get the recent messages (unfiltered)
  static Future<List<Message>> getMessages(String otherUserId) async {
    QuerySnapshot msgSnapshot = await chatsRef
        .document(Constants.currentUserID)
        .collection('conversations')
        .document(otherUserId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .getDocuments();
    List<Message> messages =
        msgSnapshot.documents.map((doc) => Message.fromDoc(doc)).toList();
    return messages;
  }

  static Future<List<Message>> getGroupMessages(String groupId) async {
    QuerySnapshot msgSnapshot = await chatGroupsRef
        .document(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .getDocuments();
    List<Message> messages =
        msgSnapshot.documents.map((doc) => Message.fromDoc(doc)).toList();
    return messages;
  }

  static Future<List<Message>> getPrevMessages(
      Timestamp firstVisibleGameSnapShot, String otherUserId) async {
    QuerySnapshot msgSnapshot = await chatsRef
        .document(Constants.currentUserID)
        .collection('conversations')
        .document(otherUserId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfter([firstVisibleGameSnapShot])
        .limit(20)
        .getDocuments();
    List<Message> messages =
        msgSnapshot.documents.map((doc) => Message.fromDoc(doc)).toList();
    return messages;
  }

  static Future<List<Message>> getPrevGroupMessages(
      Timestamp firstVisibleGameSnapShot, String groupId) async {
    QuerySnapshot msgSnapshot = await chatGroupsRef
        .document(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfter([firstVisibleGameSnapShot])
        .limit(20)
        .getDocuments();
    List<Message> messages =
        msgSnapshot.documents.map((doc) => Message.fromDoc(doc)).toList();
    return messages;
  }

  /// To remove a user from a group or to exit a group
  static removeGroupMember(String groupId, String memberId) async {
    await chatGroupsRef
        .document(groupId)
        .collection('users')
        .document(memberId)
        .delete();

    await usersRef
        .document(memberId)
        .collection('chat_groups')
        .document(groupId)
        .delete();
  }

  static addMemberToGroup(String groupId, String memberId) async {
    await chatGroupsRef
        .document(groupId)
        .collection('users')
        .document(memberId)
        .setData(
            {'is_admin': false, 'timestamp': FieldValue.serverTimestamp()});

    await usersRef
        .document(memberId)
        .collection('chat_groups')
        .document(groupId)
        .setData({'timestamp': FieldValue.serverTimestamp()});
  }

  static toggleMemberAdmin(String groupId, String memberId) async {
    DocumentSnapshot doc = await chatGroupsRef
        .document(groupId)
        .collection('users')
        .document(memberId)
        .get();

    doc.reference.updateData({
      'is_admin': !doc.data['is_admin'],
      'timestamp': FieldValue.serverTimestamp()
    });
  }

  // Get Comments of a specific post
  static Future<List<Comment>> getComments(String postId) async {
    QuerySnapshot commentSnapshot = await postsRef
        .document(postId)
        .collection('comments')
        ?.orderBy('timestamp', descending: true)
        ?.limit(10)
        ?.getDocuments();
    List<Comment> comments =
        commentSnapshot.documents.map((doc) => Comment.fromDoc(doc)).toList();
    return comments;
  }

  // This function is used to get the author info of each post
  static Future<Game> getGameWithId(String gameId) async {
    DocumentSnapshot gameDocSnapshot = await gamesRef.document(gameId).get();
    if (gameDocSnapshot.exists) {
      return Game.fromDoc(gameDocSnapshot);
    }
    return Game();
  }

  static getGames() async {
    QuerySnapshot gameSnapshot = await gamesRef
        .orderBy('fullName', descending: false)
        .limit(6)
        .getDocuments();
    List<Game> games =
        gameSnapshot.documents.map((doc) => Game.fromDoc(doc)).toList();
    return games;
  }

  static getGameNames() async {
    Constants.games = [];
    QuerySnapshot gameSnapshot =
        await gamesRef.orderBy('fullName', descending: true).getDocuments();
    List<Game> games =
        gameSnapshot.documents.map((doc) => Game.fromDoc(doc)).toList();

    for (var game in games) {
      Constants.games.add(game.fullName);
    }
  }

  static Future<List<Game>> getNextGames(String lastVisibleGameSnapShot) async {
    QuerySnapshot gameSnapshot = await gamesRef
        .orderBy('fullName', descending: false)
        .startAfter([lastVisibleGameSnapShot])
        .limit(10)
        .getDocuments();
    List<Game> games =
        gameSnapshot.documents.map((doc) => Game.fromDoc(doc)).toList();
    return games;
  }

  static Future<List> searchGames(text) async {
    QuerySnapshot gameSnapshot = await gamesRef
        .where('search', arrayContains: text)
        .orderBy('fullName', descending: false)
        .getDocuments();
    List<Game> games =
        gameSnapshot.documents.map((doc) => Game.fromDoc(doc)).toList();
    return games;
  }

  // This function is used to submit/add a comment
  static void addComment(String postId, String commentText) async {
    await postsRef.document(postId).collection('comments').add({
      'commenter': Constants.currentUserID,
      'text': commentText,
      'timestamp': FieldValue.serverTimestamp()
    });
    await postsRef
        .document(postId)
        .updateData({'comments': FieldValue.increment(1)});
  }

  static followGame(String gameId) async {
    DocumentSnapshot gameDocSnapshot = await usersRef
        .document(Constants.currentUserID)
        .collection('followedGames')
        .document(gameId)
        .get();
    if (!gameDocSnapshot.exists) {
      await usersRef
          .document(Constants.currentUserID)
          .collection('followedGames')
          .document(gameId)
          .setData({'followedAt': FieldValue.serverTimestamp()});
    }
  }

  static unFollowGame(String gameId) async {
    DocumentSnapshot gameDocSnapshot = await usersRef
        .document(Constants.currentUserID)
        .collection('followedGames')
        .document(gameId)
        .get();
    if (gameDocSnapshot.exists) {
      await usersRef
          .document(Constants.currentUserID)
          .collection('followedGames')
          .document(gameId)
          .delete();
    }
  }
}
