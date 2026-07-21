// lib/services/notification_service.dart
// Schedules and cancels the weekly Q-day workout reminder notification.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    // Request nothing at init time (matches the Android side — permission is
    // asked lazily, the first time a reminder actually needs to fire; see
    // reconcileEventReminders).
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(initSettings);
  }

  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await ios?.requestPermissions(alert: true, badge: true, sound: true);
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

  // ── Per-event reminders (HC'd/Q'd beatdowns) ──────────────────────────────
  // Deterministic ids derived from the event instance id so scheduling is
  // idempotent (re-running just replaces the same three alarms) and
  // un-HC'ing can cancel exactly these three without touching anything else.
  int _dayBeforeId(int eventId) => eventId * 10 + 1;
  int _hourBeforeId(int eventId) => eventId * 10 + 2;
  int _backblastId(int eventId) => eventId * 10 + 3;

  /// Schedules day-before/hour-before reminders for a beatdown the user is
  /// HC'd or Q'd for, plus a post-event backblast nudge if they're the Q.
  /// [hasPreblast] only affects the wording (nudges to post it if missing)
  /// — the calendar-home-schedule API doesn't expose backblast status at
  /// all, so the backblast nudge always fires for a Q'd event regardless of
  /// whether one's already been posted; a known limitation, not a bug.
  /// Any of the three that would land in the past is silently skipped
  /// (e.g. HC'ing same-day skips the day-before one).
  Future<void> scheduleEventReminders({
    required int eventId,
    required DateTime eventDateTime,
    required String title,
    required bool isQ,
    required bool hasPreblast,
  }) async {
    await cancelEventReminders(eventId);
    final now = tz.TZDateTime.now(tz.local);
    final eventTime = tz.TZDateTime.from(eventDateTime, tz.local);

    final dayBefore = eventTime.subtract(const Duration(days: 1));
    if (dayBefore.isAfter(now)) {
      final needsPreblast = isQ && !hasPreblast;
      await _zonedSchedule(
        _dayBeforeId(eventId),
        dayBefore,
        needsPreblast ? '📋 Preblast still needed' : '⚡ Beatdown tomorrow',
        needsPreblast
            ? 'You\'re Q for "$title" tomorrow — post the preblast when you get a chance.'
            : '"$title" is tomorrow. You\'re signed up.',
      );
    }

    final hourBefore = eventTime.subtract(const Duration(hours: 1));
    if (hourBefore.isAfter(now)) {
      await _zonedSchedule(
        _hourBeforeId(eventId),
        hourBefore,
        '⏰ 1 hour to go',
        '"$title" starts in an hour.',
      );
    }

    if (isQ) {
      final backblastTime = eventTime.add(const Duration(hours: 3));
      if (backblastTime.isAfter(now)) {
        await _zonedSchedule(
          _backblastId(eventId),
          backblastTime,
          '📝 Backblast time',
          'Don\'t forget to post the backblast for "$title".',
        );
      }
    }
  }

  Future<void> cancelEventReminders(int eventId) async {
    await _plugin.cancel(_dayBeforeId(eventId));
    await _plugin.cancel(_hourBeforeId(eventId));
    await _plugin.cancel(_backblastId(eventId));
  }

  static const _keyScheduledEventIds = 'notif_scheduled_event_ids';

  /// Schedules reminders for every event in [events] and cancels reminders
  /// for any previously-tracked event id that isn't in this list anymore —
  /// covers un-HC'ing (or someone else taking the Q) from outside this app
  /// (Slack, the webapp), not just in-session button taps. Call this
  /// whenever the "my HC'd/Q'd events" list is fetched (e.g. Home load),
  /// not just from the HC/take-Q button handlers.
  Future<void> reconcileEventReminders(
    List<({int id, DateTime dateTime, String title, bool isQ, bool hasPreblast})>
        events,
  ) async {
    // Lazily ask here rather than at app startup with nothing to show for
    // it yet — this is the natural first moment a reminder actually needs
    // to fire. (requestNotificationsPermission() is a no-op if already
    // granted/denied, so this is safe to call every time.)
    if (events.isNotEmpty) await requestPermissions();
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getStringList(_keyScheduledEventIds) ?? [];
    final currentIds = events.map((e) => e.id.toString()).toSet();

    for (final staleId in previous.toSet().difference(currentIds)) {
      final id = int.tryParse(staleId);
      if (id != null) await cancelEventReminders(id);
    }

    for (final e in events) {
      await scheduleEventReminders(
        eventId: e.id,
        eventDateTime: e.dateTime,
        title: e.title,
        isQ: e.isQ,
        hasPreblast: e.hasPreblast,
      );
    }

    await prefs.setStringList(
        _keyScheduledEventIds, currentIds.toList());
  }

  // ── Foreground delta-check (Q assigned / backblast still unposted) ───────
  // Client-only, no backend involvement — checks whatever the app already
  // fetches (getUpcomingBeatdowns/getPastQsWithoutBackblast) against what was
  // seen last time, and fires an immediate notification for genuinely new
  // entries. IMPORTANT LIMITATION: this only runs when the app is actually
  // foregrounded (app resume + a periodic timer while it stays open — see
  // _AppEntryState in main.dart) — a Q assignment made elsewhere while the
  // app is closed produces no notification until the user next opens it.
  // This is not a substitute for real push notifications.
  static const _keySeenQEventIds = 'notif_seen_q_event_ids';
  static const _keySeenUnpostedBackblastIds = 'notif_seen_unposted_backblast_ids';
  int _deltaNotifId(int eventId) => eventId * 10 + 4; // +1/+2/+3 taken above
  int _backblastDeltaNotifId(int eventId) => eventId * 10 + 5;

  Future<void> checkForDeltasAndNotify({
    required Set<int> currentQEventIds,
    required Map<int, String> currentQEventTitles,
    required Set<int> currentUnpostedBackblastIds,
    required Map<int, String> currentUnpostedBackblastTitles,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final previousQIds = (prefs.getStringList(_keySeenQEventIds) ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
    final newQIds = currentQEventIds.difference(previousQIds);
    for (final id in newQIds) {
      await _showNow(
        _deltaNotifId(id),
        '🛡️ You\'re Q',
        'You\'ve been assigned Q for "${currentQEventTitles[id] ?? 'a beatdown'}".',
      );
    }

    final previousBackblastIds =
        (prefs.getStringList(_keySeenUnpostedBackblastIds) ?? [])
            .map(int.tryParse)
            .whereType<int>()
            .toSet();
    final newBackblastIds =
        currentUnpostedBackblastIds.difference(previousBackblastIds);
    for (final id in newBackblastIds) {
      await _showNow(
        _backblastDeltaNotifId(id),
        '📝 Backblast still unposted',
        '"${currentUnpostedBackblastTitles[id] ?? 'A beatdown'}" doesn\'t have a backblast yet.',
      );
    }

    if (newQIds.isNotEmpty || newBackblastIds.isNotEmpty) {
      await requestPermissions();
    }
    await prefs.setStringList(_keySeenQEventIds,
        currentQEventIds.map((id) => id.toString()).toList());
    await prefs.setStringList(_keySeenUnpostedBackblastIds,
        currentUnpostedBackblastIds.map((id) => id.toString()).toList());
  }

  Future<void> _showNow(int id, String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'f3_delta_check',
        'Beatdown Updates',
        channelDescription:
            'New Q assignments and unposted-backblast nudges, checked when you open the app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(id, title, body, details);
  }

  Future<void> _zonedSchedule(
      int id, tz.TZDateTime when, String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'f3_event_reminder',
        'Beatdown Reminders',
        channelDescription:
            'Day-before/hour-before reminders for beatdowns you\'re HC\'d or Q\'d for',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
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
