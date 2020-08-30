import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/screens/welcome/widgets/verify_email.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/services/auth_provider.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets/bezier_container.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _email = '', _password = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String userId = "";

  final focus = FocusNode();

  Widget _backButton() {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(left: 0, top: 10, bottom: 10),
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  searchList(String text) {
    List<String> list = [];
    for (int i = 1; i <= text.length; i++) {
      list.add(text.substring(0, i).toLowerCase());
    }
    return list;
  }

  addUserToDatabase(String id, String email, String username) async {
    List search = searchList(username);
    Map<String, dynamic> userMap = {
      'name': 'Your name here',
      'username': username,
      'email': email,
      'description': 'Write something about yourself',
      'notificationsNumber': 0,
      'violations': 0,
      'search': search
    };

    await usersRef.document(id).setData(userMap);
  }

  Widget _entryField(String title, {bool isPassword = false}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: TextFormField(
                onChanged: (value) {
                  isPassword ? _password = value : _email = value;
                },
                keyboardType: !isPassword
                    ? TextInputType.emailAddress
                    : TextInputType.text,
                textInputAction:
                    isPassword ? TextInputAction.done : TextInputAction.next,
                onFieldSubmitted: (v) {
                  if (!isPassword) {
                    FocusScope.of(context).requestFocus(focus);
                  } else {
                    _checkFields();
                  }
                },
                focusNode: isPassword ? focus : null,
                style: TextStyle(color: MyColors.darkCardBG),
                obscureText: _isObscure && (isPassword),
                decoration: InputDecoration(
                    prefixIcon: Container(
                      width: 48,
                      child: !isPassword
                          ? Icon(
                              Icons.email,
                              size: 18,
                              color: Colors.grey.shade400,
                            )
                          : Icon(
                              Icons.lock,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                    ),
                    suffixIcon: Container(
                      width: 48,
                      child: _isObscure && isPassword
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  _isObscure = !_isObscure;
                                });
                              },
                              icon: Icon(
                                Icons.remove_red_eye,
                                size: 18,
                              ),
                              color: Colors.grey.shade400,
                            )
                          : isPassword
                              ? IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isObscure = !_isObscure;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.visibility_off,
                                    size: 18,
                                  ),
                                  color: Colors.grey.shade400,
                                )
                              : Container(),
                    ),
                    hintText: isPassword ? 'Password' : 'E-mail',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    fillColor: Color(0xfff3f3f4),
                    filled: true)),
          )
        ],
      ),
    );
  }

  bool _isObscure = true;

  Widget _submitButton() {
    return Ink(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerRight,
              colors: [MyColors.darkCardBG, MyColors.darkPrimary])),
      child: InkWell(
        splashColor: Colors.yellow,
        onTap: () async {
          _checkFields();
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.symmetric(vertical: 15),
          alignment: Alignment.center,
          child: Text(
            'LOGIN',
            style: TextStyle(
                fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  Widget _divider() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 20,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Divider(
                thickness: 1,
              ),
            ),
          ),
          Text('or'),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Divider(
                thickness: 1,
              ),
            ),
          ),
          SizedBox(
            width: 20,
          ),
        ],
      ),
    );
  }

  Widget _facebookButton() {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xff1959a9),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(5),
                    topLeft: Radius.circular(5)),
              ),
              alignment: Alignment.center,
              child: Text('f',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w400)),
            ),
          ),
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: () async {
                final facebookLogin = FacebookLogin();

                // Let's force the users to login using the login dialog based on WebViews. Yay!
                facebookLogin.loginBehavior = FacebookLoginBehavior.webViewOnly;

                final result = await facebookLogin.logIn(['email']);

                switch (result.status) {
                  case FacebookLoginStatus.loggedIn:
                    print('facebook login success');
                    //_sendTokenToServer(result.accessToken.token);
                    //_showLoggedInUI();
                    break;
                  case FacebookLoginStatus.cancelledByUser:
                    //_showCancelledMessage();
                    break;
                  case FacebookLoginStatus.error:
                    //_showErrorOnUI(result.errorMessage);
                    break;
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xff2872ba),
                  borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(5),
                      topRight: Radius.circular(5)),
                ),
                alignment: Alignment.center,
                child: Text('Log in with Facebook',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w400)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _createAccountLabel() {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/sign-up');
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.all(15),
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Don\'t have an account ?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              'Register',
              style: TextStyle(
                  color: MyColors.darkPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _icon() {
    return Image.asset(
      'assets/images/icon-480.png',
      height: 200.0,
    );
  }

  Widget _emailPasswordWidget() {
    return Column(
      children: <Widget>[
        _entryField("Email"),
        _entryField("Password", isPassword: true),
      ],
    );
  }

  Future _login() async {
    final BaseAuth auth = AuthProvider.of(context).auth;

    //print(mEmail + ' : ' + mPassword);
    glitcherLoader.showLoader(context);
    //print('Should be true: $_loading');
    try {
      FirebaseUser user =
          await auth.signInWithEmailAndPassword(_email, _password);
      userId = user.uid;
      User temp = await DatabaseService.getUserWithId(userId);

      if (user.isEmailVerified && temp.id == null) {
        print('signed up');
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String username = prefs.getString('username');

        await addUserToDatabase(userId, user.email, username);
        await DatabaseService.addUserEmailToNewsletter(
            userId, user.email, username);

        saveToken();

        Navigator.of(context).pushReplacementNamed('/');
      } else if (!user.isEmailVerified) {
        await auth.signOut();
        await showVerifyEmailSentDialog(context);
      } else {
        saveToken();

        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      // Email or Password Incorrect
      AppUtil.showSnackBar(context, _scaffoldKey, 'Authentication failed');
    }
    glitcherLoader.hideLoader();
    //print('Should be true: $_loading');
  }

  saveToken() async {
    String token = await FirebaseMessaging().getToken();
    usersRef
        .document(Constants.currentUserID)
        .collection('tokens')
        .document(token)
        .setData({'modifiedAt': FieldValue.serverTimestamp(), 'signed': true});
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
        key: _scaffoldKey,
        body: Container(
          height: height,
          child: Stack(
            children: <Widget>[
              Positioned(
                  top: -height * .15,
                  right: -MediaQuery.of(context).size.width * .4,
                  child: BezierContainer()),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: 30.0),
                      _icon(),
                      SizedBox(height: 50),
                      _emailPasswordWidget(),
                      SizedBox(height: 20),
                      _submitButton(),
                      GestureDetector(
                        onTap: () async {
                          Navigator.of(context).pushNamed('/password-reset');
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.centerRight,
                          child: Text('Forgot Password ?',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                      ),
//                      _divider(),
//                      _facebookButton(),
                      SizedBox(height: 10.0),
                      _createAccountLabel(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Future<void> _checkFields() async {
    if (_email.isNotEmpty && _password.isNotEmpty) {
      await _login();
    } else {
      AppUtil.showSnackBar(
          context, _scaffoldKey, 'Please enter your login details');
    }
  }
}
