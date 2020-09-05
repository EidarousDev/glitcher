// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

'use strict'

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

exports.sendNotification = functions.firestore.document('users/{userId}/notifications/{notificationId}').onCreate((snap, context) => {

  const userId = context.params.userId;
  const notificationId = context.params.notificationId;

  return admin.firestore().collection("users").doc(userId).collection("notifications").doc(notificationId).get().then(queryResult =>{

      const sender = queryResult.data().sender;
      const title = queryResult.data().title;
      const body = queryResult.data().body;
      const timestamp = queryResult.data().timestamp;
      const objectId = queryResult.data().object_id;
      const type =  queryResult.data().type;
      const seen = queryResult.data().seen;

      console.log("You have new notification from  : ", sender);
      const userQuery = admin.firestore().collection("users").doc(sender).get();

      var tokens = [];

      const toUserDeviceTokenQuery = admin.firestore().collection("users").doc(userId).collection("tokens").get()
      .then(snapshot => {
              snapshot.forEach(doc => {
              console.log("signed", doc.data().signed);
              if(doc.data().signed){
                tokens.push(doc.id);
              }
              });
              return tokens;
          })
          .catch(err => {
              console.log('Error getting documents', err);
          });

      return Promise.all([userQuery, toUserDeviceTokenQuery]).then(result => {

        const userName = result[0].data().name;

        const payload = {
          notification: {
            title : title,
            body: body,
            icon: "default",
            sound: "notification.mp3",
            click_action : "FLUTTER_NOTIFICATION_CLICK"
          },
          data:{
            "object_id": objectId,
            "type": type,
            "timestamp" : JSON.stringify(timestamp),
            "seen": JSON.stringify(seen),
             "id": notificationId,
          }
        };

        return admin.messaging().sendToDevice(tokens, payload).then(response => {

          return console.log("Notification sent to device " + tokens[0]);

        });

      });
    });
  });