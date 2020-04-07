import 'package:flutter/material.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/strings.dart';

class AboutUs extends StatefulWidget {
  @override
  _AboutUsState createState() => _AboutUsState();
}

class _AboutUsState extends State<AboutUs> {
  // If you want to edit any of the listItems,
  // make sure you edit its link in the itemsRoute

  List<String> listItems = [
    'Help Center',
    'Terms of service',
    'Privacy policy',
    'Cookie use',
    'Legal notices'
  ];

  List<String> itemsRoute = [
    '/help-center',
    '/terms-of-service',
    '/privacy-policy',
    '/cookie-use',
    '/legal-notices'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.about_us),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[MyColors.darkBG, MyColors.darkCardBG]),
            boxShadow: [
              BoxShadow(
                color: MyColors.darkBG,
                blurRadius: 1.0, // has the effect of softening the shadow
                spreadRadius: 0, // has the effect of extending the shadow
                offset: Offset(
                  1.0, // horizontal, move right 10
                  1.0, // vertical, move down 10
                ),
              )
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Version ${Strings.appVersion}'),
          ),
          Divider(
            height: 1.0,
            color: MyColors.darkLineBreak,
          ),
          Expanded(
            child: ListView.builder(
                itemCount: listItems.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    onTap: () {
                      Navigator.of(context).pushNamed(itemsRoute[index]);
                    },
                    title: Text(listItems[index]),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                  );
                }),
          ),
        ],
      ),
    );
  }
}
