import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/services/auth_provider.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';

import 'login_page.dart';
import 'widgets/bezier_container.dart';

class PasswordChangeScreen extends StatefulWidget {
  PasswordChangeScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _PasswordChangeScreenState createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  bool _isObscure = true;

  String _password = '';

  String _confirmPassword = '';

  String userId = "";

  final FocusNode myFocusNodePassword = FocusNode();
  final FocusNode myFocusNodeConfirmPassword = FocusNode();

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

  Widget _entryField(String title,
      {FocusNode focusNode,
      bool isPassword = false,
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
                  if (isPassword) {
                    setState(() {
                      _password = value;
                    });
                  } else if (isConfirmPassword) {
                    _confirmPassword = value;
                  }
                },
                onFieldSubmitted: (v) {
                  if (isPassword) {
                    FocusScope.of(context)
                        .requestFocus(myFocusNodeConfirmPassword);
                  } else if (isConfirmPassword) {
                    _changePassword();
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
                        child: Icon(
                          Icons.lock,
                          size: 18,
                          color: Colors.grey.shade400,
                        )),
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
    return InkWell(
      onTap: () async {
        if (_password.isNotEmpty && _confirmPassword.isNotEmpty) {
          await _changePassword();
        } else {
          AppUtil.showSnackBar(
              context, _scaffoldKey, 'Please fill fields above');
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerRight,
                colors: [MyColors.darkCardBG, MyColors.darkPrimary])),
        child: Text(
          'Change Password',
          style: TextStyle(fontSize: 20, color: Colors.white),
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
      appBar: AppBar(
        title: Text('Change Password'),
        flexibleSpace: gradientAppBar(),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
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
                    SizedBox(height: 200),
                    //_icon(),
                    SizedBox(
                      height: 50,
                    ),
                    _textFieldWidgets(),
                    SizedBox(
                      height: 20,
                    ),
                    _submitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _loading = false;

  @override
  void dispose() {
    super.dispose();
    myFocusNodeConfirmPassword.dispose();
    myFocusNodePassword.dispose();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  searchList(String text) {
    List<String> list = [];
    for (int i = 1; i <= text.length; i++) {
      list.add(text.substring(0, i).toLowerCase());
    }
    return list;
  }

  Future _changePassword() async {
    final BaseAuth auth = AuthProvider.of(context).auth;

    setState(() {
      _loading = true;
    });

    if (_password == _confirmPassword) {
      // Validation Passed
      try {
        await auth.changePassword(_password);
        AppUtil.showSnackBar(
            context, _scaffoldKey, 'Password changed successfully');
        Navigator.of(context).pushReplacementNamed('/login');
      } catch (signUpError) {}
    } else {
      if (_password != _confirmPassword) {
        AppUtil.showSnackBar(context, _scaffoldKey, "Passwords don't match");
        myFocusNodePassword.requestFocus();
      } else {}
    }

    setState(() {
      _loading = false;
    });
    print('Should be false: $_loading');
  }
}
