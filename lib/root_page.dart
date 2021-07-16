import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/models/user_model.dart' as user;
import 'package:glitcher/screens/app_page.dart';
import 'package:glitcher/screens/welcome/login_page.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/functions.dart';

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
    User firebaseUser = await Auth().getCurrentUser();
    if (firebaseUser?.uid != null &&
        firebaseUser.emailVerified &&
        ((await DatabaseService.getUserWithId(firebaseUser?.uid,
                    checkLocal: false))
                .id !=
            null)) {
      user.User loggedInUser = await DatabaseService.getUserWithId(
          firebaseUser?.uid,
          checkLocal: false);
      setState(() {
        Constants.currentUser = loggedInUser;
        Constants.currentFirebaseUser = firebaseUser;
        Constants.currentUserID = firebaseUser?.uid;
        authStatus = AuthStatus.LOGGED_IN;
      });
    } else if (firebaseUser?.uid != null && !(firebaseUser.emailVerified)) {
      print(
          '!(firebaseUser.isEmailVerified) = ${!(firebaseUser.emailVerified)}');
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
