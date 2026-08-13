const { admin } = require('../config/firebaseAdmin');

async function sendPush(fcmToken, { title, body, data }) {
  const message = {
    token: fcmToken,
    notification: { title, body },
    data: data || {},
  };
  return admin.messaging().send(message);
}

module.exports = { sendPush };
