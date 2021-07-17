import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
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
import 'package:glitcher/utils/app_util.dart';
import 'package:glitcher/utils/functions.dart';

import 'sqlite_service.dart';

class DatabaseService {
  // This function is used to get the recent posts (unfiltered)
  static Future<List<Post>> getPosts() async {
    QuerySnapshot postSnapshot =
        await postsRef.orderBy('timestamp', descending: true).limit(20).get();
    List<Post> posts =
        postSnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  //Gets the posts of a certain user
  static Future<List<Post>> getUserPosts(String authorId) async {
    QuerySnapshot postSnapshot = await postsRef
        .where('author', isEqualTo: authorId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();
    List<Post> posts =
        postSnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  static updateUserCountry() async {
    usersRef
        .doc(Constants.currentUserID)
        .update({'country': Constants.country});
  }

  // This function is used to get the recent posts of a certain user
  static Future<List<Post>> getNextUserPosts(
      String authorId, Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot postSnapshot = await postsRef
        .where('author', isEqualTo: authorId)
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .get();
    List<Post> posts =
        postSnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  static Future<Post> getUserLastPost(String authorId) async {
    QuerySnapshot postSnapshot = await postsRef
        .where('author', isEqualTo: authorId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    List<Post> posts =
        postSnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();

    if (posts == null || posts.isEmpty) {
      return null;
    } else {
      return posts[0];
    }
  }

  /// Check Username availability
  static Future<bool> isUsernameTaken(String name) async {
    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: name)
        .limit(1)
        .get();
    return result.docs.isEmpty;
  }

  // Get Post info of a specific post
  static Future<Post> getPostWithId(String postId) async {
    DocumentSnapshot postDocSnapshot = await postsRef.doc(postId).get();
    if (postDocSnapshot.exists) {
      return Post.fromDoc(postDocSnapshot);
    }
    return Post();
  }

  // Get Post Meta Info of a specific post
  static Future<Map> getPostMeta(String postId) async {
    var postMeta = Map();
    DocumentSnapshot postDocSnapshot = await postsRef.doc(postId).get();
    if (postDocSnapshot.exists) {
      postMeta['likes'] = postDocSnapshot['likes'];
      postMeta['dislikes'] = postDocSnapshot['dislikes'];
      postMeta['comments'] = postDocSnapshot['comments'];
    }
    return postMeta;
  }

  // Get Post Meta Info of a specific post
  static Future<Map> getCommentMeta(String postId, String commentId) async {
    var commentMeta = Map();
    DocumentSnapshot commentDocSnapshot =
        await postsRef.doc(postId).collection('comments').doc(commentId).get();

    if (commentDocSnapshot.exists) {
      commentMeta['likes'] = commentDocSnapshot['likes'];
      commentMeta['dislikes'] = commentDocSnapshot['dislikes'];
      commentMeta['replies'] = commentDocSnapshot['replies'];
    }
    return commentMeta;
  }

  static Future<Map> getReplyMeta(
      String postId, String commentId, String replyId) async {
    var replyMeta = Map();
    DocumentSnapshot replyDocSnapshot = await postsRef
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc(replyId)
        .get();

    if (replyDocSnapshot.exists) {
      replyMeta['likes'] = replyDocSnapshot['likes'];
      replyMeta['dislikes'] = replyDocSnapshot['dislikes'];
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
        .get();
    List<Post> posts =
        postSnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
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
        .get();
    List<Post> posts =
        postSnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  static deletePost(String postId) async {
    print('deleting post...');

    CollectionReference commentsRef =
        postsRef.doc(postId).collection('comments');

    CollectionReference likesRef = postsRef.doc(postId).collection('likes');

    CollectionReference dislikesRef =
        postsRef.doc(postId).collection('dislikes');

    (await commentsRef.get()).docs.forEach((comment) async {
      (await commentsRef.doc(comment.id).collection('replies').get())
          .docs
          .forEach((reply) async {
        (await commentsRef
                .doc(comment.id)
                .collection('replies')
                .doc(reply.id)
                .collection('likes')
                .get())
            .docs
            .forEach((replyLike) {
          commentsRef
              .doc(comment.id)
              .collection('replies')
              .doc(reply.id)
              .collection('likes')
              .doc(replyLike.id)
              .delete();
        });

        (await commentsRef
                .doc(comment.id)
                .collection('replies')
                .doc(reply.id)
                .collection('dislikes')
                .get())
            .docs
            .forEach((replyDislike) {
          commentsRef
              .doc(comment.id)
              .collection('replies')
              .doc(reply.id)
              .collection('dislikes')
              .doc(replyDislike.id)
              .delete();
        });

        commentsRef
            .doc(comment.id)
            .collection('replies')
            .doc(reply.id)
            .delete();
      });

      (await commentsRef.doc(comment.id).collection('likes').get())
          .docs
          .forEach((commentLike) async {
        await commentsRef
            .doc(comment.id)
            .collection('likes')
            .doc(commentLike.id)
            .delete();
      });

      (await commentsRef.doc(comment.id).collection('dislikes').get())
          .docs
          .forEach((commentDislike) async {
        await commentsRef
            .doc(comment.id)
            .collection('dislikes')
            .doc(commentDislike.id)
            .delete();
      });

      await commentsRef.doc(comment.id).delete();
    });

    (await likesRef.get()).docs.forEach((like) async {
      await likesRef.doc(like.id).delete();
    });

    (await dislikesRef.get()).docs.forEach((dislike) async {
      await dislikesRef.doc(dislike.id).delete();
    });

    await postsRef.doc(postId).delete();
  }

  static deleteComment(
      String postId, String commentId, String parentCommentId) async {
    if (parentCommentId == null) {
      DocumentReference commentRef =
          postsRef.doc(postId).collection('comments').doc(commentId);
      (await commentRef.collection('replies').get())
          .docs
          .forEach((reply) async {
        (await commentRef
                .collection('replies')
                .doc(reply.id)
                .collection('likes')
                .get())
            .docs
            .forEach((replyLike) {
          commentRef
              .collection('replies')
              .doc(reply.id)
              .collection('likes')
              .doc(replyLike.id)
              .delete();
        });

        (await commentRef
                .collection('replies')
                .doc(reply.id)
                .collection('dislikes')
                .get())
            .docs
            .forEach((replyDislike) {
          commentRef
              .collection('replies')
              .doc(reply.id)
              .collection('dislikes')
              .doc(replyDislike.id)
              .delete();
        });

        commentRef.collection('replies').doc(reply.id).delete();
      });

      (await commentRef.collection('likes').get())
          .docs
          .forEach((commentLike) async {
        await commentRef.collection('likes').doc(commentLike.id).delete();
      });

      (await commentRef.collection('dislikes').get())
          .docs
          .forEach((commentDislike) async {
        await commentRef.collection('dislikes').doc(commentDislike.id).delete();
      });

      await commentRef.delete();

      await postsRef.doc(postId).update({'comments': FieldValue.increment(-1)});
    } else {
      DocumentReference replyRef = postsRef
          .doc(postId)
          .collection('comments')
          .doc(parentCommentId)
          .collection('replies')
          .doc(commentId);

      (await replyRef.collection('likes').get()).docs.forEach((replyLike) {
        replyRef.collection('likes').doc(replyLike.id).delete();
      });

      (await replyRef.collection('dislikes').get())
          .docs
          .forEach((replyDislike) {
        replyRef.collection('dislikes').doc(replyDislike.id).delete();
      });

      replyRef.delete();

      await postsRef
          .doc(postId)
          .collection('comments')
          .doc(parentCommentId)
          .update({'replies': FieldValue.increment(-1)});
    }
  }

  // This function is used to get the recent posts (filtered by followed games)
  static Future<List<Post>> getNextPostsFilteredByFollowedGames(
      Timestamp lastVisiblePostSnapShot) async {
    List list = List();
    if (Constants.followedGamesNames.length > 10) {
      list = AppUtil.randomIndices(Constants.followedGamesNames);
    } else {
      list = Constants.followedGamesNames;
    }

    QuerySnapshot postSnapshot = await postsRef
        .where('game', whereIn: list)
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .get();
    List<Post> posts =
        postSnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  // This function is used to get the recent posts (filtered by followed gamers)
  static Future<List<Post>> getNextPostsFilteredByFollowing(
      Timestamp lastVisiblePostSnapShot) async {
    List list = List();
    if (Constants.followingIds.length > 10) {
      list = AppUtil.randomIndices(Constants.followingIds);
    } else {
      list = Constants.followedGamesNames;
    }

    QuerySnapshot postSnapshot = await postsRef
        .where('author', whereIn: list)
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .get();
    List<Post> posts =
        postSnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  static getAllMyFriends() async {
    List<User> friends = await UserSqlite.getByCategory('friends');
    if (friends == null || friends.length != Constants.currentUser.friends) {
      QuerySnapshot friendsSnapshot = await usersRef
          .doc(Constants.currentUserID)
          .collection('friends')
          .get();

      friends = friendsSnapshot.docs.map((doc) => User.fromDoc(doc)).toList();

      for (int i = 0; i < friends.length; i++) {
        User user = await DatabaseService.getUserWithId(friends[i].id,
            checkLocal: false);
        friends[i] = user;

        user.isFriend = 1;
        User localUser = await UserSqlite.getUserWithId(user.id);
        if (localUser == null) {
          int success = await UserSqlite.insert(user);
        } else {
          user.isFollower = localUser.isFollower;
          user.isFollowing = localUser.isFollowing;
          int success = await UserSqlite.update(user);
        }
      }
    }
    Constants.userFriends = friends;
    return friends;
  }

  static getAllMyFollowing() async {
    List<User> following = await UserSqlite.getByCategory('following');
    if (following == null ||
        following.length != Constants.currentUser.following) {
      QuerySnapshot followingSnapshot = await usersRef
          .doc(Constants.currentUserID)
          .collection('following')
          .get();

      following =
          followingSnapshot.docs.map((doc) => User.fromDoc(doc)).toList();

      Constants.followingIds = [];

      for (int i = 0; i < following.length; i++) {
        User user = await DatabaseService.getUserWithId(following[i].id,
            checkLocal: false);
        following[i] = user;

        user.isFollowing = 1;
        User localUser = await UserSqlite.getUserWithId(user.id);
        if (localUser == null) {
          int success = await UserSqlite.insert(user);
        } else {
          user.isFollower = localUser.isFollower;
          user.isFriend = localUser.isFriend;
          int success = await UserSqlite.update(user);
        }

        Constants.followingIds.add(following[i].id);
      }
    } else {
      Constants.followingIds = [];
      for (int i = 0; i < following.length; i++) {
        Constants.followingIds.add(following[i].id);
      }
    }
    return following;
  }

  static getAllMyFollowers() async {
    List<User> followers = await UserSqlite.getByCategory('followers');
    if (followers == null ||
        followers.length != Constants.currentUser.followers) {
      QuerySnapshot followersSnapshot = await usersRef
          .doc(Constants.currentUserID)
          .collection('followers')
          .get();

      followers =
          followersSnapshot.docs.map((doc) => User.fromDoc(doc)).toList();

      for (int i = 0; i < followers.length; i++) {
        User user = await DatabaseService.getUserWithId(followers[i].id,
            checkLocal: false);
        followers[i] = user;

        user.isFollower = 1;
        User localUser = await UserSqlite.getUserWithId(user.id);
        if (localUser == null) {
          int success = await UserSqlite.insert(user);
        } else {
          user.isFriend = localUser.isFriend;
          user.isFollowing = localUser.isFollowing;
          int success = await UserSqlite.update(user);
        }
      }
    }

    return followers;
  }

  static getAllFollowedGames(String userId) async {
    QuerySnapshot followedGamesSnapshot =
        await usersRef.doc(userId).collection('followedGames').get();

    List<Game> followedGames = [];
    Constants.followedGamesNames = [];

    for (DocumentSnapshot doc in followedGamesSnapshot.docs) {
      Game game = await getGameWithId(doc.id);
      followedGames.add(game);
      if (userId == Constants.currentUserID) {
        Constants.followedGamesNames.add(game.fullName);
      }
    }

    return followedGames;
  }

  static getAllFriends(String userId) async {
    QuerySnapshot friendsSnapshot =
        await usersRef.doc(userId).collection('friends').get();

    List<User> friends =
        friendsSnapshot.docs.map((doc) => User.fromDoc(doc)).toList();

    for (int i = 0; i < friends.length; i++) {
      friends[i] =
          await DatabaseService.getUserWithId(friends[i].id, checkLocal: false);
    }

    return friends;
  }

  static getAllFollowing(String userId) async {
    QuerySnapshot followingSnapshot =
        await usersRef.doc(userId).collection('following').get();

    List<User> following =
        followingSnapshot.docs.map((doc) => User.fromDoc(doc)).toList();

    for (int i = 0; i < following.length; i++) {
      following[i] = await DatabaseService.getUserWithId(following[i].id,
          checkLocal: false);
    }

    return following;
  }

  static getAllFollowers(String userId) async {
    QuerySnapshot followersSnapshot =
        await usersRef.doc(userId).collection('followers').get();

    List<User> followers =
        followersSnapshot.docs.map((doc) => User.fromDoc(doc)).toList();

    for (int i = 0; i < followers.length; i++) {
      followers[i] = await DatabaseService.getUserWithId(followers[i].id,
          checkLocal: false);
    }

    return followers;
  }

  // This function is used to get the recent posts (filtered by a certain game)
  static Future<List<Post>> getGamePosts(String gameName) async {
    QuerySnapshot postSnapshot = await postsRef
        .where('game', isEqualTo: gameName)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();
    List<Post> posts =
        postSnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
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
        .get();
    List<Post> posts =
        postSnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  static Future<List<Post>> getPostsFilteredByFollowedGames() async {
    List list = List();
    if (Constants.followedGamesNames.length > 10) {
      list = AppUtil.randomIndices(Constants.followedGamesNames);
    } else {
      list = Constants.followedGamesNames;
    }
    QuerySnapshot postSnapshot = await postsRef
        .where('game', whereIn: list)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();
    List<Post> posts =
        postSnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  static Future<List<Post>> getPostsFilteredByFollowing() async {
    List list = List();
    if (Constants.followingIds.length > 10) {
      list = AppUtil.randomIndices(Constants.followingIds);
    } else {
      list = Constants.followingIds;
    }
    QuerySnapshot postSnapshot = await postsRef
        .where('author', whereIn: list)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();
    List<Post> posts =
        postSnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
    return posts;
  }

  static Future<List<notification.Notification>> getNotifications() async {
    QuerySnapshot notificationSnapshot = await usersRef
        .doc(Constants.currentUserID)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();
    List<notification.Notification> notifications = notificationSnapshot.docs
        .map((doc) => notification.Notification.fromDoc(doc))
        .toList();
    return notifications;
  }

  static Future<List<notification.Notification>> getNextNotifications(
      Timestamp lastVisibleNotificationSnapShot) async {
    QuerySnapshot notificationSnapshot = await usersRef
        .doc(Constants.currentUserID)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisibleNotificationSnapShot])
        .limit(20)
        .get();
    List<notification.Notification> notifications = notificationSnapshot.docs
        .map((doc) => notification.Notification.fromDoc(doc))
        .toList();
    return notifications;
  }

  // This function is used to get the author info of each post
  static Future<User> getUserWithId(String userId,
      {@required bool checkLocal}) async {
    if (checkLocal) {
      User user = await UserSqlite.getUserWithId(userId);
      if (user != null) {
        return user;
      }
    }
    DocumentSnapshot userDocSnapshot = await usersRef?.doc(userId)?.get();
    if (userDocSnapshot.exists) {
      return User.fromDoc(userDocSnapshot);
    }
    return User();
  }

  static Future<User> getUserWithEmail(String email) async {
    QuerySnapshot userDocSnapshot =
        await usersRef.where('email', isEqualTo: email).get();
    if (userDocSnapshot.docs.length != 0) {
      return User.fromDoc(userDocSnapshot.docs[0]);
    }
    return User();
  }

  static Future<User> getUserWithUsername(String username) async {
    QuerySnapshot userDocSnapshot =
        await usersRef.where('username', isEqualTo: username).get();
    User user =
        userDocSnapshot.docs.map((doc) => User.fromDoc(doc)).toList()[0];

    return user;
  }

  static Future<List<String>> getGroups() async {
    QuerySnapshot snapshot = await usersRef
        .doc(Constants.currentUserID)
        .collection('chat_groups')
        .get();

    List<String> groups = [];

    snapshot.docs.forEach((f) {
      groups.add(f.id);
    });

    return groups;
  }

  static Future<Group> getGroupWithId(String groupId) async {
    DocumentSnapshot groupDocSnapshot = await chatGroupsRef.doc(groupId).get();
    if (groupDocSnapshot.exists) {
      return Group.fromDoc(groupDocSnapshot);
    }
    return Group();
  }

  static sendGroupMessage(String groupId, String type, String message) async {
    await chatGroupsRef.doc(groupId).collection('messages').add({
      'sender': Constants.currentUserID,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type
    });
  }

  static sendMessage(String otherUserId, String type, String message) async {
    await chatsRef
        .doc(Constants.currentUserID)
        .collection('conversations')
        .doc(otherUserId)
        .collection('messages')
        .add({
      'sender': Constants.currentUserID,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type
    });

    await chatsRef
        .doc(otherUserId)
        .collection('conversations')
        .doc(Constants.currentUserID)
        .collection('messages')
        .add({
      'sender': Constants.currentUserID,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type
    });
  }

  // This function is used to get the recent messages (unfiltered)
  static Future<List<Message>> getMessages(String otherUserId) async {
    QuerySnapshot msgSnapshot = await chatsRef
        .doc(Constants.currentUserID)
        .collection('conversations')
        .doc(otherUserId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();
    List<Message> messages =
        msgSnapshot.docs.map((doc) => Message.fromDoc(doc)).toList();
    return messages;
  }

  static getLastMessage(String otherUserId) async {
    QuerySnapshot msgSnapshot = await chatsRef
        .doc(Constants.currentUserID)
        .collection('conversations')
        .doc(otherUserId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    List<Message> messages =
        msgSnapshot.docs.map((doc) => Message.fromDoc(doc)).toList();
    if (messages.length == 0)
      return Message(
          message: 'Say hi to your new friend!',
          type: 'text',
          sender: otherUserId,
          timestamp: null);
    return messages[0];
  }

  static Future<List<Message>> getGroupMessages(String groupId) async {
    QuerySnapshot msgSnapshot = await chatGroupsRef
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();
    List<Message> messages =
        msgSnapshot.docs.map((doc) => Message.fromDoc(doc)).toList();
    return messages;
  }

  static Future<List<Message>> getPrevMessages(
      Timestamp firstVisibleGameSnapShot, String otherUserId) async {
    QuerySnapshot msgSnapshot = await chatsRef
        .doc(Constants.currentUserID)
        .collection('conversations')
        .doc(otherUserId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfter([firstVisibleGameSnapShot])
        .limit(20)
        .get();
    List<Message> messages =
        msgSnapshot.docs.map((doc) => Message.fromDoc(doc)).toList();
    return messages;
  }

  static Future<List<Message>> getPrevGroupMessages(
      Timestamp firstVisibleGameSnapShot, String groupId) async {
    QuerySnapshot msgSnapshot = await chatGroupsRef
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfter([firstVisibleGameSnapShot])
        .limit(20)
        .get();
    List<Message> messages =
        msgSnapshot.docs.map((doc) => Message.fromDoc(doc)).toList();
    return messages;
  }

  /// To remove a user from a group or to exit a group
  static removeGroupMember(String groupId, String memberId) async {
    await chatGroupsRef.doc(groupId).collection('users').doc(memberId).delete();

    await usersRef
        .doc(memberId)
        .collection('chat_groups')
        .doc(groupId)
        .delete();
  }

  static Future<List<String>> getGroupMembersIds(String groupId) async {
    QuerySnapshot members =
        await chatGroupsRef.doc(groupId).collection('users').get();
    List<String> ids = [];
    members.docs.forEach((doc) {
      ids.add(doc.id);
    });

    return ids;
  }

  static addMemberToGroup(String groupId, String memberId) async {
    await chatGroupsRef
        .doc(groupId)
        .collection('users')
        .doc(memberId)
        .set({'is_admin': false, 'timestamp': FieldValue.serverTimestamp()});

    await usersRef
        .doc(memberId)
        .collection('chat_groups')
        .doc(groupId)
        .set({'timestamp': FieldValue.serverTimestamp()});
  }

  static toggleMemberAdmin(String groupId, String memberId) async {
    DocumentSnapshot doc = await chatGroupsRef
        .doc(groupId)
        .collection('users')
        .doc(memberId)
        .get();

    await doc.reference.update({
      'is_admin': !doc['is_admin'],
      'timestamp': FieldValue.serverTimestamp()
    });
  }

  // Get Comments of a specific post
  static Future<List<Comment>> getComments(String postId) async {
    QuerySnapshot commentSnapshot = await postsRef
        .doc(postId)
        .collection('comments')
        ?.orderBy('timestamp', descending: true)
        ?.limit(20)
        ?.get();
    List<Comment> comments =
        commentSnapshot.docs.map((doc) => Comment.fromDoc(doc)).toList();
    return comments;
  }

  static Future<List<Comment>> getNextComments(
      String postId, Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot commentSnapshot = await postsRef
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .get();
    List<Comment> comments =
        commentSnapshot.docs.map((doc) => Comment.fromDoc(doc)).toList();
    return comments;
  }

  static Future<List<Comment>> getCommentReplies(
      String postId, String commentId) async {
    QuerySnapshot commentSnapshot = await postsRef
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        ?.orderBy('timestamp', descending: true)
        ?.limit(20)
        ?.get();
    List<Comment> comments =
        commentSnapshot.docs.map((doc) => Comment.fromDoc(doc)).toList();
    return comments;
  }

  // This function is used to get the author info of each post
  static Future<Game> getGameWithId(String gameId) async {
    DocumentSnapshot gameDocSnapshot = await gamesRef.doc(gameId).get();
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
        .get();
    List<Game> games =
        gameSnapshot.docs.map((doc) => Game.fromDoc(doc)).toList();
    return games;
  }

//  static getGameNames() async {
//    Constants.games = [];
//    QuerySnapshot gameSnapshot =
//        await gamesRef.orderBy('fullName', descending: true).get();
//    List<Game> games =
//        gameSnapshot.docs.map((doc) => Game.fromDoc(doc)).toList();
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
        .get();
    List<Game> games =
        gameSnapshot.docs.map((doc) => Game.fromDoc(doc)).toList();
    return games;
  }

  static Future<List> searchGames(text) async {
    QuerySnapshot gameSnapshot = await gamesRef
        .where('search', arrayContains: text)
        .orderBy('fullName', descending: false)
        .limit(20)
        .get();
    List<Game> games =
        gameSnapshot.docs.map((doc) => Game.fromDoc(doc)).toList();
    return games;
  }

  static Future<List> nextSearchGames(
      String lastVisiblePostSnapShot, String text) async {
    QuerySnapshot gameSnapshot = await gamesRef
        .where('search', arrayContains: text)
        .orderBy('fullName', descending: false)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .get();
    List<Game> games =
        gameSnapshot.docs.map((doc) => Game.fromDoc(doc)).toList();
    return games;
  }

  static Future<List> searchUsers(text) async {
    QuerySnapshot usersSnapshot = await usersRef
        .where('search', arrayContains: text)
        .orderBy('username', descending: false)
        .limit(20)
        .get();
    List<User> users =
        usersSnapshot.docs.map((doc) => User.fromDoc(doc)).toList();
    return users;
  }

  static Future<List> nextSearchUsers(
      String lastVisiblePostSnapShot, String text) async {
    QuerySnapshot usersSnapshot = await usersRef
        .where('search', arrayContains: text)
        .orderBy('username', descending: false)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .get();
    List<User> users =
        usersSnapshot.docs.map((doc) => User.fromDoc(doc)).toList();
    return users;
  }

  // This function is used to submit/add a comment
  static void addComment(String postId, String commentText) async {
    await postsRef.doc(postId).collection('comments').add({
      'commenter': Constants.currentUserID,
      'text': commentText,
      'timestamp': FieldValue.serverTimestamp()
    });
    await postsRef.doc(postId).update({'comments': FieldValue.increment(1)});
  }

  static void editComment(
      String postId, String commentId, String commentText) async {
    await postsRef.doc(postId).collection('comments').doc(commentId).update(
        {'text': commentText, 'timestamp': FieldValue.serverTimestamp()});
  }

  static void addReply(
      String postId, String commentId, String replyText) async {
    await postsRef
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .add({
      'commenter': Constants.currentUserID,
      'text': replyText,
      'timestamp': FieldValue.serverTimestamp()
    });
    await postsRef
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({'replies': FieldValue.increment(1)});
  }

  static void editReply(
      String postId, String commentId, String replyId, String replyText) async {
    await postsRef
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc(replyId)
        .update({'text': replyText, 'timestamp': FieldValue.serverTimestamp()});
  }

  static followGame(String gameId) async {
    DocumentSnapshot gameDocSnapshot = await usersRef
        .doc(Constants.currentUserID)
        .collection('followedGames')
        .doc(gameId)
        .get();
    if (!gameDocSnapshot.exists) {
      await usersRef
          .doc(Constants.currentUserID)
          .collection('followedGames')
          .doc(gameId)
          .set({'followedAt': FieldValue.serverTimestamp()});
    }

    await usersRef
        .doc(Constants.currentUserID)
        .update({'followed_games': FieldValue.increment(1)});
  }

  static unFollowGame(String gameId) async {
    DocumentSnapshot gameDocSnapshot = await usersRef
        .doc(Constants.currentUserID)
        .collection('followedGames')
        .doc(gameId)
        .get();
    if (gameDocSnapshot.exists) {
      await usersRef
          .doc(Constants.currentUserID)
          .collection('followedGames')
          .doc(gameId)
          .delete();
    }

    await usersRef
        .doc(Constants.currentUserID)
        .update({'followed_games': FieldValue.increment(-1)});
  }

  static Future<Game> getGameWithGameName(String gameName) async {
    QuerySnapshot gameDocSnapshot =
        await gamesRef.where('fullName', isEqualTo: gameName).get();
    Game game =
        gameDocSnapshot.docs.map((doc) => Game.fromDoc(doc)).toList()[0];

    return game;
  }

  static getHashtags() async {
    QuerySnapshot hashtagsSnapshot = await hashtagsRef.get();

    List<Hashtag> hashtags =
        hashtagsSnapshot.docs.map((doc) => Hashtag.fromDoc(doc)).toList();

    return hashtags;
  }

  static Future<Hashtag> getHashtagWithText(String text) async {
    QuerySnapshot hashtagDocSnapshot =
        await hashtagsRef.where('text', isEqualTo: text).get();

    if (hashtagDocSnapshot.docs.length == 0) {
      return null;
    } else {
      Hashtag hashtag = hashtagDocSnapshot.docs
          .map((doc) => Hashtag.fromDoc(doc))
          .toList()[0];

      return hashtag;
    }
  }

  // This function is used to get the recent posts for a certain tag
  static Future<List<Post>> getHashtagPosts(String hashtagId) async {
    QuerySnapshot postSnapshot = await hashtagsRef
        .doc(hashtagId)
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();

    List<Post> posts = [];

    for (DocumentSnapshot doc in postSnapshot.docs) {
      DocumentSnapshot postDoc = await postsRef.doc(doc.id).get();

      if (postDoc.exists) {
        posts.add(await getPostWithId(doc.id));
      } else {
        hashtagsRef.doc(hashtagId).collection('posts').doc(doc.id).delete();
      }
    }

    return posts;
  }

  // This function is used to get the recent posts (filtered by a certain game)
  static Future<List<Post>> getNextHashtagPosts(
      Timestamp lastVisiblePostSnapShot, String hashtagId) async {
    QuerySnapshot postSnapshot = await hashtagsRef
        .doc(hashtagId)
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .get();

    List<Post> posts = [];

    for (DocumentSnapshot doc in postSnapshot.docs) {
      DocumentSnapshot postDoc = await postsRef.doc(doc.id).get();

      if (postDoc.exists) {
        posts.add(await getPostWithId(doc.id));
      } else {
        hashtagsRef.doc(hashtagId).collection('posts').doc(doc.id).delete();
      }
    }

    return posts;
  }

  static Future<List<Post>> getBookmarksPosts() async {
    QuerySnapshot postSnapshot = await usersRef
        .doc(Constants.currentUserID)
        .collection('bookmarks')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();

    List<Post> posts = [];

    for (DocumentSnapshot doc in postSnapshot.docs) {
      DocumentSnapshot postDoc = await postsRef.doc(doc.id).get();

      if (postDoc.exists) {
        Post post = await getPostWithId(doc.id);

        posts.add(post);
      } else {
        posts.add(Post(id: doc.id, authorId: 'deleted'));
//        usersRef
//            .doc(Constants.currentUserID)
//            .collection('bookmarks')
//            .doc(doc.id)
//            .delete();
      }
    }
    return posts;
  }

  static Future<List<Post>> getNextBookmarksPosts(
      Timestamp lastVisiblePostSnapShot) async {
    QuerySnapshot postsSnapshot = await usersRef
        .doc(Constants.currentUserID)
        .collection('bookmarks')
        .orderBy('timestamp', descending: true)
        .startAfter([lastVisiblePostSnapShot])
        .limit(20)
        .get();

    List<Post> posts = [];

    for (DocumentSnapshot doc in postsSnapshot.docs) {
      DocumentSnapshot postDoc = await postsRef.doc(doc.id).get();

      if (postDoc.exists) {
        posts.add(await getPostWithId(doc.id));
      } else {
        usersRef
            .doc(Constants.currentUserID)
            .collection('bookmarks')
            .doc(doc.id)
            .delete();
      }
    }

    return posts;
  }

  static addPostToBookmarks(String postId) async {
    await usersRef
        .doc(Constants.currentUserID)
        .collection('bookmarks')
        .doc(postId)
        .set({'timestamp': FieldValue.serverTimestamp()});
  }

  static removePostFromBookmarks(String postId) async {
    await usersRef
        .doc(Constants.currentUserID)
        .collection('bookmarks')
        .doc(postId)
        .delete();
  }

  static unfollowUser(String userId) async {
    await usersRef
        .doc(Constants.currentUserID)
        .collection('following')
        .doc(userId)
        .delete();

    await usersRef
        .doc(userId)
        .collection('followers')
        .doc(Constants.currentUserID)
        .delete();

    DocumentSnapshot doc = await usersRef
        .doc(Constants.currentUserID)
        .collection('friends')
        .doc(userId)
        .get();

    //Store/update user locally
    User user = await DatabaseService.getUserWithId(userId, checkLocal: false);
    user.isFollowing = 0;
    user.isFriend = 0;
    User localUser = await UserSqlite.getUserWithId(user.id);
    if (localUser == null) {
      int success = await UserSqlite.insert(user);
    } else {
      user.isFollower = localUser.isFollower;
      int success = await UserSqlite.update(user);
    }

    if (doc.exists) {
      await usersRef
          .doc(Constants.currentUserID)
          .collection('friends')
          .doc(userId)
          .delete();
    }

    DocumentSnapshot doc2 = await usersRef
        .doc(userId)
        .collection('friends')
        .doc(Constants.currentUserID)
        .get();

    if (doc2.exists) {
      await usersRef
          .doc(userId)
          .collection('friends')
          .doc(Constants.currentUserID)
          .delete();

      await usersRef
          .doc(Constants.currentUserID)
          .update({'friends': FieldValue.increment(-1)});

      await usersRef.doc(userId).update({'friends': FieldValue.increment(-1)});
    }

    await usersRef
        .doc(Constants.currentUserID)
        .update({'following': FieldValue.increment(-1)});

    await usersRef.doc(userId).update({'followers': FieldValue.increment(-1)});
  }

  static followUser(String userId) async {
    FieldValue timestamp = FieldValue.serverTimestamp();

    await usersRef
        .doc(userId)
        .collection('followers')
        .doc(Constants.currentUserID)
        .set({
      'timestamp': FieldValue.serverTimestamp(),
    });

    await usersRef
        .doc(Constants.currentUserID)
        .collection('following')
        .doc(userId)
        .set({
      'timestamp': timestamp,
    });

    DocumentSnapshot doc = await usersRef
        .doc(userId)
        .collection('following')
        .doc(Constants.currentUserID)
        .get();

    if (doc.exists) {
      await usersRef
          .doc(Constants.currentUserID)
          .collection('friends')
          .doc(userId)
          .set({'timestamp': FieldValue.serverTimestamp()});

      await usersRef
          .doc(userId)
          .collection('friends')
          .doc(Constants.currentUserID)
          .set({'timestamp': FieldValue.serverTimestamp()});

      await usersRef
          .doc(Constants.currentUserID)
          .update({'friends': FieldValue.increment(1)});

      await usersRef.doc(userId).update({'friends': FieldValue.increment(1)});

      //Store/update user locally as a friend
      User user =
          await DatabaseService.getUserWithId(userId, checkLocal: false);
      user.isFollowing = 1;
      user.isFriend = 1;
      user.isFollower = 1;
      User localUser = await UserSqlite.getUserWithId(user.id);
      if (localUser == null) {
        int success = await UserSqlite.insert(user);
      } else {
        int success = await UserSqlite.update(user);
      }

      NotificationHandler.sendNotification(
          userId,
          '${Constants.currentUser.username} followed you',
          'You are now friends',
          Constants.currentUserID,
          'follow');
    } else {
      //Store/update user locally as a following
      User user =
          await DatabaseService.getUserWithId(userId, checkLocal: false);
      user.isFollowing = 1;
      User localUser = await UserSqlite.getUserWithId(user.id);
      if (localUser == null) {
        int success = await UserSqlite.insert(user);
      } else {
        user.isFollower = localUser.isFollower;
        user.isFriend = localUser.isFriend;
        int success = await UserSqlite.update(user);
      }

      NotificationHandler.sendNotification(
          userId,
          '${Constants.currentUser.username} followed you',
          'Follow him back to be friends',
          Constants.currentUserID,
          'follow');
    }

    //Increment current user following and other user followers
    await usersRef
        .doc(Constants.currentUserID)
        .update({'following': FieldValue.increment(1)});

    await usersRef.doc(userId).update({'followers': FieldValue.increment(1)});
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

    await usersRef.doc(id).set(userMap);
  }

  static addUserEmailToNewsletter(
      String userId, String email, String username) async {
    await newsletterEmailsRef.doc(userId).set({
      'email': email,
      'username': username,
      'timestamp': FieldValue.serverTimestamp()
    });
  }

  static makeUserOnline() async {
    await usersRef.doc(Constants.currentUserID).update({'online': 'online'});
  }

  static makeUserOffline() async {
    await usersRef
        .doc(Constants.currentUserID)
        .update({'online': FieldValue.serverTimestamp()});
  }

  static removeNotification(
      String receiverId, String objectId, String type) async {
    QuerySnapshot snapshot = await usersRef
        .doc(receiverId)
        .collection('notifications')
        .where('sender', isEqualTo: Constants.currentUserID)
        .where('type', isEqualTo: type)
        .where('object_id', isEqualTo: objectId)
        .get();

    if (snapshot.docs.length > 0) {
      await usersRef
          .doc(receiverId)
          .collection('notifications')
          .doc(snapshot.docs[0].id)
          .delete();

      await usersRef
          .doc(receiverId)
          .update({'notificationsNumber': FieldValue.increment(-1)});
    }
  }
}
