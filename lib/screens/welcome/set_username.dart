import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/services/auth.dart';
import 'package:glitcher/services/auth_provider.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:glitcher/utils/functions.dart';

import 'widgets/bezier_container.dart';

class SetUsernameScreen extends StatefulWidget {
  final FirebaseUser user;

  const SetUsernameScreen({Key key, this.user}) : super(key: key);

  @override
  _SetUsernameScreenState createState() => _SetUsernameScreenState();
}

class _SetUsernameScreenState extends State<SetUsernameScreen> {
  String _username = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        _icon(),
                        SizedBox(height: 50),
                        _entryField('Username'),
                        SizedBox(height: 20),
                        _submitButton(),
                        SizedBox(height: 100.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(top: 40, left: 0, child: _backButton())
            ],
          ),
        ));
  }

  Widget _entryField(String title) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: TextFormField(
                onChanged: (value) {
                  _username = value;
                },
                style: TextStyle(color: MyColors.darkCardBG),
                decoration: InputDecoration(
                    prefixIcon: Container(
                        width: 48,
                        child: Icon(
                          Icons.person,
                          size: 18,
                          color: Colors.grey.shade400,
                        )),
                    hintText: 'Username',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    fillColor: Color(0xfff3f3f4),
                    filled: true)),
          )
        ],
      ),
    );
  }

  Widget _icon() {
    return Image.asset(
      'assets/images/icon-480.png',
      height: 260.0,
    );
  }

  Widget _submitButton() {
    return InkWell(
      onTap: () async {
        _createUser();
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
          'Set username',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }

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

  void _createUser() async {
    final BaseAuth auth = AuthProvider.of(context).auth;
    glitcherLoader.showLoader(context);
    String validUsername = validateUsername(_username);
    try {
      if (_username != '' && validUsername == null) {
        print('signed up');
        await DatabaseService.addUserToDatabase(
            widget.user.uid, widget.user.email, _username);
        await DatabaseService.addUserEmailToNewsletter(
            widget.user.uid, widget.user.email, _username);

        saveToken();

        Navigator.of(context).pushReplacementNamed('/');
      } else if (validUsername != null) {
        AppUtil.showSnackBar(context, _scaffoldKey, 'Invalid username!');
      } else {
        AppUtil.showSnackBar(
            context, _scaffoldKey, 'Please, enter a valid username.');
      }
    } catch (e) {
      // Email or Password Incorrect
      AppUtil.showSnackBar(context, _scaffoldKey, 'Unknown Error occurred!');
    }
    glitcherLoader.hideLoader();
  }
}
