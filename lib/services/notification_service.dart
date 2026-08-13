import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import 'api_client.dart';

// Must match the raw resource at android/app/src/main/res/raw/disaster_alert.m4a
// and the android channel/sound the backend sends via fcm.js.
const String disasterAlertChannelId = 'disaster_alert_channel';
const String disasterAlertChannelName = 'Disaster Alerts';
const String disasterAlertSoundResource = 'disaster_alert';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationService {
  final ApiClient _api = ApiClient();
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(const InitializationSettings(android: androidInit));

    const channel = AndroidNotificationChannel(
      disasterAlertChannelId,
      disasterAlertChannelName,
      description: 'Critical disaster and emergency alerts for your area',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(disasterAlertSoundResource),
      enableVibration: true,
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _registerToken(token);
    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    FirebaseMessaging.onMessage.listen(_showForegroundAlert);
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
    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          disasterAlertChannelId,
          disasterAlertChannelName,
          channelDescription: 'Critical disaster and emergency alerts for your area',
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
}
