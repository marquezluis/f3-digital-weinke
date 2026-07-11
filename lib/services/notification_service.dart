// lib/services/notification_service.dart
// Schedules and cancels the weekly Q-day workout reminder notification.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _reminderNotifId = 42;

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Schedule a weekly repeating reminder.
  /// [weekday]: 1=Mon ... 7=Sun (ISO 8601).
  /// [hour] / [minute]: 24h local time.
  Future<void> scheduleWeeklyReminder({
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(_reminderNotifId);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'f3_reminder',
        'F3 Beatdown Reminder',
        channelDescription: 'Weekly Q-day workout reminder',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = _nextWeekday(now, weekday, hour, minute);

    await _plugin.zonedSchedule(
      _reminderNotifId,
      '⚡ Time to Q!',
      'Your weekly F3 beatdown is ready. Open Digital Weinke to plan your session.',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancelReminder() async {
    await _plugin.cancel(_reminderNotifId);
  }

  tz.TZDateTime _nextWeekday(
      tz.TZDateTime from, int weekday, int hour, int minute) {
    var dt = tz.TZDateTime(tz.local, from.year, from.month, from.day, hour, minute);
    // Advance until we hit the target weekday, then ensure it's in the future.
    while (dt.weekday != weekday || dt.isBefore(from)) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }
}
