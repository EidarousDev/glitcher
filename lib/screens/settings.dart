import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/common_widgets/gradient_appbar.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int darkOrLight = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.settings),
        flexibleSpace: gradientAppBar(),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:  16.0, vertical: 8),
            child: Row(
              children: <Widget>[
                Text('Theme: '),
                Radio(
                    value: 0,
                    groupValue: darkOrLight,
                    onChanged: (value) {
                      changeTheme(context);
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
                      changeTheme(context);
                      setState(() {
                        darkOrLight = value;
                      });
                    }),
                Text(
                  'Light',
                ),
              ],
            ),
          )
        ],
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
    super.initState();
  }
}
