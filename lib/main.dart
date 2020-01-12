import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:glitcher/screens/root_page.dart';
import 'package:glitcher/utils/auth.dart';
import 'package:glitcher/utils/lifecycle_manager.dart';

void main() {
  RenderErrorBox.backgroundColor = Colors.transparent;
  RenderErrorBox.textStyle = ui.TextStyle(color: Colors.transparent);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LifecycleManager(
      child: MaterialApp(
          title: 'Glitcher',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
              primaryColor: Color(0xffffffff),
              primaryColorDark: Colors.white70,
              accentColor: Color(0xff1CA1F1),
              iconTheme: IconThemeData(color: Color(0xff1CA1F1))),
          home: new RootPage(auth: new Auth())),
    );
  }
}
