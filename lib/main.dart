import 'package:flutter/material.dart';
import 'package:glitcher/screens/root_page.dart';
import 'package:glitcher/utils/auth.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Glitcher',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            primaryColor: Color(0xffffffff),
            primaryColorDark: Colors.white70,
            accentColor: Color(0xff1CA1F1),
            iconTheme: IconThemeData(color: Color(0xff1CA1F1))),
            home: new RootPage(auth: new Auth()));
  }
}
