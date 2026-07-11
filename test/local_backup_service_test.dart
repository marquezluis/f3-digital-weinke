// test/local_backup_service_test.dart
// Local backup/export keeps the app portable without requiring accounts.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:f3_nation_app/models/workout_history.dart';
import 'package:f3_nation_app/services/app_profile_service.dart';
import 'package:f3_nation_app/services/history_service.dart';
import 'package:f3_nation_app/services/local_backup_service.dart';
import 'package:f3_nation_app/services/region_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('exports and imports profile, history, and region data', () async {
    final profile = AppProfileService();
    final history = HistoryService();
    final region = RegionService();
    await profile.load();
    await history.load();
    await region.load();

    await profile.completeWelcome(
      role: AppRole.siteQ,
      displayName: 'Digital',
      homeAo: 'The Flag',
      region: 'F3 Test',
      authUserId: 'guest_123',
    );
    await history.add(
      WorkoutHistory(
        id: 'session-1',
        title: 'Saturday Beatdown',
        date: DateTime(2026, 5, 2),
        ao: 'The Flag',
        q: 'Digital',
        pax: const ['Alpha', 'Bravo'],
      ),
    );
    await region.upsertAo(name: 'The Flag');

    final backup = LocalBackupService.exportJson(
      profile: profile,
      history: history,
      region: region,
    );

    SharedPreferences.setMockInitialValues({});
    final importedProfile = AppProfileService();
    final importedHistory = HistoryService();
    final importedRegion = RegionService();
    await importedProfile.load();
    await importedHistory.load();
    await importedRegion.load();

    await LocalBackupService.importJson(
      raw: backup,
      profile: importedProfile,
      history: importedHistory,
      region: importedRegion,
    );

    expect(importedProfile.displayName, 'Digital');
    expect(importedProfile.homeAo, 'The Flag');
    expect(importedProfile.region, 'F3 Test');
    expect(importedHistory.all.single.title, 'Saturday Beatdown');
    expect(importedRegion.aos.single.name, 'The Flag');
  });

  test('rejects unrelated JSON', () async {
    final profile = AppProfileService();
    final history = HistoryService();
    final region = RegionService();
    await profile.load();
    await history.load();
    await region.load();

    expect(
      () => LocalBackupService.importJson(
        raw: '{"app":"something_else"}',
        profile: profile,
        history: history,
        region: region,
      ),
      throwsFormatException,
    );
  });
}
