// test/codex_sync_service_test.dart
// Unit tests for the live-Exicon overlay logic — see
// lib/services/codex_sync_service.dart. The network call itself isn't
// exercised here; parseAndMatch is a pure function split out specifically so
// the matching/normalization logic is testable without hitting the network.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:f3_nation_app/models/exercise.dart';
import 'package:f3_nation_app/services/codex_sync_service.dart';
import 'package:f3_nation_app/services/exercise_service.dart';

const _burpee = Exercise(
  id: 'burpee',
  name: 'Burpee',
  description: 'Test',
  aliases: [],
  category: ExerciseCategory.bodyweight,
  equipment: Equipment.none,
  intensity: Intensity.intermediate,
);

const _merkin = Exercise(
  id: 'merkin',
  name: 'Merkin',
  description: 'Test',
  aliases: [],
  category: ExerciseCategory.bodyweight,
  equipment: Equipment.none,
  intensity: Intensity.beginner,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CodexSyncService.normalize', () {
    test('lowercases and trims', () {
      expect(CodexSyncService.normalize('  Burpee  '), 'burpee');
    });
  });

  group('CodexSyncService.parseAndMatch', () {
    test('matches by normalized name and overlays the video link', () {
      final live = [
        {
          'name': ' Burpee ',
          'videoLink': 'https://youtube.com/watch?v=burpee',
        },
      ];
      final result = CodexSyncService.parseAndMatch(live, [_burpee, _merkin]);
      expect(result.videoLinks, {'burpee': 'https://youtube.com/watch?v=burpee'});
      expect(result.liveNames, {'burpee'});
    });

    test('records live names even without a video link, and skips entries '
        'that never matched the app\'s exercise list', () {
      final live = [
        {'name': 'Burpee', 'videoLink': null},
        {'name': 'Some Other Move', 'videoLink': 'https://youtube.com/x'},
      ];
      final result = CodexSyncService.parseAndMatch(live, [_burpee, _merkin]);
      expect(result.videoLinks, isEmpty);
      expect(result.liveNames, {'burpee', 'some other move'});
    });

    test('ignores malformed entries (missing/empty name, wrong type)', () {
      final live = [
        {'videoLink': 'https://youtube.com/x'},
        {'name': '', 'videoLink': 'https://youtube.com/y'},
        'not a map',
      ];
      final result = CodexSyncService.parseAndMatch(live, [_burpee]);
      expect(result.videoLinks, isEmpty);
      expect(result.liveNames, isEmpty);
    });

    test('empty live list yields no matches and no live names', () {
      final result = CodexSyncService.parseAndMatch([], [_burpee, _merkin]);
      expect(result.videoLinks, isEmpty);
      expect(result.liveNames, isEmpty);
    });
  });

  group('CodexSyncService persistence', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('load() is a no-op with nothing previously synced', () async {
      final service = CodexSyncService();
      await service.load();
      expect(service.videoLinksByName, isEmpty);
      expect(service.liveExiconNames, isEmpty);
      expect(service.lastSyncedAt, isNull);
    });
  });

  group('ExerciseService.isOfficial', () {
    test('bundled exercises are always official', () {
      final service = ExerciseService()..injectForTesting([_burpee]);
      expect(service.isOfficial(_burpee), isTrue);
    });

    test('custom exercises start pending', () async {
      SharedPreferences.setMockInitialValues({});
      final service = ExerciseService()..injectForTesting([]);
      final custom = _merkin.withVideoLink(null);
      await service.addCustomExercise(custom);
      expect(service.isOfficial(custom), isFalse);
    });

    test('custom exercises become official once the live Exicon confirms '
        'the same normalized name', () async {
      SharedPreferences.setMockInitialValues({});
      final service = ExerciseService()..injectForTesting([]);
      final custom = _merkin.withVideoLink(null);
      await service.addCustomExercise(custom);

      service.applyLiveExiconNames({'merkin'});
      expect(service.isOfficial(custom), isTrue);
    });
  });

  group('ExerciseService.applyVideoLinks', () {
    test('overlays matched links without touching unmatched exercises', () {
      final service = ExerciseService()..injectForTesting([_burpee, _merkin]);
      service.applyVideoLinks({'burpee': 'https://youtube.com/watch?v=burpee'});

      final burpee = service.all.firstWhere((e) => e.id == 'burpee');
      final merkin = service.all.firstWhere((e) => e.id == 'merkin');
      expect(burpee.videoLink, 'https://youtube.com/watch?v=burpee');
      expect(merkin.videoLink, isNull);
    });

    test('an empty overlay is a no-op', () {
      final service = ExerciseService()..injectForTesting([_burpee]);
      service.applyVideoLinks({});
      expect(service.all.single.videoLink, isNull);
    });
  });
}
