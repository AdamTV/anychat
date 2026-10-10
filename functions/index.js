"use strict";

const functions = require("firebase-functions");

const admin = require("firebase-admin");
admin.initializeApp(functions.config().firebase);

// The reCAPTCHA Enterprise assessment sample lives in ./assessment.js and is
// covered by unit tests (test/assessment.test.js). Require it here and wire it
// up as an HTTPS callable when the endpoint is needed:
// const {createAssessment} = require("./assessment");

/**
 * Health check endpoint. Always answers 200 so agents and monitors can
 * verify that the functions deployment is up and serving requests.
 */
exports.health = functions.https.onRequest((req, res) => {
  res.status(200).json({status: "ok"});
});

// exports.listFruit = functions.https.onCall((data, context) => {
//   return ["Apple", "Banana", "Cherry", "Date", "Fig", "Grapes"]
// })
//
// exports.pushNotification = functions.database.ref('/counter')
//  .onWrite(( change,context) => {
//     console.log("Push Notification event triggered");
//     var request = change.after.val();
//     console.log("request: " + request);
//     var payload = {
//         data:{
//             username: request.userName,
// //            username: "test",
//         }
//     };
//    admin.messaging().sendToDevice(request.userTokenId, payload)
//    .then(function(response){
//        console.log("Successfully sent message: ",response);
//        console.log(response.results[0].error);
//    })
//    .catch(function(error){
//        console.log("Error sending message: ", error)
//    })
// })
