import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/models/comment_model.dart';
import 'package:glitcher/models/game_model.dart';
import 'package:glitcher/models/group_model.dart';
import 'package:glitcher/models/hashtag_model.dart';
import 'package:glitcher/models/message_model.dart';
import 'package:glitcher/models/notification_model.dart' as notification;
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/services/notification_handler.dart';
import 'package:glitcher/utils/functions.dart';

class DatabaseService {
  // This function is used to get the recent posts (unfiltered)
  static Future<List<Post>> getPosts() async {
    QuerySnapshot postSnapshot = await postsRef
        .orderBy('timestamp', descending: true)
        .limit(20)
        .getDocuments();
    List<Post> posts =
        postSnapshot.documents.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  //Gets the posts of a certain user
  static Future<List<Post>> getUserPosts(String authorId) async {
    QuerySnapshot postSnapshot = await postsRef
        .where('author', isEqualTo: authorId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .getDocuments();
    List<Post> posts =
        postSnapshot.documents.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  // This function is used to get the recent posts of a certain user
  static Future<List<Post>> getNextUserPosts(
      String authorId, Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot postSnapshot = await postsRef
        .where('author', isEqualTo: authorId)
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .getDocuments();
    List<Post> posts =
        postSnapshot.documents.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  static Future<Post> getUserLastPost(String authorId) async {
    QuerySnapshot postSnapshot = await postsRef
        .where('author', isEqualTo: authorId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .getDocuments();
    List<Post> posts =
        postSnapshot.documents.map((doc) => Post.fromDoc(doc)).toList();

    if (posts == null || posts.isEmpty) {
      return null;
    } else {
      return posts[0];
    }
  }

  /// Check Username availability
  static Future<bool> isUsernameTaken(String name) async {
    final QuerySnapshot result = await Firestore.instance
        .collection('users')
        .where('username', isEqualTo: name)
        .limit(1)
        .getDocuments();
    return result.documents.isEmpty;
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
      postMeta['comments'] = postDocSnapshot.data['comments'];
    }
    return postMeta;
  }

  // Get Post Meta Info of a specific post
  static Future<Map> getCommentMeta(String postId, String commentId) async {
    var commentMeta = Map();
    DocumentSnapshot commentDocSnapshot = await postsRef
        .document(postId)
        .collection('comments')
        .document(commentId)
        .get();

    if (commentDocSnapshot.exists) {
      commentMeta['likes'] = commentDocSnapshot.data['likes'];
      commentMeta['dislikes'] = commentDocSnapshot.data['dislikes'];
      commentMeta['replies'] = commentDocSnapshot.data['replies'];
    }
    return commentMeta;
  }

  static Future<Map> getReplyMeta(
      String postId, String commentId, String replyId) async {
    var replyMeta = Map();
    DocumentSnapshot replyDocSnapshot = await postsRef
        .document(postId)
        .collection('comments')
        .document(commentId)
        .collection('replies')
        .document(replyId)
        .get();

    if (replyDocSnapshot.exists) {
      replyMeta['likes'] = replyDocSnapshot.data['likes'];
      replyMeta['dislikes'] = replyDocSnapshot.data['dislikes'];
    }
    return replyMeta;
  }

  // This function is used to get the recent posts (unfiltered)
  static Future<List<Post>> getNextPosts(
      Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot postSnapshot = await postsRef
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .getDocuments();
    List<Post> posts =
        postSnapshot.documents.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  // This function is used to get the recent user posts (unfiltered)
  static Future<List<Post>> getUserNextPosts(
      Timestamp lastVisiblePostSnapShot, String authorId) async {
    QuerySnapshot postSnapshot = await postsRef
        .where('author', isEqualTo: authorId)
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .getDocuments();
    List<Post> posts =
        postSnapshot.documents.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  static deletePost(String postId) async {
    print('deleting post...');

    CollectionReference commentsRef =
        postsRef.document(postId).collection('comments');

    CollectionReference likesRef =
        postsRef.document(postId).collection('likes');

    CollectionReference dislikesRef =
        postsRef.document(postId).collection('dislikes');

    (await commentsRef.getDocuments()).documents.forEach((comment) async {
      (await commentsRef
              .document(comment.documentID)
              .collection('replies')
              .getDocuments())
          .documents
          .forEach((reply) async {
        (await commentsRef
                .document(comment.documentID)
                .collection('replies')
                .document(reply.documentID)
                .collection('likes')
                .getDocuments())
            .documents
            .forEach((replyLike) {
          commentsRef
              .document(comment.documentID)
              .collection('replies')
              .document(reply.documentID)
              .collection('likes')
              .document(replyLike.documentID)
              .delete();
        });

        (await commentsRef
                .document(comment.documentID)
                .collection('replies')
                .document(reply.documentID)
                .collection('dislikes')
                .getDocuments())
            .documents
            .forEach((replyDislike) {
          commentsRef
              .document(comment.documentID)
              .collection('replies')
              .document(reply.documentID)
              .collection('dislikes')
              .document(replyDislike.documentID)
              .delete();
        });

        commentsRef
            .document(comment.documentID)
            .collection('replies')
            .document(reply.documentID)
            .delete();
      });

      (await commentsRef
              .document(comment.documentID)
              .collection('likes')
              .getDocuments())
          .documents
          .forEach((commentLike) async {
        await commentsRef
            .document(comment.documentID)
            .collection('likes')
            .document(commentLike.documentID)
            .delete();
      });

      (await commentsRef
              .document(comment.documentID)
              .collection('dislikes')
              .getDocuments())
          .documents
          .forEach((commentDislike) async {
        await commentsRef
            .document(comment.documentID)
            .collection('dislikes')
            .document(commentDislike.documentID)
            .delete();
      });

      await commentsRef.document(comment.documentID).delete();
    });

    (await likesRef.getDocuments()).documents.forEach((like) async {
      await likesRef.document(like.documentID).delete();
    });

    (await dislikesRef.getDocuments()).documents.forEach((dislike) async {
      await dislikesRef.document(dislike.documentID).delete();
    });

    await postsRef.document(postId).delete();
  }

  static deleteComment(
      String postId, String commentId, String parentCommentId) async {
    if (parentCommentId == null) {
      DocumentReference commentRef =
          postsRef.document(postId).collection('comments').document(commentId);
      (await commentRef.collection('replies').getDocuments())
          .documents
          .forEach((reply) async {
        (await commentRef
                .collection('replies')
                .document(reply.documentID)
                .collection('likes')
                .getDocuments())
            .documents
            .forEach((replyLike) {
          commentRef
              .collection('replies')
              .document(reply.documentID)
              .collection('likes')
              .document(replyLike.documentID)
              .delete();
        });

        (await commentRef
                .collection('replies')
                .document(reply.documentID)
                .collection('dislikes')
                .getDocuments())
            .documents
            .forEach((replyDislike) {
          commentRef
              .collection('replies')
              .document(reply.documentID)
              .collection('dislikes')
              .document(replyDislike.documentID)
              .delete();
        });

        commentRef.collection('replies').document(reply.documentID).delete();
      });

      (await commentRef.collection('likes').getDocuments())
          .documents
          .forEach((commentLike) async {
        await commentRef
            .collection('likes')
            .document(commentLike.documentID)
            .delete();
      });

      (await commentRef.collection('dislikes').getDocuments())
          .documents
          .forEach((commentDislike) async {
        await commentRef
            .collection('dislikes')
            .document(commentDislike.documentID)
            .delete();
      });

      await commentRef.delete();

      await postsRef
          .document(postId)
          .updateData({'comments': FieldValue.increment(-1)});
    } else {
      DocumentReference replyRef = postsRef
          .document(postId)
          .collection('comments')
          .document(parentCommentId)
          .collection('replies')
          .document(commentId);

      (await replyRef.collection('likes').getDocuments())
          .documents
          .forEach((replyLike) {
        replyRef.collection('likes').document(replyLike.documentID).delete();
      });

      (await replyRef.collection('dislikes').getDocuments())
          .documents
          .forEach((replyDislike) {
        replyRef
            .collection('dislikes')
            .document(replyDislike.documentID)
            .delete();
      });

      replyRef.delete();

      await postsRef
          .document(postId)
          .collection('comments')
          .document(parentCommentId)
          .updateData({'replies': FieldValue.increment(-1)});
    }
  }

  // This function is used to get the recent posts (filtered by followed games)
  static Future<List<Post>> getNextPostsFilteredByFollowedGames(
      Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot postSnapshot = await postsRef
        .where('game', whereIn: Constants.followedGamesNames)
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .getDocuments();
    List<Post> posts =
        postSnapshot.documents.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  // This function is used to get the recent posts (filtered by followed gamers)
  static Future<List<Post>> getNextPostsFilteredByFollowing(
      Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot postSnapshot = await postsRef
        .where('author', whereIn: Constants.followingIds)
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
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

    for (int i = 0; i < friends.length; i++) {
      friends[i] = await DatabaseService.getUserWithId(friends[i].id);
    }

    return friends;
  }

  static getFollowing(String userId) async {
    QuerySnapshot followingSnapshot =
        await usersRef.document(userId).collection('following').getDocuments();

    List<User> following =
        followingSnapshot.documents.map((doc) => User.fromDoc(doc)).toList();

    for (int i = 0; i < following.length; i++) {
      following[i] = await DatabaseService.getUserWithId(following[i].id);
    }

    for (DocumentSnapshot doc in followingSnapshot.documents) {
      Constants.followingIds.add(doc.documentID);
    }

    return following;
  }

  static getFollowers(String userId) async {
    QuerySnapshot followersSnapshot =
        await usersRef.document(userId).collection('followers').getDocuments();

    List<User> followers =
        followersSnapshot.documents.map((doc) => User.fromDoc(doc)).toList();

    for (int i = 0; i < followers.length; i++) {
      followers[i] = await DatabaseService.getUserWithId(followers[i].id);
    }
    return followers;
  }

  // This function is used to get the recent posts (filtered by a certain game)
  static Future<List<Post>> getGamePosts(String gameName) async {
    QuerySnapshot postSnapshot = await postsRef
        .where('game', isEqualTo: gameName)
        .orderBy('timestamp', descending: true)
        .limit(20)
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
        .limit(20)
        .getDocuments();
    List<Post> posts =
        postSnapshot.documents.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  static Future<List<Post>> getPostsFilteredByFollowedGames() async {
    QuerySnapshot postSnapshot = await postsRef
        .where('game', whereIn: Constants.followedGamesNames)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .getDocuments();
    List<Post> posts =
        postSnapshot.documents.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  static Future<List<Post>> getPostsFilteredByFollowing() async {
    QuerySnapshot postSnapshot = await postsRef
        .where('author', whereIn: Constants.followingIds)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .getDocuments();
    List<Post> posts =
        postSnapshot.documents.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  static Future<List<notification.Notification>> getNotifications() async {
    QuerySnapshot notificationSnapshot = await usersRef
        .document(Constants.currentUserID)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .getDocuments();
    List<notification.Notification> notifications = notificationSnapshot
        .documents
        .map((doc) => notification.Notification.fromDoc(doc))
        .toList();
    return notifications;
  }

  static Future<List<notification.Notification>> getNextNotifications(
      Timestamp lastVisibleNotificationSnapShot) async {
    QuerySnapshot notificationSnapshot = await usersRef
        .document(Constants.currentUserID)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisibleNotificationSnapShot])
        .limit(20)
        .getDocuments();
    List<notification.Notification> notifications = notificationSnapshot
        .documents
        .map((doc) => notification.Notification.fromDoc(doc))
        .toList();
    return notifications;
  }

  // This function is used to get the author info of each post
  static Future<User> getUserWithId(String userId) async {
    DocumentSnapshot userDocSnapshot = await usersRef?.document(userId)?.get();
    if (userDocSnapshot.exists) {
      return User.fromDoc(userDocSnapshot);
    }
    return User();
  }

  static Future<User> getUserWithEmail(String email) async {
    QuerySnapshot userDocSnapshot =
        await usersRef.where('email', isEqualTo: email).getDocuments();
    if (userDocSnapshot.documents.length != 0) {
      return User.fromDoc(userDocSnapshot.documents[0]);
    }
    return User();
  }

  static Future<User> getUserWithUsername(String username) async {
    QuerySnapshot userDocSnapshot =
        await usersRef.where('username', isEqualTo: username).getDocuments();
    User user =
        userDocSnapshot.documents.map((doc) => User.fromDoc(doc)).toList()[0];

    return user;
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

  static sendGroupMessage(String groupId, String type, String message) async {
    await chatGroupsRef.document(groupId).collection('messages').add({
      'sender': Constants.currentUserID,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type
    });
  }

  static sendMessage(String otherUserId, String type, String message) async {
    await chatsRef
        .document(Constants.currentUserID)
        .collection('conversations')
        .document(otherUserId)
        .collection('messages')
        .add({
      'sender': Constants.currentUserID,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type
    });

    await chatsRef
        .document(otherUserId)
        .collection('conversations')
        .document(Constants.currentUserID)
        .collection('messages')
        .add({
      'sender': Constants.currentUserID,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type
    });
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

  static getLastMessage(String otherUserId) async {
    QuerySnapshot msgSnapshot = await chatsRef
        .document(Constants.currentUserID)
        .collection('conversations')
        .document(otherUserId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .getDocuments();
    List<Message> messages =
        msgSnapshot.documents.map((doc) => Message.fromDoc(doc)).toList();
    if (messages.length == 0)
      return Message(
          message: 'Say hi to your new friend!',
          type: 'text',
          sender: otherUserId,
          timestamp: Timestamp.fromDate(DateTime.now()));
    return messages[0];
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

  static Future<List<String>> getGroupMembersIds(String groupId) async {
    QuerySnapshot members = await chatGroupsRef
        .document(groupId)
        .collection('users')
        .getDocuments();
    List<String> ids = [];
    members.documents.forEach((doc) {
      ids.add(doc.documentID);
    });

    return ids;
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

    await doc.reference.updateData({
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
        ?.limit(20)
        ?.getDocuments();
    List<Comment> comments =
        commentSnapshot.documents.map((doc) => Comment.fromDoc(doc)).toList();
    return comments;
  }

  static Future<List<Comment>> getNextComments(
      String postId, Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot commentSnapshot = await postsRef
        .document(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .getDocuments();
    List<Comment> comments =
        commentSnapshot.documents.map((doc) => Comment.fromDoc(doc)).toList();
    return comments;
  }

  static Future<List<Comment>> getCommentReplies(
      String postId, String commentId) async {
    QuerySnapshot commentSnapshot = await postsRef
        .document(postId)
        .collection('comments')
        .document(commentId)
        .collection('replies')
        ?.orderBy('timestamp', descending: true)
        ?.limit(20)
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
//        .orderBy(
//          'frequency',
//          descending: true,
//        )
        .limit(20)
        .getDocuments();
    List<Game> games =
        gameSnapshot.documents.map((doc) => Game.fromDoc(doc)).toList();
    return games;
  }

//  static getGameNames() async {
//    Constants.games = [];
//    QuerySnapshot gameSnapshot =
//        await gamesRef.orderBy('fullName', descending: true).getDocuments();
//    List<Game> games =
//        gameSnapshot.documents.map((doc) => Game.fromDoc(doc)).toList();
//
//    for (var game in games) {
//      Constants.games.add(game.fullName);
//    }
//  }

  static Future<List<Game>> getNextGames(String lastVisibleGameSnapShot) async {
    QuerySnapshot gameSnapshot = await gamesRef
        .orderBy(
          'frequency',
          descending: true,
        )
        .startAfter([lastVisibleGameSnapShot])
        .limit(20)
        .getDocuments();
    List<Game> games =
        gameSnapshot.documents.map((doc) => Game.fromDoc(doc)).toList();
    return games;
  }

  static Future<List> searchGames(text) async {
    QuerySnapshot gameSnapshot = await gamesRef
        .where('search', arrayContains: text)
        .orderBy('fullName', descending: false)
        .limit(20)
        .getDocuments();
    List<Game> games =
        gameSnapshot.documents.map((doc) => Game.fromDoc(doc)).toList();
    return games;
  }

  static Future<List> nextSearchGames(
      String lastVisiblePostSnapShot, String text) async {
    QuerySnapshot gameSnapshot = await gamesRef
        .where('search', arrayContains: text)
        .orderBy('fullName', descending: false)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .getDocuments();
    List<Game> games =
        gameSnapshot.documents.map((doc) => Game.fromDoc(doc)).toList();
    return games;
  }

  static Future<List> searchUsers(text) async {
    QuerySnapshot usersSnapshot = await usersRef
        .where('search', arrayContains: text)
        .orderBy('username', descending: false)
        .limit(20)
        .getDocuments();
    List<User> users =
        usersSnapshot.documents.map((doc) => User.fromDoc(doc)).toList();
    return users;
  }

  static Future<List> nextSearchUsers(
      String lastVisiblePostSnapShot, String text) async {
    QuerySnapshot usersSnapshot = await usersRef
        .where('search', arrayContains: text)
        .orderBy('username', descending: false)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .getDocuments();
    List<User> users =
        usersSnapshot.documents.map((doc) => User.fromDoc(doc)).toList();
    return users;
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

  static void editComment(
      String postId, String commentId, String commentText) async {
    await postsRef
        .document(postId)
        .collection('comments')
        .document(commentId)
        .updateData(
            {'text': commentText, 'timestamp': FieldValue.serverTimestamp()});
  }

  static void addReply(
      String postId, String commentId, String replyText) async {
    await postsRef
        .document(postId)
        .collection('comments')
        .document(commentId)
        .collection('replies')
        .add({
      'commenter': Constants.currentUserID,
      'text': replyText,
      'timestamp': FieldValue.serverTimestamp()
    });
    await postsRef
        .document(postId)
        .collection('comments')
        .document(commentId)
        .updateData({'replies': FieldValue.increment(1)});
  }

  static void editReply(
      String postId, String commentId, String replyId, String replyText) async {
    await postsRef
        .document(postId)
        .collection('comments')
        .document(commentId)
        .collection('replies')
        .document(replyId)
        .updateData(
            {'text': replyText, 'timestamp': FieldValue.serverTimestamp()});
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

  static Future<Game> getGameWithGameName(String gameName) async {
    QuerySnapshot gameDocSnapshot =
        await gamesRef.where('fullName', isEqualTo: gameName).getDocuments();
    Game game =
        gameDocSnapshot.documents.map((doc) => Game.fromDoc(doc)).toList()[0];

    return game;
  }

  static getHashtags() async {
    QuerySnapshot hashtagsSnapshot = await hashtagsRef.getDocuments();

    List<Hashtag> hashtags =
        hashtagsSnapshot.documents.map((doc) => Hashtag.fromDoc(doc)).toList();

    return hashtags;
  }

  static Future<Hashtag> getHashtagWithText(String text) async {
    QuerySnapshot hashtagDocSnapshot =
        await hashtagsRef.where('text', isEqualTo: text).getDocuments();

    if (hashtagDocSnapshot.documents.length == 0) {
      return null;
    } else {
      Hashtag hashtag = hashtagDocSnapshot.documents
          .map((doc) => Hashtag.fromDoc(doc))
          .toList()[0];

      return hashtag;
    }
  }

  // This function is used to get the recent posts for a certain tag
  static Future<List<Post>> getHashtagPosts(String hashtagId) async {
    QuerySnapshot postSnapshot = await hashtagsRef
        .document(hashtagId)
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .getDocuments();

    List<Post> posts = [];

    for (DocumentSnapshot doc in postSnapshot.documents) {
      DocumentSnapshot postDoc = await postsRef.document(doc.documentID).get();

      if (postDoc.exists) {
        posts.add(await getPostWithId(doc.documentID));
      } else {
        hashtagsRef
            .document(hashtagId)
            .collection('posts')
            .document(doc.documentID)
            .delete();
      }
    }

    return posts;
  }

  // This function is used to get the recent posts (filtered by a certain game)
  static Future<List<Post>> getNextHashtagPosts(
      Timestamp lastVisiblePostSnapShot, String hashtagId) async {
    QuerySnapshot postSnapshot = await hashtagsRef
        .document(hashtagId)
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .getDocuments();

    List<Post> posts = [];

    for (DocumentSnapshot doc in postSnapshot.documents) {
      DocumentSnapshot postDoc = await postsRef.document(doc.documentID).get();

      if (postDoc.exists) {
        posts.add(await getPostWithId(doc.documentID));
      } else {
        hashtagsRef
            .document(hashtagId)
            .collection('posts')
            .document(doc.documentID)
            .delete();
      }
    }

    return posts;
  }

  static Future<List<Post>> getBookmarksPosts() async {
    QuerySnapshot postSnapshot = await usersRef
        .document(Constants.currentUserID)
        .collection('bookmarks')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .getDocuments();

    List<Post> posts = [];

    for (DocumentSnapshot doc in postSnapshot.documents) {
      DocumentSnapshot postDoc = await postsRef.document(doc.documentID).get();

      if (postDoc.exists) {
        Post post = await getPostWithId(doc.documentID);

        posts.add(post);
      } else {
        posts.add(Post(id: doc.documentID, authorId: 'deleted'));
//        usersRef
//            .document(Constants.currentUserID)
//            .collection('bookmarks')
//            .document(doc.documentID)
//            .delete();
      }
    }
    return posts;
  }

  static Future<List<Post>> getNextBookmarksPosts(
      Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot postsSnapshot = await usersRef
        .document(Constants.currentUserID)
        .collection('bookmarks')
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .getDocuments();

    List<Post> posts = [];

    for (DocumentSnapshot doc in postsSnapshot.documents) {
      DocumentSnapshot postDoc = await postsRef.document(doc.documentID).get();

      if (postDoc.exists) {
        posts.add(await getPostWithId(doc.documentID));
      } else {
        usersRef
            .document(Constants.currentUserID)
            .collection('bookmarks')
            .document(doc.documentID)
            .delete();
      }
    }

    return posts;
  }

  static addPostToBookmarks(String postId) async {
    await usersRef
        .document(Constants.currentUserID)
        .collection('bookmarks')
        .document(postId)
        .setData({'timestamp': FieldValue.serverTimestamp()});
  }

  static unfollowUser(String userId) async {
    await usersRef
        .document(Constants.currentUserID)
        .collection('following')
        .document(userId)
        .delete();

    await usersRef
        .document(userId)
        .collection('followers')
        .document(Constants.currentUserID)
        .delete();

    DocumentSnapshot doc = await usersRef
        .document(Constants.currentUserID)
        .collection('friends')
        .document(userId)
        .get();

    if (doc.exists) {
      await usersRef
          .document(Constants.currentUserID)
          .collection('friends')
          .document(userId)
          .delete();
    }

    DocumentSnapshot doc2 = await usersRef
        .document(userId)
        .collection('friends')
        .document(Constants.currentUserID)
        .get();

    if (doc2.exists) {
      await usersRef
          .document(userId)
          .collection('friends')
          .document(Constants.currentUserID)
          .delete();
    }

    List<User> friends = await getFriends(Constants.currentUserID);
    Constants.userFriends = friends;
    List<User> following = await getFollowing(Constants.currentUserID);
    Constants.userFollowing = following;
    List<User> followers = await getFollowers(Constants.currentUserID);
    Constants.userFollowers = followers;
  }

  static followUser(String userId) async {
    FieldValue timestamp = FieldValue.serverTimestamp();

    await usersRef
        .document(userId)
        .collection('followers')
        .document(Constants.currentUserID)
        .setData({
      'timestamp': FieldValue.serverTimestamp(),
    });

    await usersRef
        .document(Constants.currentUserID)
        .collection('following')
        .document(userId)
        .setData({
      'timestamp': timestamp,
    });

    DocumentSnapshot doc = await usersRef
        .document(userId)
        .collection('following')
        .document(Constants.currentUserID)
        .get();

    if (doc.exists) {
      await usersRef
          .document(Constants.currentUserID)
          .collection('friends')
          .document(userId)
          .setData({'timestamp': FieldValue.serverTimestamp()});

      await usersRef
          .document(userId)
          .collection('friends')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});

      NotificationHandler.sendNotification(
          userId,
          '${Constants.currentUser.username} followed you',
          'You are now friends',
          Constants.currentUserID,
          'follow');
    } else {
      NotificationHandler.sendNotification(
          userId,
          '${Constants.currentUser.username} followed you',
          'Follow him back to be friends',
          Constants.currentUserID,
          'follow');
    }

    List<User> friends = await getFriends(Constants.currentUserID);
    Constants.userFriends = friends;
    List<User> following = await getFollowing(Constants.currentUserID);
    Constants.userFollowing = following;
    List<User> followers = await getFollowers(Constants.currentUserID);
    Constants.userFollowers = followers;
  }

  static addUserToDatabase(String id, String email, String username) async {
    List search = searchList(username);
    Map<String, dynamic> userMap = {
      'name': 'John Doe',
      'username': username,
      'email': email,
      'description': 'Write something about yourself',
      'notificationsNumber': 0,
      'violations': 0,
      'search': search
    };

    await usersRef.document(id).setData(userMap);
  }

  static addUserEmailToNewsletter(
      String userId, String email, String username) async {
    await newsletterEmailsRef.document(userId).setData({
      'email': email,
      'username': username,
      'timestamp': FieldValue.serverTimestamp()
    });
  }

  static makeUserOnline() async {
    await usersRef
        .document(Constants.currentUserID)
        .updateData({'online': 'online'});
  }

  static makeUserOffline() async {
    await usersRef
        .document(Constants.currentUserID)
        .updateData({'online': FieldValue.serverTimestamp()});
  }

  static removeNotification(
      String receiverId, String objectId, String type) async {
    QuerySnapshot snapshot = await usersRef
        .document(receiverId)
        .collection('notifications')
        .where('sender', isEqualTo: Constants.currentUserID)
        .where('type', isEqualTo: type)
        .where('object_id', isEqualTo: objectId)
        .getDocuments();

    if (snapshot.documents.length > 0) {
      await usersRef
          .document(receiverId)
          .collection('notifications')
          .document(snapshot.documents[0].documentID)
          .delete();

      await usersRef
          .document(receiverId)
          .updateData({'notificationsNumber': FieldValue.increment(-1)});
    }
  }
}
