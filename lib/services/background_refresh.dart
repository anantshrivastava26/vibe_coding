import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../firebase_options.dart';
import 'alert_service.dart';
import 'notification_service.dart';

const String _alertRefreshUniqueName = 'lifeloop-alert-refresh';
const String _alertRefreshTaskName = 'alertRefreshTask';

// Tracks the highest alert id we've already surfaced a notification for, so
// the periodic sync only notifies about alerts the device hasn't seen yet.
const String _lastNotifiedAlertIdKey = 'lastNotifiedAlertId';

/// Registers (or refreshes) the periodic background sync. Android enforces a
/// 15 minute floor on periodic work, which is as tight as this can poll.
Future<void> registerAlertBackgroundRefresh() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    _alertRefreshUniqueName,
    _alertRefreshTaskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await _refreshAndNotify();
      return true;
    } catch (_) {
      // Let WorkManager retry with its default backoff.
      return false;
    }
  });
}

Future<void> _refreshAndNotify() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // No signed-in user in this isolate means nothing to fetch (also covers
  // the device being logged out between the task being scheduled and run).
  if (FirebaseAuth.instance.currentUser == null) return;

  final alerts = await AlertService().fetchMyAlerts();
  if (alerts.isEmpty) return;

  final prefs = await SharedPreferences.getInstance();
  final lastNotifiedId = prefs.getInt(_lastNotifiedAlertIdKey);
  final maxId = alerts.map((a) => a.id).reduce((a, b) => a > b ? a : b);

  // First run ever (no baseline yet): the user has already seen current
  // alerts via push/the alerts screen, so just record the baseline instead
  // of re-notifying the whole history.
  if (lastNotifiedId == null) {
    await prefs.setInt(_lastNotifiedAlertIdKey, maxId);
    return;
  }

  final missed = alerts.where((a) => a.id > lastNotifiedId).toList();
  if (missed.isEmpty) return;

  final local = FlutterLocalNotificationsPlugin();
  await initDisasterAlertChannel(local);
  for (final alert in missed) {
    await showDisasterAlertNotification(
      local,
      id: alert.id,
      title: alert.title,
      body: alert.message,
    );
  }

  await prefs.setInt(_lastNotifiedAlertIdKey, maxId);
}
