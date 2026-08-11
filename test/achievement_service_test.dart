// test/achievement_service_test.dart
// Unit tests for AchievementService.compute (final unlock state) and
// unlockDates (reconstructed unlock dates, used to backfill the activity feed).
// Run with: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/custom_achievement.dart';
import 'package:f3_nation_app/models/workout_history.dart';
import 'package:f3_nation_app/services/achievement_service.dart';

WorkoutHistory _session({
  required DateTime date,
  List<String> pax = const [],
  int fngCount = 0,
  List<HistoryBlock> blocks = const [],
  String ao = '',
}) =>
    WorkoutHistory(
      id: date.toIso8601String(),
      title: 'Beatdown',
      date: date,
      pax: pax,
      fngCount: fngCount,
      blocks: blocks,
      ao: ao,
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

    test('a locked achievement reports current progress toward its target', () {
      final history = List.generate(
        6,
        (i) => _session(date: DateTime(2026, 1, i + 1)),
      );
      final result = AchievementService.compute(history);
      final ironPax = result.firstWhere((a) => a.id == 'iron_pax');
      expect(ironPax.unlocked, isFalse);
      expect(ironPax.currentProgress, 6);
      expect(ironPax.targetProgress, 10);
    });

    test('an unlocked achievement clamps progress at its target, not the raw overshoot', () {
      final history = List.generate(
        15,
        (i) => _session(date: DateTime(2026, 1, i + 1)),
      );
      final result = AchievementService.compute(history);
      final ironPax = result.firstWhere((a) => a.id == 'iron_pax');
      expect(ironPax.unlocked, isTrue);
      expect(ironPax.currentProgress, 10);
      expect(ironPax.targetProgress, 10);
    });

    test(
        'REGRESSION: a streak achievement stays unlocked when nothing has been '
        'posted yet this week, instead of flickering back to locked', () {
      // AchievementService.compute always evaluates against the real
      // DateTime.now() (it has no injectable clock), so the fixture is
      // anchored to it directly: 4 consecutive weeks ending last week, and
      // deliberately nothing in the current, still-open week.
      final now = DateTime.now();
      final history = [
        for (var i = 1; i <= 4; i++) _session(date: now.subtract(Duration(days: 7 * i))),
      ];
      final result = AchievementService.compute(history);
      final streak4 = result.firstWhere((a) => a.id == 'streak_4');
      expect(streak4.unlocked, isTrue,
          reason: '4 consecutive prior weeks should stay earned even with '
              'nothing posted yet in the current, still-open week');
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

  group('AchievementService.computeCustom', () {
    test('unlocks a total-sessions custom achievement at threshold', () {
      final history = List.generate(
        5,
        (i) => _session(date: DateTime(2026, 1, i + 1)),
      );
      const def = CustomAchievement(
        id: 'custom_1',
        title: 'Five-timer',
        thresholdType: CustomAchievementThreshold.totalSessions,
        thresholdValue: 5,
      );

      final badges = AchievementService.computeCustom(history, [def]);

      expect(badges.single.unlocked, isTrue);
      expect(badges.single.isCustom, isTrue);
    });

    test('sessionsAtAo only counts sessions at the matching AO, case-insensitive', () {
      final history = [
        _session(date: DateTime(2026, 1, 1), ao: 'DarkRoast'),
        _session(date: DateTime(2026, 1, 2), ao: 'darkroast'),
        _session(date: DateTime(2026, 1, 3), ao: 'Common Ground'),
      ];
      const def = CustomAchievement(
        id: 'custom_2',
        title: 'DarkRoast Regular',
        thresholdType: CustomAchievementThreshold.sessionsAtAo,
        thresholdValue: 2,
        aoFilter: 'DarkRoast',
      );

      final badges = AchievementService.computeCustom(history, [def]);

      expect(badges.single.unlocked, isTrue);
    });

    test('stays locked below threshold', () {
      final history = [_session(date: DateTime(2026, 1, 1), ao: 'DarkRoast')];
      const def = CustomAchievement(
        id: 'custom_3',
        title: 'DarkRoast Regular',
        thresholdType: CustomAchievementThreshold.sessionsAtAo,
        thresholdValue: 2,
        aoFilter: 'DarkRoast',
      );

      final badges = AchievementService.computeCustom(history, [def]);

      expect(badges.single.unlocked, isFalse);
    });

    test('templates are excluded, matching the built-in achievements', () {
      final history = [
        WorkoutHistory(
          id: 't1',
          title: 'Template',
          date: DateTime(2026, 1, 1),
          isTemplate: true,
        ),
      ];
      const def = CustomAchievement(
        id: 'custom_4',
        title: 'Any session',
        thresholdType: CustomAchievementThreshold.totalSessions,
        thresholdValue: 1,
      );

      final badges = AchievementService.computeCustom(history, [def]);

      expect(badges.single.unlocked, isFalse);
    });
  });
}
