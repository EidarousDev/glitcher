import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/utils/functions.dart';

Widget gradientAppBar() {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: currentTheme == AvailableThemes.LIGHT_THEME
              ? <Color>[MyColors.lightCardBG, MyColors.lightBG]
              : <Color>[MyColors.darkCardBG, MyColors.darkBG]),
      boxShadow: [
        BoxShadow(
          color: switchColor(MyColors.lightPrimary, MyColors.darkBG),
          blurRadius: 1.0, // has the effect of softening the shadow
          spreadRadius: 0, // has the effect of extending the shadow
          offset: Offset(
            1.0, // horizontal, move right 10
            1.0, // vertical, move down 10
          ),
        )
      ],
    ),
  );
}
