import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:glitcher/models/game_model.dart';
import 'package:glitcher/models/user_model.dart';

final auth = FirebaseAuth.instance;
final firestore = Firestore.instance;
final storageRef = FirebaseStorage.instance.ref();
final postsRef = firestore.collection('posts');
final usersRef = firestore.collection('users');
final chatsRef = firestore.collection('chats');
final gamesRef = firestore.collection('games');

enum AvailableThemes {
  LIGHT_THEME,
  DARK_THEME,
}
var currentTheme = AvailableThemes.DARK_THEME;

enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
}
AuthStatus authStatus = AuthStatus.NOT_DETERMINED;

final double inlineBreak = 32.0;

class Constants {
  static FirebaseUser currentUser;
  static String currentUserID;
  static User loggedInUser;
  static List<String> games = [];
  static const genres = [
    'Action',
    'Sports',
    'Racing',
    'Fighting'
  ];

  //Colors for theme
  static Color lightPrimary = Color(0xffdbd8e3);
  static const Color darkPrimary = Color(0xffca3e47);
  static Color darkPrimarySwatch = Colors.indigo;
  static Color lightAccent = Color(0xff065471);
  static Color darkAccent = Color(0xff393e46);
  static Color lightBG = Color(0xffeeeeee);
  static Color darkBG = Color(0xff222831);
  static Color badgeColor = Colors.red;
  static Color lightLineBreak = Colors.grey[300];
  static Color darkLineBreak = Colors.grey[900];
  static Color lightInLineBreak = Colors.blueGrey[200];

  static ThemeData lightTheme = ThemeData(
    backgroundColor: lightBG,
    primaryColor: lightPrimary,
    accentColor: lightAccent,
    cursorColor: lightAccent,
    scaffoldBackgroundColor: lightBG,
    appBarTheme: AppBarTheme(
      elevation: 0,
      textTheme: TextTheme(
        title: TextStyle(
          color: darkBG,
          fontSize: 18.0,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    backgroundColor: darkBG,
    primaryColor: darkPrimary,
    primarySwatch: darkPrimarySwatch,
    accentColor: darkAccent,
    scaffoldBackgroundColor: darkBG,
    cursorColor: darkAccent,
    appBarTheme: AppBarTheme(
      elevation: 0,
      textTheme: TextTheme(
        title: TextStyle(
          color: lightBG,
          fontSize: 18.0,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}
