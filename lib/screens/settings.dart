import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:glitcher/widgets/gradient_appbar.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/utils/functions.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int darkOrLight = 0;
  int filter = 0;

  bool _isSubscribedToNewsletter = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  isSubscribedToNewsletter() async {
    bool isSubscribed =
        (await newsletterEmailsRef.document(Constants.currentUserID).get())
            .exists;
    setState(() {
      _isSubscribedToNewsletter = isSubscribed;
    });
    return isSubscribed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(Strings.settings),
        flexibleSpace: gradientAppBar(),
        centerTitle: true,
      ),
      body: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                children: <Widget>[
                  Text(
                    'Theme: ',
                    style: textStyle(),
                  ),
                  Radio(
                      activeColor: MyColors.darkPrimary,
                      value: 0,
                      groupValue: darkOrLight,
                      onChanged: (value) {
                        setTheme(context);
                        setState(() {
                          darkOrLight = value;
                        });
                      }),
                  Text(
                    'Dark',
                  ),
                  Radio(
                      activeColor: MyColors.darkPrimary,
                      value: 1,
                      groupValue: darkOrLight,
                      onChanged: (value) {
                        setTheme(context);
                        setState(() {
                          darkOrLight = value;
                        });
                      }),
                  Text(
                    'Light',
                  ),
                ],
              ),
            ),
            Divider(
              height: 2,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16),
              child: Text(
                'Favourite Feed filter: ',
                style: textStyle(),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Radio(
                        activeColor: MyColors.darkPrimary,
                        value: 0,
                        groupValue: filter,
                        onChanged: (value) {
                          setFavouriteFilter(context, value);
                          setState(() {
                            filter = value;
                          });
                        }),
                    Text(
                      'Recent Posts',
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Radio(
                        activeColor: MyColors.darkPrimary,
                        value: 1,
                        groupValue: filter,
                        onChanged: (value) {
                          setFavouriteFilter(context, value);
                          setState(() {
                            filter = value;
                          });
                        }),
                    Text(
                      'Followed Gamers',
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Radio(
                        activeColor: MyColors.darkPrimary,
                        value: 2,
                        groupValue: filter,
                        onChanged: (value) {
                          setFavouriteFilter(context, value);
                          setState(() {
                            filter = value;
                          });
                        }),
                    Text(
                      'Followed Games',
                    ),
                  ],
                )
              ],
            ),
            Divider(
              height: 2,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16),
              child: Row(
                children: [
                  Text(
                    'Subscribed to newsletter? : ',
                    style: textStyle(),
                  ),
                  Checkbox(
                    checkColor: Colors.white,
                    activeColor: MyColors.darkPrimary,
                    onChanged: (value) {
                      alterNewsletterState();
                    },
                    value: _isSubscribedToNewsletter,
                  )
                ],
              ),
            ),
            Divider(
              height: 2,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16),
              child: MaterialButton(
                color: switchColor(MyColors.lightPrimary, MyColors.darkPrimary),
                child: Text('Change Password'),
                onPressed: () {
                  Navigator.of(context).pushNamed('/password-change');
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  TextStyle textStyle() {
    return TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  }

  alterNewsletterState() async {
    bool isSubscribed = await isSubscribedToNewsletter();
    if (isSubscribed) {
      await newsletterEmailsRef.document(Constants.currentUserID).delete();
      setState(() {
        _isSubscribedToNewsletter = false;
      });
      AppUtil.showSnackBar(
          context, _scaffoldKey, 'Unsubscribed from newsletter');
    } else {
      await DatabaseService.addUserEmailToNewsletter(Constants.currentUserID,
          Constants.currentUser.email, Constants.currentUser.username);
      setState(() {
        _isSubscribedToNewsletter = true;
      });
      AppUtil.showSnackBar(context, _scaffoldKey, 'Subscribed to newsletter');
    }
  }

  @override
  void initState() {
    if (Constants.currentTheme == AvailableThemes.LIGHT_THEME) {
      setState(() {
        darkOrLight = 1;
      });
    } else {
      setState(() {
        darkOrLight = 0;
      });
    }

    setState(() {
      filter = Constants.favouriteFilter;
    });

    isSubscribedToNewsletter();
    super.initState();
  }
}
