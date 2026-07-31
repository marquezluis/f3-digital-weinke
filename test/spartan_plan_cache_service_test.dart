// test/spartan_plan_cache_service_test.dart
// Unit tests for the offline fallback cache backing Spartan's "build me a
// Weinke" flow — see lib/services/spartan_plan_cache_service.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:f3_nation_app/services/spartan_plan_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('randomCached returns null when nothing has ever been cached',
      () async {
    final service = SpartanPlanCacheService();
    expect(await service.randomCached(), isNull);
  });

  test('caches a successful generation and can read it back', () async {
    final service = SpartanPlanCacheService();
    await service.cache('leg day', [
      {
        'label': 'The Thang',
        'category': 'bodyweight',
        'rounds': 1,
        'durationMinutes': 20,
        'exercises': [
          {'name': 'Squat'}
        ],
      },
    ]);

    final loaded = await service.load();
    expect(loaded.single.label, 'leg day');
    expect(loaded.single.blocksJson, hasLength(1));
  });

  test('ignores an empty blocks list — nothing worth caching', () async {
    final service = SpartanPlanCacheService();
    await service.cache('empty', const []);
    expect(await service.load(), isEmpty);
  });

  test('rotates out the oldest entry beyond maxEntries, newest first',
      () async {
    final service = SpartanPlanCacheService();
    for (var i = 0; i < SpartanPlanCacheService.maxEntries + 2; i++) {
      await service.cache('plan $i', [
        {
          'label': 'Block',
          'category': 'bodyweight',
          'rounds': 1,
          'durationMinutes': 10,
          'exercises': [
            {'name': 'Merkins'}
          ],
        },
      ]);
    }

    final loaded = await service.load();
    expect(loaded.length, SpartanPlanCacheService.maxEntries);
    // Newest goes in front; the two oldest ("plan 0", "plan 1") should have
    // been rotated out.
    expect(loaded.first.label, 'plan ${SpartanPlanCacheService.maxEntries + 1}');
    expect(loaded.map((e) => e.label), isNot(contains('plan 0')));
    expect(loaded.map((e) => e.label), isNot(contains('plan 1')));
  });
}
