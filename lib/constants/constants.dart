import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:glitcher/models/hashtag_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/widgets/custom_loader.dart';

/// Firebase Constants
final auth = FirebaseAuth.instance;
final firestore = Firestore.instance;
final storageRef = FirebaseStorage.instance.ref();
final postsRef = firestore.collection('posts');
final usersRef = firestore.collection('users');
final chatsRef = firestore.collection('chats');
final gamesRef = firestore.collection('games');
final hashtagsRef = firestore.collection('hashtags');
final chatGroupsRef = firestore.collection('chat_groups');
final glitcherLoader = CustomLoader();

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
  static FirebaseUser currentUser;
  static String currentUserID;
  static User loggedInUser;
  static List<String> games = [];
  static const genres = ['Action', 'Sports', 'Racing', 'Fighting'];
  static var currentTheme = AvailableThemes.DARK_THEME;
  static int favouriteFilter;
  static List<String> followingIds = [];
  static List<String> followedGamesNames = [];

  static List<User> userFriends = [];
  static List<User> userFollowing = [];
  static List<User> userFollowers = [];
  static List<Hashtag> hashtags = [];

  static ConnectivityResult connectionState;
  static String country;
}
