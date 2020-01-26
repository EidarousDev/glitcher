import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:glitcher/constants/strings.dart';
import 'dart:ui' as ui;
import 'package:glitcher/root_page.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/services/auth_provider.dart';
import 'package:glitcher/services/route_generator.dart';
import 'package:glitcher/utils/lifecycle_manager.dart';

void main() {
  RenderErrorBox.backgroundColor = Colors.transparent;
  RenderErrorBox.textStyle = ui.TextStyle(color: Colors.transparent);
  runApp(MyApp());
}

Future<void> retrieveDynamicLink(BuildContext context) async {
  final PendingDynamicLinkData data =
      await FirebaseDynamicLinks.instance.getInitialLink();
  final Uri deepLink = data?.link;

  if (deepLink != null) {
    Navigator.pushNamed(context, deepLink.path);
    return deepLink.toString();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    retrieveDynamicLink(context);
    return AuthProvider(
      auth: Auth(),
      child: MaterialApp(
        title: Strings.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            primaryColor: Color(0xffffffff),
            primaryColorDark: Colors.white70,
            accentColor: Color(0xff1CA1F1),
            iconTheme: IconThemeData(color: Color(0xff1CA1F1))),
        initialRoute: '/',
        onGenerateRoute: RouteGenerator.generateRoute,
      ),
    );
//    return LifecycleManager(
//      child: MaterialApp(
//          title: 'Glitcher',
//          debugShowCheckedModeBanner: false,
//          theme: ThemeData(
//              primaryColor: Color(0xffffffff),
//              primaryColorDark: Colors.white70,
//              accentColor: Color(0xff1CA1F1),
//              iconTheme: IconThemeData(color: Color(0xff1CA1F1))),
//          home: new RootPage(auth: new Auth())),
//    );
  }
}
