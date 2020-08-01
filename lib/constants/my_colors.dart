import 'dart:ui';

import 'package:flutter/material.dart';

class MyColors {
  /// Light Theme Colors
  //Colors for theme
  static Color lightPrimary = Color(0xffc74f57);
  static Color lightPrimarySwatch = Colors.indigo;
  static Color lightAccent = Color(0xff393e46);
  static Color lightCardBG = Color(0xffe5e5e5);
  static Color lightBG = Color(0xffeeeeee);
  static Color badgeColor = Colors.red;
  static Color lightButtonsBackground = Colors.grey[300];
  static Color lightPrimaryTappedBtn = Color(0xff4b9fe3);
  static Color lightLineBreak = Color(0xffd5d5d5);
  static Color lightInLineBreak = Color(0xffe1e3e3);

  static ThemeData lightTheme = ThemeData(
    canvasColor: lightBG, // BottomNavigationBar & Drawer Colors
    brightness:
        Brightness.light, // This will make all text and icons colors white
    backgroundColor:
        lightCardBG, // the background color of the app if not Scaffold
    primaryColor: lightPrimary, // The AppBar background Color
    primarySwatch: lightPrimarySwatch,
    accentColor:
        lightPrimary, // The active/selected button of the bottomNavigationBar & the FAB color
    scaffoldBackgroundColor:
        lightCardBG, // The background color of the entire Scaffold Widget
    cursorColor: lightAccent,
    primaryIconTheme:
        IconThemeData(color: Colors.black87), // AppBar Icons Color
    iconTheme: IconThemeData(
        color: Colors
            .black54), // IconButtons inside the body of the app (i.e. like, dislike, comment, share, and arrow_down)
    accentIconTheme:
        IconThemeData(color: Colors.white70), // Text Color inside FAB

    appBarTheme: AppBarTheme(
      elevation: 0,
      textTheme: TextTheme(
        title: TextStyle(
          color: Colors.black54,
          fontSize: 18.0,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );

  /// Dark Theme Colors
  static const Color darkPrimary = Color(0xffc74f57);
  static Color darkPrimarySwatch = Colors.indigo;
  static Color darkGrey = Color(0xff878681);
  static Color darkPrimaryTappedBtn = Color(0xff88caff);
  static Color darkAccentTappedBtn = Color(0xffd78f94);
  static Color darkAccent = Color(0xff393e46);
  static Color darkBG = Color(0xff212832);
  static Color darkCardBG = Color(0xff222e3f);
  static Color darkLineBreak = darkBG;

  static ThemeData darkTheme = ThemeData(
    canvasColor: darkBG, // BottomNavigationBar & Drawer Colors
    brightness:
        Brightness.dark, // This will make all text and icons colors white
    backgroundColor:
        darkCardBG, // the background color of the app if not Scaffold
    primaryColor: darkPrimary, // The AppBar background Color
    primarySwatch: darkPrimarySwatch,
    accentColor:
        darkAccent, // The active/selected button of the bottomNavigationBar & the FAB color
    scaffoldBackgroundColor:
        darkCardBG, // The background color of the entire Scaffold Widget
    cursorColor: darkAccent,
    primaryIconTheme: IconThemeData(color: darkGrey), // AppBar Icons Color
    iconTheme: IconThemeData(
        color: Colors
            .white70), // IconButtons inside the body of the app (i.e. like, dislike, comment, share, and arrow_down)
    accentIconTheme: IconThemeData(color: darkGrey), // Text Color inside FAB

    appBarTheme: AppBarTheme(
      elevation: 0,
      textTheme: TextTheme(
        title: TextStyle(
          color: Colors.white,
          fontSize: 18.0,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );

  /// AppBar Gradient Colors
  static Color appBarGradientTopColor = darkBG;
  static Color appBarGradientBottomColor = darkCardBG;
  static Color boxShadowColor = darkBG;
}
