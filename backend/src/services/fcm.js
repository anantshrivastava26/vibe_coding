const { admin } = require('../config/firebaseAdmin');

// Must match the Flutter-side channel/sound in lib/services/notification_service.dart
// and the raw resource at android/app/src/main/res/raw/disaster_alert.m4a.
const DISASTER_ALERT_CHANNEL_ID = 'disaster_alert_channel';
const DISASTER_ALERT_SOUND = 'disaster_alert';

async function sendPush(fcmToken, { title, body, data }) {
  const message = {
    token: fcmToken,
    notification: { title, body },
    data: data || {},
    android: {
      priority: 'high',
      notification: {
        channelId: DISASTER_ALERT_CHANNEL_ID,
        sound: DISASTER_ALERT_SOUND,
        priority: 'max',
        defaultVibrateTimings: true,
      },
    },
  };
  return admin.messaging().send(message);
}

module.exports = { sendPush };
