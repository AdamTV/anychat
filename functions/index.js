const functions = require('firebase-functions');

const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

exports.listFruit = functions.https.onCall((data, context) => {
  return ["Apple", "Banana", "Cherry", "Date", "Fig", "Grapes"]
})

exports.pushNotification = functions.database.ref('/counter')
 .onWrite(( change,context) => {
    console.log("Push Notification event triggered");
    var request = change.after.val();
    console.log("request: " + request);
    var payload = {
        data:{
            username: request.userName,
//            username: "test",
        }
    };
    admin.messaging().sendToDevice(request.userTokenId, payload)
    .then(function(response){
        console.log("Successfully sent message: ",response);
        console.log(response.results[0].error);
    })
    .catch(function(error){
        console.log("Error sending message: ", error)
    })
 })