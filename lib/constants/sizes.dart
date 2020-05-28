import 'package:flutter/material.dart';

class Sizes {
  /// User Profile Sizes
  static const double sm_profile_image_w = 50.0;
  static const double sm_profile_image_h = 50.0;
  static const double md_profile_image_w = 60.0;
  static const double md_profile_image_h = 60.0;
  static const double lg_profile_image_w = 120.0;
  static const double lg_profile_image_h = 120.0;

  /// HomeScreen Sizes
  static const double home_post_image_w = double.infinity;
  static const double home_post_image_h = 200.0;

  /// UI Card Sizes
  static const double card_btn_size = 25.0;
  static const double inline_break = 32.0;

  /// AppBar Box Shadow Sizes
  static const double appbar_blur_radius = 1.0;
  static const double appbar_spread_radius = 0;
  static const double appbar_offset_h = 1.0; // horizontal offest
  static const double appbar_offset_v = 1.0;

  static const int maxPostChars = 289; // vertical   offset

  static double fullWidth(BuildContext context) {
    // print(MediaQuery.of(context).size.width.toString());
    return MediaQuery.of(context).size.width;
  }

  static double fullHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}
