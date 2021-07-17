import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:glitcher/models/hashtag_model.dart';
import 'package:glitcher/models/notification_model.dart';
import 'package:glitcher/models/user_model.dart' as user;
import 'package:glitcher/screens/chats/chats.dart';
import 'package:stack/stack.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Firebase Constants
final firebaseAuth = FirebaseAuth.instance;
final firestore = FirebaseFirestore.instance;
final storageRef = FirebaseStorage.instance.ref();
final postsRef = firestore.collection('posts');
final usersRef = firestore.collection('users');
final reportsRef = firestore.collection('reports');
final suggestionsRef = firestore.collection('suggestions');
final chatsRef = firestore.collection('chats');
final gamesRef = firestore.collection('games');
final hashtagsRef = firestore.collection('hashtags');
final chatGroupsRef = firestore.collection('chat_groups');
final newsletterEmailsRef = firestore.collection('newsletter_emails');
final appName = 'glitcher';
String appTempDirectoryPath;

/// User Authentication Constants
enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
}
AuthStatus authStatus = AuthStatus.NOT_DETERMINED;

/// Logged In User Constants
String loggedInProfileImageURL; // TODO: Assign Default image url

/// App Theme Constants

class Constants {
  static User currentFirebaseUser;
  static String currentUserID;
  static user.User currentUser;
  //static List<String> games = [];
  static const genres = ['Action', 'Sports', 'Racing', 'Fighting'];
  static var isDarkTheme = true;
  static int favouriteFilter;

  static List<String> followingIds = [];
  static List<String> followedGamesNames = [];
  static List<user.User> userFriends = []; //mentioning has to be searched

  static List<Hashtag> hashtags = [];
  static List<Notification> unseenNotifications = [];

  static ConnectivityResult connectionState;
  static String country;

  static Stack<String> routesStack = Stack();

  //YoutubeControllers
  static Map<String, YoutubePlayerController> youtubeControllers = {};

  //screens
  static Chats chats = Chats();

  static int endPositionOffsetInMilliSeconds = 600;
}
