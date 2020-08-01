import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/services/auth_provider.dart';
import 'package:glitcher/utils/functions.dart';

import 'services/route_generator.dart';

void main() {
  /*RenderErrorBox.backgroundColor = Colors.transparent;
  RenderErrorBox.textStyle = ui.TextStyle(color: Colors.transparent);*/
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

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    retrieveDynamicLink(context);
    return AuthProvider(
      auth: Auth(),
      child: DynamicTheme(
          defaultBrightness:
              Constants.currentTheme == AvailableThemes.DARK_THEME
                  ? Brightness.dark
                  : Brightness.light,
          data: (brightness) =>
              Constants.currentTheme == AvailableThemes.DARK_THEME
                  ? MyColors.darkTheme
                  : MyColors.lightTheme,
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

  @override
  void initState() {
    getCurrentTheme();
    super.initState();
  }

  getCurrentTheme() async {
    String theme = await getTheme();
    print("Fucking theme :  $theme ");
    if (theme == "AvailableThemes.LIGHT_THEME") {
      //DynamicTheme.of(context).setThemeData(MyColors.lightTheme);
      setState(() {
        Constants.currentTheme = AvailableThemes.LIGHT_THEME;
      });
    } else {
      //DynamicTheme.of(context).setThemeData(MyColors.darkTheme);
      setState(() {
        Constants.currentTheme = AvailableThemes.DARK_THEME;
      });
    }
  }
}
