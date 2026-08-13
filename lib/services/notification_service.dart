import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import 'api_client.dart';
import 'background_refresh.dart';

// Must match the raw resource at android/app/src/main/res/raw/disaster_alert.m4a
// and the android channel/sound the backend sends via fcm.js.
//
// Android notification channels are immutable after creation: once a channel
// with a given ID exists on a device, changing its sound/importance in code
// has no effect for that install. Devices that had the app installed before
// the custom sound was added are stuck on the old (silent/default) channel.
// Bumping the ID forces Android to create a fresh channel with the right
// sound. Bump it again any time channel settings change.
const String disasterAlertChannelId = 'disaster_alert_channel_v2';
const String disasterAlertChannelName = 'Disaster Alerts';
const String disasterAlertSoundResource = 'disaster_alert';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

const String disasterAlertChannelDescription =
    'Critical disaster and emergency alerts for your area';

// Shared by the foreground path here and the background-refresh isolate in
// background_refresh.dart, so a device that only ever gets caught-up alerts
// through the periodic refresh still gets the same channel/sound.
Future<void> initDisasterAlertChannel(FlutterLocalNotificationsPlugin local) async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await local.initialize(const InitializationSettings(android: androidInit));

  const channel = AndroidNotificationChannel(
    disasterAlertChannelId,
    disasterAlertChannelName,
    description: disasterAlertChannelDescription,
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound(disasterAlertSoundResource),
    enableVibration: true,
  );
  await local
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> showDisasterAlertNotification(
  FlutterLocalNotificationsPlugin local, {
  required int id,
  required String? title,
  required String? body,
}) {
  return local.show(
    id,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        disasterAlertChannelId,
        disasterAlertChannelName,
        channelDescription: disasterAlertChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(disasterAlertSoundResource),
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
      ),
    ),
  );
}

class NotificationService {
  final ApiClient _api = ApiClient();
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    await initDisasterAlertChannel(_local);

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _registerToken(token);
    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    FirebaseMessaging.onMessage.listen(_showForegroundAlert);

    // Push should be near-instant, but OEM battery optimization and Doze can
    // delay or drop FCM delivery while the app is backgrounded/killed. This
    // periodic sync is a catch-up net: it polls for alerts the device missed
    // and surfaces them as local notifications, so alerts still land even if
    // a push was swallowed.
    await registerAlertBackgroundRefresh();
  }

  Future<void> _registerToken(String token) async {
    try {
      await _api.post('/api/users/me/device-token', {'fcmToken': token, 'platform': 'android'});
    } catch (_) {
      // Non-fatal: retried automatically on next app start or token refresh.
    }
  }

  Future<void> _showForegroundAlert(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await showDisasterAlertNotification(
      _local,
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
    );
  }
}
