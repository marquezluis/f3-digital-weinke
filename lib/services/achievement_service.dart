// lib/services/achievement_service.dart
// Derives achievement badges purely from local history data.
// No persistence needed — badges are recomputed from HistoryService on demand.

import '../models/workout_history.dart';

enum AchievementTier { bronze, silver, gold }

class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementTier tier;
  final bool unlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.tier,
    required this.unlocked,
  });
}

/// Running totals used to decide whether each achievement is unlocked.
/// Shared by [AchievementService.compute] (final totals) and
/// [AchievementService.unlockDates] (totals as of each session), so the
/// threshold numbers only live in one place: [_AchievementDef.isUnlocked].
class _Stats {
  int count = 0;
  int streak = 0;
  int murphCount = 0;
  int couponCount = 0;
  int uniquePax = 0;
  int totalFngs = 0;
}

class _AchievementDef {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementTier tier;
  final bool Function(_Stats) isUnlocked;
  /// True for achievements whose unlock state depends on "now" (a current
  /// streak) rather than purely on accumulated session history — these
  /// can't be attributed to the exact session that "caused" them.
  final bool relativeToNow;

  const _AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.tier,
    required this.isUnlocked,
    this.relativeToNow = false,
  });
}

class AchievementService {
  static final List<_AchievementDef> _defs = [
    _AchievementDef(
      id: 'first_beatdown',
      title: 'First Beatdown',
      description: 'Complete your first session.',
      emoji: '🏁',
      tier: AchievementTier.bronze,
      isUnlocked: (s) => s.count >= 1,
    ),
    _AchievementDef(
      id: 'iron_pax',
      title: 'Iron PAX',
      description: 'Complete 10 sessions.',
      emoji: '💪',
      tier: AchievementTier.bronze,
      isUnlocked: (s) => s.count >= 10,
    ),
    _AchievementDef(
      id: 'centurion',
      title: 'Centurion',
      description: 'Complete 100 sessions.',
      emoji: '🏆',
      tier: AchievementTier.gold,
      isUnlocked: (s) => s.count >= 100,
    ),
    _AchievementDef(
      id: 'streak_4',
      title: 'Consistent Q',
      description: '4-week consecutive streak.',
      emoji: '🔥',
      tier: AchievementTier.silver,
      isUnlocked: (s) => s.streak >= 4,
      relativeToNow: true,
    ),
    _AchievementDef(
      id: 'streak_12',
      title: 'Streak Machine',
      description: '12-week consecutive streak.',
      emoji: '⚡',
      tier: AchievementTier.gold,
      isUnlocked: (s) => s.streak >= 12,
      relativeToNow: true,
    ),
    _AchievementDef(
      id: 'murph_warrior',
      title: 'Murph Warrior',
      description: 'Complete a Murph Prep beatdown.',
      emoji: '🪖',
      tier: AchievementTier.silver,
      isUnlocked: (s) => s.murphCount >= 1,
    ),
    _AchievementDef(
      id: 'coupon_grinder',
      title: 'Coupon Grinder',
      description: 'Complete 5 coupon sessions.',
      emoji: '🏋️',
      tier: AchievementTier.bronze,
      isUnlocked: (s) => s.couponCount >= 5,
    ),
    _AchievementDef(
      id: 'fng_welcome',
      title: 'EH Master',
      description: 'Welcome 5 FNGs total.',
      emoji: '🤝',
      tier: AchievementTier.bronze,
      isUnlocked: (s) => s.totalFngs >= 5,
    ),
    _AchievementDef(
      id: 'community',
      title: 'Community Builder',
      description: 'Work out with 20 different PAX.',
      emoji: '🫂',
      tier: AchievementTier.silver,
      isUnlocked: (s) => s.uniquePax >= 20,
    ),
    _AchievementDef(
      id: 'half_century',
      title: 'Half Century',
      description: 'Complete 50 sessions.',
      emoji: '🎖️',
      tier: AchievementTier.silver,
      isUnlocked: (s) => s.count >= 50,
    ),
  ];

  /// Compute all achievements given the current history.
  static List<Achievement> compute(List<WorkoutHistory> history) {
    final stats = _finalStats(history);
    return _defs
        .map((d) => Achievement(
              id: d.id,
              title: d.title,
              description: d.description,
              emoji: d.emoji,
              tier: d.tier,
              unlocked: d.isUnlocked(stats),
            ))
        .toList();
  }

  /// The date each currently-unlocked achievement was first earned, keyed by
  /// achievement id. Reconstructed by replaying sessions chronologically and
  /// noting the session at which each threshold was first crossed — used to
  /// backfill achievement-unlock entries into the activity feed without any
  /// new persistence. Streak achievements ([_AchievementDef.relativeToNow])
  /// can't be reconstructed this way (a streak is relative to today, not a
  /// fixed point in history), so if currently unlocked they're attributed to
  /// the most recent session instead of a historically-accurate date.
  static Map<String, DateTime> unlockDates(List<WorkoutHistory> history) {
    final sessions = history.where((h) => !h.isTemplate).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final dates = <String, DateTime>{};
    if (sessions.isEmpty) return dates;

    final running = _Stats();
    final paxSoFar = <String>{};
    final murphDefs = _defs.where((d) => !d.relativeToNow);
    for (final s in sessions) {
      running.count++;
      if (s.blocks.any((b) => b.label.toLowerCase().contains('murph'))) {
        running.murphCount++;
      }
      if (s.blocks.any((b) => b.category == 'coupon')) {
        running.couponCount++;
      }
      running.totalFngs += s.fngCount;
      paxSoFar.addAll(s.pax);
      running.uniquePax = paxSoFar.length;

      for (final d in murphDefs) {
        if (!dates.containsKey(d.id) && d.isUnlocked(running)) {
          dates[d.id] = s.date;
        }
      }
    }

    final finalStats = _finalStats(history);
    for (final d in _defs.where((d) => d.relativeToNow)) {
      if (d.isUnlocked(finalStats)) {
        dates[d.id] = sessions.last.date;
      }
    }
    return dates;
  }

  static _Stats _finalStats(List<WorkoutHistory> history) {
    final sessions = history.where((h) => !h.isTemplate).toList();
    final allPax = <String>{};
    for (final s in sessions) {
      allPax.addAll(s.pax);
    }
    return _Stats()
      ..count = sessions.length
      ..streak = _weekStreak(sessions)
      ..murphCount = sessions
          .where((s) => s.blocks.any((b) => b.label.toLowerCase().contains('murph')))
          .length
      ..couponCount =
          sessions.where((s) => s.blocks.any((b) => b.category == 'coupon')).length
      ..uniquePax = allPax.length
      ..totalFngs = sessions.fold(0, (sum, s) => sum + s.fngCount);
  }

  static int _weekStreak(List<WorkoutHistory> sessions) {
    if (sessions.isEmpty) return 0;
    final now = DateTime.now();
    final sorted = sessions.map((s) => s.date).toList()
      ..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime check = now;
    for (int w = 0; w < 52; w++) {
      final weekStart = check.subtract(Duration(days: check.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final has = sorted.any((d) =>
          !d.isBefore(weekStart.subtract(const Duration(seconds: 1))) &&
          !d.isAfter(weekEnd.add(const Duration(seconds: 1))));
      if (has) {
        streak++;
        check = weekStart.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}
