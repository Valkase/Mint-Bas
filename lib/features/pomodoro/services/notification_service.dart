// lib/features/pomodoro/services/notification_service.dart
//
// Owns the single ongoing "Pomodoro timer" notification.
// Call showTimer() on every tick — it updates in place with no sound/vibration.
// Call cancel() when the timer stops.
//
// Setup required (do once, see README below):
//   pubspec.yaml  : flutter_local_notifications: ^18.0.0
//   AndroidManifest.xml inside <manifest>:
//     <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
//     <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
//   AndroidManifest.xml inside <application>:
//     <service
//       android:name="com.dexterous.flutterlocalnotifications.ForegroundService"
//       android:exported="false"/>

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _channelId   = 'pomodoro_timer';
  static const _channelName = 'Pomodoro Timer';
  static const _notifId     = 888;

  final _plugin      = FlutterLocalNotificationsPlugin();
  bool  _initialized = false;

  // ── Init — call once from main() before runApp ─────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    try {
      const android  = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      await _plugin.initialize(settings);
      // Request POST_NOTIFICATIONS permission (Android 13+).
      await _plugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _initialized = true;
    } catch (e) {
      debugPrint('[NotificationService] init error: $e');
    }
  }

  // ── Show / update ──────────────────────────────────────────────────────────

  Future<void> showTimer({
    required int    secondsLeft,
    required String phase,
    required bool   isRunning,
    String?         taskName,
  }) async {
    if (!_initialized) return;
    try {
      final m       = secondsLeft ~/ 60;
      final s       = secondsLeft % 60;
      final timeStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

      final phaseLabel = switch (phase) {
        'shortBreak' => 'Short Break',
        'longBreak'  => 'Long Break',
        _            => 'Focus',
      };

      final title = isRunning
          ? '$phaseLabel  •  $timeStr'
          : '$phaseLabel  •  $timeStr  (paused)';

      final body = taskName != null
          ? taskName
          : (isRunning ? 'Timer is running' : 'Timer is paused');

      final details = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription : 'Live Pomodoro timer progress',
        importance         : Importance.low,   // no heads-up pop
        priority           : Priority.low,
        ongoing            : true,             // can't be swiped away
        onlyAlertOnce      : true,             // no sound after first show
        showWhen           : false,
        playSound          : false,
        enableVibration    : false,
        enableLights       : false,
        ticker             : '$phaseLabel $timeStr',
      );

      await _plugin.show(
        _notifId,
        title,
        body,
        NotificationDetails(android: details),
      );
    } catch (e) {
      debugPrint('[NotificationService] showTimer error: $e');
    }
  }

  // ── Cancel ─────────────────────────────────────────────────────────────────

  Future<void> cancel() async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(_notifId);
    } catch (e) {
      debugPrint('[NotificationService] cancel error: $e');
    }
  }
}