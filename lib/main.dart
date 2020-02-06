import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:glitcher/constants/strings.dart';
import 'dart:ui' as ui;
import 'package:glitcher/root_page.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/services/auth_provider.dart';
import 'package:glitcher/services/route_generator.dart';
import 'package:glitcher/utils/constants.dart';
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
      child: DynamicTheme(
          defaultBrightness: Brightness.dark,
          data: (brightness) => Constants.darkTheme,
          themedWidgetBuilder: (context, theme) {
            return MaterialApp(
              title: Strings.appName,
              debugShowCheckedModeBanner: false,
              theme: theme,
              initialRoute: '/',
              onGenerateRoute: RouteGenerator.generateRoute,
            );
          }),
    );
  }
}
