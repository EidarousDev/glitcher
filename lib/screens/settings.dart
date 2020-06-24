import 'package:flutter/material.dart';
import 'package:glitcher/common_widgets/gradient_appbar.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  Text('Theme: '),
                  Radio(
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
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Favourite Feed filter: ',
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Radio(
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
          ],
        ),
      ),
    );
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
    super.initState();
  }
}
