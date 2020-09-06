import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/services/auth_provider.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets/bezier_container.dart';

class SignUpPage extends StatefulWidget {
  SignUpPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _isObscure = true;

  String _errorMsgUsername = '';

  String _errorMsgEmail = '';

  String _username = '';

  String _password = '';

  String _email = '';

  String _confirmPassword = '';

  String userId = "";

  final FocusNode myFocusNodePassword = FocusNode();
  final FocusNode myFocusNodeEmail = FocusNode();
  final FocusNode myFocusNodeName = FocusNode();
  final FocusNode myFocusNodeConfirmPassword = FocusNode();

  Widget _entryField(String title,
      {FocusNode focusNode,
      bool isPassword = false,
      bool isUsername = false,
      bool isEmail = false,
      bool isConfirmPassword = false}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: TextFormField(
                focusNode: focusNode,
                onChanged: (value) {
                  if (isEmail) {
                    setState(() {
                      _email = value;
                    });
                  } else if (isUsername) {
                    setState(() {
                      _username = value;
                    });
                  } else if (isPassword) {
                    setState(() {
                      _password = value;
                    });
                  } else if (isConfirmPassword) {
                    _confirmPassword = value;
                  }
                },
                keyboardType:
                    isEmail ? TextInputType.emailAddress : TextInputType.text,
                onFieldSubmitted: (v) {
                  if (isUsername) {
                    FocusScope.of(context).requestFocus(myFocusNodeEmail);
                  } else if (isEmail) {
                    FocusScope.of(context).requestFocus(myFocusNodePassword);
                  } else if (isPassword) {
                    FocusScope.of(context)
                        .requestFocus(myFocusNodeConfirmPassword);
                  } else if (isConfirmPassword) {
                    _submit();
                  }
                },
                textInputAction: isConfirmPassword
                    ? TextInputAction.done
                    : TextInputAction.next,
                style: TextStyle(color: MyColors.darkCardBG),
                obscureText: _isObscure && (isPassword || isConfirmPassword),
                decoration: InputDecoration(
                    hintText: title,
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Container(
                      width: 48,
                      child: isEmail
                          ? Icon(
                              Icons.email,
                              size: 18,
                              color: Colors.grey.shade400,
                            )
                          : isPassword || isConfirmPassword
                              ? Icon(
                                  Icons.lock,
                                  size: 18,
                                  color: Colors.grey.shade400,
                                )
                              : Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Colors.grey.shade400,
                                ),
                    ),
                    suffixIcon: Container(
                      width: 48,
                      child: _isObscure && (isPassword || isConfirmPassword)
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
                          : isPassword || isConfirmPassword
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
                    border: InputBorder.none,
                    fillColor: Color(0xfff3f3f4),
                    filled: true)),
          )
        ],
      ),
    );
  }

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
          await _submit();
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.symmetric(vertical: 15),
          alignment: Alignment.center,
          child: Text(
            'Register now',
            style: TextStyle(
                fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _loginAccountLabel() {
    return InkWell(
      onTap: () {
        Navigator.pushReplacementNamed(context, '/login');
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 20),
        padding: EdgeInsets.all(15),
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Already have an account ?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              'Login',
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

  Widget _textFieldWidgets() {
    return Column(
      children: <Widget>[
        _entryField("Username", focusNode: myFocusNodeName, isUsername: true),
        _entryField("Email", focusNode: myFocusNodeEmail, isEmail: true),
        _entryField("Password",
            focusNode: myFocusNodePassword, isPassword: true),
        _entryField("Confirm Password",
            focusNode: myFocusNodeConfirmPassword, isConfirmPassword: true)
      ],
    );
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
              top: -MediaQuery.of(context).size.height * .15,
              right: -MediaQuery.of(context).size.width * .4,
              child: BezierContainer(),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 30),
                    _icon(),
                    SizedBox(
                      height: 50,
                    ),
                    _textFieldWidgets(),
                    SizedBox(
                      height: 20,
                    ),
                    _submitButton(),
                    SizedBox(height: 10.0),
                    _loginAccountLabel(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String validateEmail(String value) {
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regExp = new RegExp(pattern);
    if (value.length == 0) {
      AppUtil().showToast("Email is Required");
      setState(() {
        _errorMsgEmail = "Email is Required";
      });
    } else if (!regExp.hasMatch(value)) {
      AppUtil().showToast("Invalid Email");
      setState(() {
        _errorMsgEmail = "Invalid Email";
      });
    } else {
      setState(() {
        _errorMsgEmail = null;
      });
    }
    return _errorMsgEmail;
  }

  @override
  void dispose() {
    super.dispose();
    myFocusNodeConfirmPassword.dispose();
    myFocusNodePassword.dispose();
    myFocusNodeEmail.dispose();
    myFocusNodeName.dispose();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future _signUp() async {
    final BaseAuth auth = AuthProvider.of(context).auth;

    //print(_email + ' : ' + _password);
    glitcherLoader.showLoader(context);

    String validEmail = validateEmail(_email);
    String validUsername = validateUsername(_username);

    print('validEmail: $validEmail ');
    print('validUsername: $validUsername ');

    final valid = await DatabaseService.isUsernameTaken(_username);

    if (!valid) {
      // username exists
      AppUtil.showSnackBar(context, _scaffoldKey,
          '$_username is already in use. Please choose a different username.');
      _setFocusNode(myFocusNodeName);
      return;
    } else {
      if (validEmail == null &&
          validUsername == null &&
          _password == _confirmPassword) {
        // Validation Passed
        userId = await auth.signUp(_username, _email, _password);
        if (userId == 'Email is already in use') {
          AppUtil.showSnackBar(context, _scaffoldKey, userId);
          _setFocusNode(myFocusNodeEmail);
          return;
        } else if (userId == 'Weak Password') {
          AppUtil.showSnackBar(context, _scaffoldKey, 'Weak Password!');
          _setFocusNode(myFocusNodePassword);
          return;
        } else if (userId == 'Invalid Email') {
          AppUtil.showSnackBar(context, _scaffoldKey, 'Invalid Email!');
          _setFocusNode(myFocusNodeEmail);
          return;
        } else if (userId == 'sign_up_error') {
          AppUtil.showSnackBar(context, _scaffoldKey, 'Sign up error!');
          _setFocusNode(myFocusNodeName);
          return;
        }

//          ////TODO test
//          await FirebaseAuth.instance
//              .signInWithEmailAndPassword(email: _email, password: _password);
//          FirebaseUser user = await FirebaseAuth.instance.currentUser();
//          await addUserToDatabase(userId, user.email);
//          await DatabaseService.addUserEmailToNewsletter(
//              userId, user.email, _username);
//          await FirebaseAuth.instance.signOut();
//          ////

        // await auth.sendEmailVerification(); // It's already implemented in the auth.signUp method
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('username', _username);
        glitcherLoader.hideLoader();
        Navigator.of(context).pushReplacementNamed('/login',
            arguments: {'on_sign_up_callback': true});
      } else {
        if (_password != _confirmPassword) {
          AppUtil.showSnackBar(context, _scaffoldKey, "Passwords don't match");
          _setFocusNode(myFocusNodePassword);
          return;
        } else {
          if (_errorMsgUsername != null) {
            AppUtil.showSnackBar(context, _scaffoldKey, _errorMsgUsername);
            _setFocusNode(myFocusNodeName);
            return;
          } else if (_errorMsgEmail != null) {
            AppUtil.showSnackBar(context, _scaffoldKey, _errorMsgEmail);
            _setFocusNode(myFocusNodeEmail);
            return;
          } else {
            print('$_errorMsgUsername\n$_errorMsgEmail');
            AppUtil.showSnackBar(context, _scaffoldKey, "An Error Occurred");
            _setFocusNode(myFocusNodeEmail);
            return;
          }
        }
      }
    }
  }

  Future<void> _submit() async {
    if (_email.isNotEmpty &&
        _username.isNotEmpty &&
        _password.isNotEmpty &&
        _confirmPassword.isNotEmpty) {
      await _signUp();
    } else {
      AppUtil.showSnackBar(context, _scaffoldKey, 'Please fill fields above');
    }
  }

  void _setFocusNode(FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
    glitcherLoader.hideLoader();
  }
}
