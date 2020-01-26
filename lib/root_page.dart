import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/screens/login_page.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/screens/home/home.dart';
import 'package:glitcher/services/auth_provider.dart';

enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
}

class RootPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;
  String _userId = "";
  bool emailVerified;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final BaseAuth auth = AuthProvider.of(context).auth;
    auth.getCurrentUser().then((FirebaseUser user) {
      if (user?.uid != null && user.isEmailVerified) {
        _userId = user?.uid;
        setState(() {
          authStatus = AuthStatus.LOGGED_IN;
        });
      } else {
        setState(() {
          authStatus = AuthStatus.NOT_LOGGED_IN;
        });
      }
    });
    print('authStatus = $authStatus');
  }

  void _signedIn() {
    setState(() {
      authStatus = AuthStatus.LOGGED_IN;
    });
  }

  void _signedOut() {
    setState(() {
      authStatus = AuthStatus.NOT_LOGGED_IN;
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
        return HomePage(
          onSignedOut: _signedOut,
        );
    }
    return null;
  }
}
