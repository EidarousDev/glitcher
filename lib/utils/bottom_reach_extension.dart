import 'dart:async';

import 'package:flutter/material.dart';

extension BottomReachExtension on ScrollController {
  void onBottomReach(VoidCallback callback,
      {double sensitivity = 200.0, Duration throttleDuration}) {
    final duration = throttleDuration ?? Duration(milliseconds: 200);
    Timer timer;

    addListener(() {
      if (timer != null) {
        return;
      }

      // I used the timer to destroy the timer
      timer = Timer(duration, () => timer = null);

      // see Esteban Díaz answer
      final maxScroll = position.maxScrollExtent;
      final currentScroll = position.pixels;
      if (maxScroll - currentScroll <= sensitivity) {
        callback();
      }
    });
  }
}
