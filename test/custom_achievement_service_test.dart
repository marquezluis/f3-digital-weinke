// test/custom_achievement_service_test.dart
// Unit tests for local persistence of Site-Q-authored achievements.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:f3_nation_app/models/custom_achievement.dart';
import 'package:f3_nation_app/services/custom_achievement_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('add persists and reloads across a fresh instance', () async {
    final service = CustomAchievementService();
    await service.load();
    await service.add(
      title: '5 times at DarkRoast',
      thresholdType: CustomAchievementThreshold.sessionsAtAo,
      thresholdValue: 5,
      aoFilter: 'DarkRoast',
    );

    final reloaded = CustomAchievementService();
    await reloaded.load();

    expect(reloaded.all.single.title, '5 times at DarkRoast');
    expect(reloaded.all.single.aoFilter, 'DarkRoast');
    expect(reloaded.all.single.id, startsWith('custom_'));
  });

  test('remove deletes by id and persists', () async {
    final service = CustomAchievementService();
    await service.load();
    await service.add(
      title: 'Test',
      thresholdType: CustomAchievementThreshold.totalSessions,
      thresholdValue: 1,
    );
    final id = service.all.single.id;

    await service.remove(id);

    final reloaded = CustomAchievementService();
    await reloaded.load();
    expect(reloaded.all, isEmpty);
  });
}
