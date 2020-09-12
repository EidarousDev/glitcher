import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:glitcher/models/game_model.dart';
import 'package:glitcher/models/hashtag_model.dart';
import 'package:glitcher/models/notification_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/screens/chats/chats.dart';
import 'package:glitcher/widgets/custom_loader.dart';
import 'package:stack/stack.dart';

/// Firebase Constants
final firebaseAuth = FirebaseAuth.instance;
final firestore = Firestore.instance;
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
enum AvailableThemes {
  LIGHT_THEME,
  DARK_THEME,
}

class Constants {
  static FirebaseUser currentFirebaseUser;
  static String currentUserID;
  static User currentUser;
  //static List<String> games = [];
  static const genres = ['Action', 'Sports', 'Racing', 'Fighting'];
  static var currentTheme = AvailableThemes.DARK_THEME;
  static int favouriteFilter;
  static List<String> followingIds = [];
  static List<Game> followedGames = [];
  static List<String> followedGamesNames = [];

  static List<User> userFriends = [];
  static List<User> userFollowing = [];
  static List<User> userFollowers = [];
  static List<Hashtag> hashtags = [];
  static List<Notification> unseenNotifications = [];

  static ConnectivityResult connectionState;
  static String country;

  static Stack<String> routesStack = Stack();

  //screens
  static Chats chats = Chats();
}
