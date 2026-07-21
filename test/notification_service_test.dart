// test/notification_service_test.dart
// Tests for the foreground delta-check (new Q assignment / still-unposted
// backblast) — checkForDeltasAndNotify's diff-against-last-seen logic.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:f3_nation_app/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel =
      MethodChannel('dexterous.com/flutter/local_notifications');
  final shown = <Map<String, dynamic>>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    shown.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'initialize':
          return true;
        case 'show':
          shown.add(Map<String, dynamic>.from(call.arguments as Map));
          return null;
        case 'requestNotificationsPermission':
        case 'requestPermissions':
          return true;
        default:
          return null;
      }
    });
  });

  test('fires a notification for a newly-appeared Q assignment', () async {
    await NotificationService().checkForDeltasAndNotify(
      currentQEventIds: {101},
      currentQEventTitles: {101: 'Shovel Flag'},
      currentUnpostedBackblastIds: {},
      currentUnpostedBackblastTitles: {},
    );
    expect(shown, hasLength(1));
    expect(shown.first['title'], contains('Q'));
  });

  test('does not re-fire for a Q assignment already seen last check',
      () async {
    await NotificationService().checkForDeltasAndNotify(
      currentQEventIds: {101},
      currentQEventTitles: {101: 'Shovel Flag'},
      currentUnpostedBackblastIds: {},
      currentUnpostedBackblastTitles: {},
    );
    shown.clear();

    await NotificationService().checkForDeltasAndNotify(
      currentQEventIds: {101},
      currentQEventTitles: {101: 'Shovel Flag'},
      currentUnpostedBackblastIds: {},
      currentUnpostedBackblastTitles: {},
    );
    expect(shown, isEmpty);
  });

  test('fires again once a Q id drops out and reappears (re-Q\'d later)',
      () async {
    await NotificationService().checkForDeltasAndNotify(
      currentQEventIds: {101},
      currentQEventTitles: {101: 'Shovel Flag'},
      currentUnpostedBackblastIds: {},
      currentUnpostedBackblastTitles: {},
    );
    await NotificationService().checkForDeltasAndNotify(
      currentQEventIds: {},
      currentQEventTitles: {},
      currentUnpostedBackblastIds: {},
      currentUnpostedBackblastTitles: {},
    );
    shown.clear();

    await NotificationService().checkForDeltasAndNotify(
      currentQEventIds: {101},
      currentQEventTitles: {101: 'Shovel Flag'},
      currentUnpostedBackblastIds: {},
      currentUnpostedBackblastTitles: {},
    );
    expect(shown, hasLength(1));
  });

  test('fires a separate notification for an unposted backblast', () async {
    await NotificationService().checkForDeltasAndNotify(
      currentQEventIds: {},
      currentQEventTitles: {},
      currentUnpostedBackblastIds: {202},
      currentUnpostedBackblastTitles: {202: 'The Ruckus'},
    );
    expect(shown, hasLength(1));
    expect(shown.first['title'], contains('Backblast'));
  });

  test('Q and backblast deltas in the same check both fire', () async {
    await NotificationService().checkForDeltasAndNotify(
      currentQEventIds: {101},
      currentQEventTitles: {101: 'Shovel Flag'},
      currentUnpostedBackblastIds: {202},
      currentUnpostedBackblastTitles: {202: 'The Ruckus'},
    );
    expect(shown, hasLength(2));
  });
}
