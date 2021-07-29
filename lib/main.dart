import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/models/app_model.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/services/auth_provider.dart';
import 'package:glitcher/style/dark_theme.dart';
import 'package:glitcher/style/light_theme.dart';
import 'package:provider/provider.dart';

import 'services/route_generator.dart';

void main() async{
  /*RenderErrorBox.backgroundColor = Colors.transparent;
  RenderErrorBox.textStyle = ui.TextStyle(color: Colors.transparent);*/
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
  AppModel _app;

  @override
  Widget build(BuildContext context) {
    retrieveDynamicLink(context);
    return ChangeNotifierProvider<AppModel>(
      create: (context) => _app,
      child: Consumer<AppModel>(
        builder: (context, value, child) {
          return AuthProvider(
            auth: Auth(),
            child: MaterialApp(
              title: Strings.appName,
              debugShowCheckedModeBanner: false,
              theme: getTheme(context),
              initialRoute: '/',
              onGenerateRoute: RouteGenerator.generateRoute,
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    _app = AppModel();
    super.initState();
  }

  /// Build the App Theme
  ThemeData getTheme(context) {
    var appModel = Provider.of<AppModel>(context);
    var isDarkTheme = appModel.darkTheme ?? true;

    var fontFamily = 'Roboto';

    if (isDarkTheme) {
      return buildDarkTheme('en', fontFamily).copyWith(
        primaryColor: MyColors.darkPrimary,
      );
    }
    return buildLightTheme('en', fontFamily).copyWith(
      primaryColor: MyColors.lightPrimary,
    );
  }
}
