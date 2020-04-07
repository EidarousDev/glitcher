import 'dart:ui';

import 'package:flutter/material.dart';

class MyColors {
  /// Light Theme Colors
  //Colors for theme
  static Color lightPrimary = Color(0xffdbd8e3);
  static Color lightAccent = Color(0xff065471);
  static Color lightBG = Color(0xffeeeeee);
  static Color badgeColor = Colors.red;
  static Color lightLineBreak = Colors.grey[300];
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
    brightness: Brightness.dark,
    backgroundColor: darkBG,
    primaryColor: darkPrimary,
    primarySwatch: darkPrimarySwatch,
    accentColor: darkAccent,
    scaffoldBackgroundColor: darkCardBG,
    cursorColor: darkAccent,
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
