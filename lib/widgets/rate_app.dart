import 'package:flutter/material.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/utils/app_util.dart';
import 'package:rate_my_app/rate_my_app.dart';

class RateApp {
  RateMyApp rateMyApp = RateMyApp(
    preferencesPrefix: 'rateMyApp_',
    minDays: 7,
    minLaunches: 10,
    remindDays: 7,
    remindLaunches: 10,
    googlePlayIdentifier: Strings.packageName,
    appStoreIdentifier: '1491556149',
  );

  BuildContext context;

  RateApp(this.context);

  void rateGlitcher() {
    rateMyApp.init().then((_) {
      if (rateMyApp.shouldOpenDialog) {
        rateApp();
      }
    });
  }

  void rateApp() {
    // if you prefer to show a star rating bar :
    rateMyApp.showStarRateDialog(
      context,
      title: 'Rate this app', // The dialog title.

      message:
          'You like this app ? Then take a little bit of your time to leave a rating :', // The dialog message.
      // contentBuilder: (context, defaultContent) => content, // This one allows you to change the default dialog content.
      actionsBuilder: (context, stars) {
        // Triggered when the user updates the star rating.
        return [
          // Return a list of actions (that will be shown at the bottom of the dialog).
          FlatButton(
            child: Text('OK'),
            onPressed: () async {
              if (stars.round() < 4) {
                print('move the user to contact us page!');
                showDialog(
                  context: context,
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: new AlertDialog(
                      content: new Text(
                          'Care to tell us what you don\'t like about our app?'),
                      actions: <Widget>[
                        new GestureDetector(
                          onTap: () => Navigator.of(context).pop(false),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("NO"),
                          ),
                        ),
                        SizedBox(height: 16),
                        new GestureDetector(
                          onTap: () async {
                            await AppUtil.sendSupportEmail('App Review');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("YES"),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (stars >= 4) {
                print('5 stars!!');
                rateMyApp.launchStore();
              } else {
                print('User did not rate the app!');
              }
              // You can handle the result as you want (for instance if the user puts 1 star then open your contact page, if he puts more then open the store page, etc...).
              // This allows to mimic the behavior of the default "Rate" button. See "Advanced > Broadcasting events" for more information :
              await rateMyApp.callEvent(RateMyAppEventType.rateButtonPressed);
              Navigator.pop<RateMyAppDialogButton>(
                  context, RateMyAppDialogButton.rate);
            },
          ),
          FlatButton(
            child: Text('Cancel'),
            onPressed: () async {
              Navigator.pop<RateMyAppDialogButton>(
                  context, RateMyAppDialogButton.rate);
            },
          ),
        ];
      },
      ignoreNativeDialog:
          false, // Set to false if you want to show the native Apple app rating dialog on iOS.
      dialogStyle: DialogStyle(
        // Custom dialog styles.
        titleAlign: TextAlign.center,
        messageAlign: TextAlign.center,
        messagePadding: EdgeInsets.only(bottom: 20),
      ),
      starRatingOptions: StarRatingOptions(), // Custom star bar rating options.
      onDismissed: () => rateMyApp.callEvent(RateMyAppEventType
          .laterButtonPressed), // Called when the user dismissed the dialog (either by taping outside or by pressing the "back" button).
    );
  }
}
