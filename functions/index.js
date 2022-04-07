const functions = require("firebase-functions");
const admin = require("firebase-admin");


admin.initializeApp();


exports.sendHttpPushNotification = functions.https.onRequest((req, res) => {
  const {title, desc, imageUrl} = req.body;
  console.log(req.body.title);

  const message = {
    notification: {
      title: title,
      body: desc,
    },
    data: {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "route": "red",
    },
    android: {
      priority: "high",
      notification: {
        imageUrl: imageUrl,
        icon: "stock_ticker_update",
        color: "#f45342",
      },
    },
    topic: "myTopic",
  };


  // admin.messaging().sendToTopic("myTopic", message, options);
  admin.messaging().send(message).then((response) => {
    console.log("Successfully sent message:", response);
    return res.send(response.data);
  }).catch((error) => {
    console.log("Error sending message:", error);
    return res.status(500).send(error);
  });
});

