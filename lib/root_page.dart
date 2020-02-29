import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/screens/app_page.dart';
import 'package:glitcher/screens/login_page.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/constants.dart';

class RootPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  bool emailVerified;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    authAssignment();
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
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (authStatus) {
      case AuthStatus.NOT_DETERMINED:
        return buildWaitingScreen();
      case AuthStatus.NOT_LOGGED_IN:
        return LoginPage(
          onSignedIn: _signedIn,
        );
      case AuthStatus.LOGGED_IN:
        return AppPage();
    }
    return null;
  }

  Future authAssignment() async {
    FirebaseUser user = await Auth().getCurrentUser();

    if (user?.uid != null && user.isEmailVerified) {
      User loggedInUser = await DatabaseService.getUserWithId(user?.uid);
      setState(() {
        Constants.loggedInUser = loggedInUser;
        Constants.currentUser = user;
        Constants.currentUserID = user?.uid;
        authStatus = AuthStatus.LOGGED_IN;
      });
    } else {
      setState(() {
        authStatus = AuthStatus.NOT_LOGGED_IN;
      });
    }
    print('authStatus = $authStatus');
  }
}
