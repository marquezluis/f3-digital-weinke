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

class AchievementService {
  /// Compute all achievements given the current history.
  static List<Achievement> compute(List<WorkoutHistory> history) {
    final sessions = history.where((h) => !h.isTemplate).toList();
    final count = sessions.length;

    // Consecutive week streak
    final streak = _weekStreak(sessions);

    // Murph prep sessions
    final murphCount = sessions.where((s) => s.blocks.any((b) =>
        b.label.toLowerCase().contains('murph'))).length;

    // Sessions with coupons
    final couponCount = sessions.where((s) => s.blocks.any((b) =>
        b.category == 'coupon')).length;

    // Unique PAX encountered
    final allPax = <String>{};
    for (final s in sessions) { allPax.addAll(s.pax); }

    // FNG count
    final totalFngs = sessions.fold(0, (sum, s) => sum + s.fngCount);

    return [
      Achievement(
        id: 'first_beatdown',
        title: 'First Beatdown',
        description: 'Complete your first session.',
        emoji: '🏁',
        tier: AchievementTier.bronze,
        unlocked: count >= 1,
      ),
      Achievement(
        id: 'iron_pax',
        title: 'Iron PAX',
        description: 'Complete 10 sessions.',
        emoji: '💪',
        tier: AchievementTier.bronze,
        unlocked: count >= 10,
      ),
      Achievement(
        id: 'centurion',
        title: 'Centurion',
        description: 'Complete 100 sessions.',
        emoji: '🏆',
        tier: AchievementTier.gold,
        unlocked: count >= 100,
      ),
      Achievement(
        id: 'streak_4',
        title: 'Consistent Q',
        description: '4-week consecutive streak.',
        emoji: '🔥',
        tier: AchievementTier.silver,
        unlocked: streak >= 4,
      ),
      Achievement(
        id: 'streak_12',
        title: 'Streak Machine',
        description: '12-week consecutive streak.',
        emoji: '⚡',
        tier: AchievementTier.gold,
        unlocked: streak >= 12,
      ),
      Achievement(
        id: 'murph_warrior',
        title: 'Murph Warrior',
        description: 'Complete a Murph Prep beatdown.',
        emoji: '🪖',
        tier: AchievementTier.silver,
        unlocked: murphCount >= 1,
      ),
      Achievement(
        id: 'coupon_grinder',
        title: 'Coupon Grinder',
        description: 'Complete 5 coupon sessions.',
        emoji: '🏋️',
        tier: AchievementTier.bronze,
        unlocked: couponCount >= 5,
      ),
      Achievement(
        id: 'fng_welcome',
        title: 'EH Master',
        description: 'Welcome 5 FNGs total.',
        emoji: '🤝',
        tier: AchievementTier.bronze,
        unlocked: totalFngs >= 5,
      ),
      Achievement(
        id: 'community',
        title: 'Community Builder',
        description: 'Work out with 20 different PAX.',
        emoji: '🫂',
        tier: AchievementTier.silver,
        unlocked: allPax.length >= 20,
      ),
      Achievement(
        id: 'half_century',
        title: 'Half Century',
        description: 'Complete 50 sessions.',
        emoji: '🎖️',
        tier: AchievementTier.silver,
        unlocked: count >= 50,
      ),
    ];
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
