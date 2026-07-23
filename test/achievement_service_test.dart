// test/achievement_service_test.dart
// Unit tests for AchievementService.compute (final unlock state) and
// unlockDates (reconstructed unlock dates, used to backfill the activity feed).
// Run with: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/workout_history.dart';
import 'package:f3_nation_app/services/achievement_service.dart';

WorkoutHistory _session({
  required DateTime date,
  List<String> pax = const [],
  int fngCount = 0,
  List<HistoryBlock> blocks = const [],
}) =>
    WorkoutHistory(
      id: date.toIso8601String(),
      title: 'Beatdown',
      date: date,
      pax: pax,
      fngCount: fngCount,
      blocks: blocks,
    );

void main() {
  group('AchievementService.compute', () {
    test('first_beatdown unlocks after one session', () {
      final result = AchievementService.compute([
        _session(date: DateTime(2026, 1, 1)),
      ]);
      final first = result.firstWhere((a) => a.id == 'first_beatdown');
      expect(first.unlocked, isTrue);
    });

    test('iron_pax stays locked below 10 sessions', () {
      final history = List.generate(
        9,
        (i) => _session(date: DateTime(2026, 1, i + 1)),
      );
      final result = AchievementService.compute(history);
      final ironPax = result.firstWhere((a) => a.id == 'iron_pax');
      expect(ironPax.unlocked, isFalse);
    });

    test('templates are excluded from every count', () {
      final result = AchievementService.compute([
        WorkoutHistory(
          id: 't1',
          title: 'Template',
          date: DateTime(2026, 1, 1),
          isTemplate: true,
        ),
      ]);
      final first = result.firstWhere((a) => a.id == 'first_beatdown');
      expect(first.unlocked, isFalse);
    });
  });

  group('AchievementService.unlockDates', () {
    test('attributes first_beatdown to the earliest session', () {
      final dates = AchievementService.unlockDates([
        _session(date: DateTime(2026, 3, 1)),
        _session(date: DateTime(2026, 1, 1)),
      ]);
      expect(dates['first_beatdown'], DateTime(2026, 1, 1));
    });

    test('attributes iron_pax to the 10th session chronologically', () {
      final history = List.generate(
        12,
        (i) => _session(date: DateTime(2026, 1, i + 1)),
      );
      final dates = AchievementService.unlockDates(history);
      expect(dates['iron_pax'], DateTime(2026, 1, 10));
      expect(dates.containsKey('centurion'), isFalse);
    });

    test('attributes community builder to the session crossing 20 unique PAX', () {
      final history = List.generate(
        20,
        (i) => _session(
          date: DateTime(2026, 1, i + 1),
          pax: ['PAX$i'],
        ),
      );
      final dates = AchievementService.unlockDates(history);
      expect(dates['community'], DateTime(2026, 1, 20));
    });

    test('streak achievements are attributed to the most recent session, not reconstructed', () {
      final now = DateTime.now();
      final history = [
        _session(date: now),
        _session(date: now.subtract(const Duration(days: 7))),
        _session(date: now.subtract(const Duration(days: 14))),
        _session(date: now.subtract(const Duration(days: 21))),
      ];
      final dates = AchievementService.unlockDates(history);
      final sorted = [...history]..sort((a, b) => a.date.compareTo(b.date));
      expect(dates['streak_4'], sorted.last.date);
    });

    test('returns no dates for an empty history', () {
      expect(AchievementService.unlockDates([]), isEmpty);
    });
  });
}
