// test/app_profile_service_test.dart
// Tests for the local welcome/profile state.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:f3_nation_app/services/app_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts with welcome incomplete and Q as default role', () async {
    final service = AppProfileService();
    await service.load();

    expect(service.welcomeComplete, isFalse);
    expect(service.role, AppRole.q);
    expect(service.displayName, isEmpty);
  });

  test('completeWelcome persists local profile fields', () async {
    final service = AppProfileService();
    await service.load();

    await service.completeWelcome(
      role: AppRole.siteQ,
      displayName: 'Digital',
      homeAo: 'The Flag',
      region: 'F3 Test',
    );

    final reloaded = AppProfileService();
    await reloaded.load();

    expect(reloaded.welcomeComplete, isTrue);
    expect(reloaded.role, AppRole.siteQ);
    expect(reloaded.displayName, 'Digital');
    expect(reloaded.homeAo, 'The Flag');
    expect(reloaded.region, 'F3 Test');
  });

  test('completeWelcome can store linked auth user id', () async {
    final service = AppProfileService();
    await service.load();

    await service.completeWelcome(
      role: AppRole.q,
      displayName: 'Digital',
      authUserId: 'guest_123',
    );

    final reloaded = AppProfileService();
    await reloaded.load();

    expect(reloaded.authUserId, 'guest_123');
  });

  test('completeWelcome can enable local app lock', () async {
    final service = AppProfileService();
    await service.load();

    await service.completeWelcome(
      role: AppRole.q,
      displayName: 'Digital',
      appLockEnabled: true,
    );

    final reloaded = AppProfileService();
    await reloaded.load();

    expect(reloaded.appLockEnabled, isTrue);
  });

  test('setAppLockEnabled persists local app lock preference', () async {
    final service = AppProfileService();
    await service.load();

    await service.setAppLockEnabled(true);

    final reloaded = AppProfileService();
    await reloaded.load();

    expect(reloaded.appLockEnabled, isTrue);
  });

  test('resetWelcome only reopens welcome gate', () async {
    final service = AppProfileService();
    await service.load();
    await service.completeWelcome(role: AppRole.pax, displayName: 'PAX One');

    await service.resetWelcome();

    expect(service.welcomeComplete, isFalse);
    expect(service.role, AppRole.pax);
    expect(service.displayName, 'PAX One');
  });

  test('importJson restores exported profile shape', () async {
    final service = AppProfileService();
    await service.load();

    await service.importJson({
      'welcomeComplete': true,
      'displayName': 'Backup',
      'homeAo': 'The Hill',
      'region': 'F3 Local',
      'role': 'siteQ',
      'authUserId': 'guest_backup',
      'appLockEnabled': true,
    });

    expect(service.welcomeComplete, isTrue);
    expect(service.displayName, 'Backup');
    expect(service.homeAo, 'The Hill');
    expect(service.region, 'F3 Local');
    expect(service.role, AppRole.siteQ);
    expect(service.authUserId, 'guest_backup');
    expect(service.appLockEnabled, isTrue);
  });
}
