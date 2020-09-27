import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/screens/app_page.dart';
import 'package:glitcher/screens/welcome/login_page.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/functions.dart';

import 'models/post_model.dart';

class RootPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  bool emailVerified;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await authAssignment();
    Functions.getUserCountryInfo();
  }

  void _signedIn() {
    setState(() {
      authStatus = AuthStatus.LOGGED_IN;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  Widget buildWaitingScreen() {
    return Scaffold(
      body: Container(
        color: switchColor(Colors.white, MyColors.darkAccent),
        alignment: Alignment.center,
        child: Center(
            child: Image.asset(
          'assets/images/glitcher_loader.gif',
          height: 250,
          width: 250,
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (authStatus) {
      case AuthStatus.NOT_DETERMINED:
        return buildWaitingScreen();
      case AuthStatus.NOT_LOGGED_IN:
        return LoginPage();
      //LoginPage(onSignedIn: _signedIn,);
      case AuthStatus.LOGGED_IN:
        return AppPage();
    }
    return null;
  }

  Future authAssignment() async {
    FirebaseUser user = await Auth().getCurrentUser();
    if (user?.uid != null &&
        user.isEmailVerified &&
        ((await DatabaseService.getUserWithId(user?.uid, checkLocally: false))
                .id !=
            null)) {
      User loggedInUser =
          await DatabaseService.getUserWithId(user?.uid, checkLocally: false);
      setState(() {
        Constants.currentUser = loggedInUser;
        Constants.currentFirebaseUser = user;
        Constants.currentUserID = user?.uid;
        authStatus = AuthStatus.LOGGED_IN;
      });
    } else if (user?.uid != null && !(user.isEmailVerified)) {
      print('!(user.isEmailVerified) = ${!(user.isEmailVerified)}');
      //await showVerifyEmailSentDialog(context);
      setState(() {
        authStatus = AuthStatus.NOT_LOGGED_IN;
      });
    } else {
      setState(() {
        authStatus = AuthStatus.NOT_LOGGED_IN;
      });
    }
    print('authStatus = $authStatus');
  }
}
