// lib/models/custom_achievement.dart
// A Site-Q-defined local achievement — e.g. "5 times at DarkRoast." Unlike
// the built-in badges in achievement_service.dart (fixed Dart predicates),
// these need a serializable, declarative unlock condition since a PAX
// authors them at runtime.

enum CustomAchievementThreshold {
  totalSessions,
  sessionsAtAo,
  uniquePax,
  fngsWelcomed;

  String get displayName {
    switch (this) {
      case CustomAchievementThreshold.totalSessions:
        return 'Total sessions';
      case CustomAchievementThreshold.sessionsAtAo:
        return 'Sessions at one AO';
      case CustomAchievementThreshold.uniquePax:
        return 'Different PAX worked out with';
      case CustomAchievementThreshold.fngsWelcomed:
        return 'FNGs welcomed';
    }
  }

  static CustomAchievementThreshold fromString(String value) => switch (value) {
        'sessionsAtAo' => CustomAchievementThreshold.sessionsAtAo,
        'uniquePax' => CustomAchievementThreshold.uniquePax,
        'fngsWelcomed' => CustomAchievementThreshold.fngsWelcomed,
        _ => CustomAchievementThreshold.totalSessions,
      };
}

class CustomAchievement {
  final String id;
  final String title;
  final String emoji;
  final CustomAchievementThreshold thresholdType;
  final int thresholdValue;
  // Only meaningful for sessionsAtAo — matched case-insensitively against
  // WorkoutHistory.ao.
  final String? aoFilter;

  const CustomAchievement({
    required this.id,
    required this.title,
    this.emoji = '🎖️',
    required this.thresholdType,
    required this.thresholdValue,
    this.aoFilter,
  });

  String get description {
    switch (thresholdType) {
      case CustomAchievementThreshold.totalSessions:
        return 'Complete $thresholdValue sessions.';
      case CustomAchievementThreshold.sessionsAtAo:
        final ao = (aoFilter ?? '').isEmpty ? 'this AO' : aoFilter;
        return 'Complete $thresholdValue sessions at $ao.';
      case CustomAchievementThreshold.uniquePax:
        return 'Work out with $thresholdValue different PAX.';
      case CustomAchievementThreshold.fngsWelcomed:
        return 'Welcome $thresholdValue FNGs total.';
    }
  }

  factory CustomAchievement.fromJson(Map<String, dynamic> json) =>
      CustomAchievement(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Custom Achievement',
        emoji: json['emoji'] as String? ?? '🎖️',
        thresholdType: CustomAchievementThreshold.fromString(
            json['thresholdType'] as String? ?? ''),
        thresholdValue: json['thresholdValue'] as int? ?? 1,
        aoFilter: json['aoFilter'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'thresholdType': thresholdType.name,
        'thresholdValue': thresholdValue,
        if (aoFilter != null) 'aoFilter': aoFilter,
      };
}
