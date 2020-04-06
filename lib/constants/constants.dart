import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:glitcher/models/user_model.dart';

/// Firebase Constants
final auth = FirebaseAuth.instance;
final firestore = Firestore.instance;
final storageRef = FirebaseStorage.instance.ref();
final postsRef = firestore.collection('posts');
final usersRef = firestore.collection('users');
final chatsRef = firestore.collection('chats');
final gamesRef = firestore.collection('games');
final chatGroupsRef = firestore.collection('chat_groups');

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
var currentTheme = AvailableThemes.DARK_THEME;

class Constants {
  static FirebaseUser currentUser;
  static String currentUserID;
  static User loggedInUser;
  static List<String> games = [];
  static const genres = ['Action', 'Sports', 'Racing', 'Fighting'];

  static List<String> followingIds = [];
  static List<String> followedGamesNames = [];

  static List<String> userFriends = [
    'DevGamer',
    'DevTester'
  ]; // ToDo: Get Dynamic User Friends to use it in the mention
}
