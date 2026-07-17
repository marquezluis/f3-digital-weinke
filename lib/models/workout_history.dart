// lib/models/workout_history.dart
// Represents a saved/completed F3 beatdown session.
// Pure Dart — no Flutter dependency.  JSON round-trips for shared_preferences.

import 'dart:convert';

/// Beatdown types shown in the app. [storageValue] is our own local JSON
/// format (stable — do not change existing entries' strings, or previously
/// saved history silently falls back to bootCamp on load). [f3EventType] is
/// the real F3 Nation API `event_type` value, confirmed against
/// packages/shared/src/app/enums.ts (EventTypes) in the F3-Nation/f3-nation
/// monorepo — used only when actually calling their API, e.g. publishing a
/// backblast. [other] has no F3 Nation equivalent (f3EventType is null); a
/// real category must be picked before publishing to F3 Nation.
enum BeatdownType {
  bootCamp,
  ruck,
  run,
  bike,
  swim,
  other,
  qsource,
  mobility,
  gear,
  wildCard,
  sports;

  String get displayName => switch (this) {
    BeatdownType.bootCamp => 'Boot Camp',
    BeatdownType.ruck     => 'Ruck',
    BeatdownType.run      => 'Run',
    BeatdownType.bike     => 'Bike',
    BeatdownType.swim     => 'Swim',
    BeatdownType.other    => 'Other',
    BeatdownType.qsource  => 'QSource',
    BeatdownType.mobility => 'Mobility',
    BeatdownType.gear     => 'Gear',
    BeatdownType.wildCard => 'Wild Card',
    BeatdownType.sports   => 'Sports',
  };

  String get storageValue => switch (this) {
    BeatdownType.bootCamp => 'Boot Camp',
    BeatdownType.ruck     => 'Ruck',
    BeatdownType.run      => 'Run',
    BeatdownType.bike     => 'Bike',
    BeatdownType.swim     => 'Swim',
    BeatdownType.other    => 'Other',
    BeatdownType.qsource  => 'QSource',
    BeatdownType.mobility => 'Mobility',
    BeatdownType.gear     => 'Gear',
    BeatdownType.wildCard => 'Wild Card',
    BeatdownType.sports   => 'Sports',
  };

  /// The real F3 Nation `event_type` string, or null for [other] (which has
  /// no F3 Nation equivalent).
  String? get f3EventType => switch (this) {
    BeatdownType.bootCamp => 'Bootcamp',
    BeatdownType.ruck     => 'Ruck',
    BeatdownType.run      => 'Run',
    BeatdownType.bike     => 'Bike',
    BeatdownType.swim     => 'Swimming',
    BeatdownType.other    => null,
    BeatdownType.qsource  => 'QSource',
    BeatdownType.mobility => 'Mobility',
    BeatdownType.gear     => 'Gear',
    BeatdownType.wildCard => 'Wild Card',
    BeatdownType.sports   => 'Sports',
  };

  static BeatdownType fromString(String? value) => switch (value) {
    'Boot Camp' => BeatdownType.bootCamp,
    'Ruck'      => BeatdownType.ruck,
    'Run'       => BeatdownType.run,
    'Bike'      => BeatdownType.bike,
    'Swim'      => BeatdownType.swim,
    'QSource'   => BeatdownType.qsource,
    'Mobility'  => BeatdownType.mobility,
    'Gear'      => BeatdownType.gear,
    'Wild Card' => BeatdownType.wildCard,
    'Sports'    => BeatdownType.sports,
    _           => BeatdownType.bootCamp,
  };
}

/// F3 Nation event tags — confirmed against the EVENT_TAGS seed data in
/// packages/db/src/local-seed-lib/data.ts in the F3-Nation/f3-nation
/// monorepo. Optional; most events have none.
enum EventTag {
  vq,
  convergence,
  f3versary,
  preWorkout,
  offTheBooks;

  String get displayName => switch (this) {
    EventTag.vq          => 'VQ',
    EventTag.convergence => 'Convergence',
    EventTag.f3versary   => 'F3versary',
    EventTag.preWorkout  => 'Pre-Workout',
    EventTag.offTheBooks => 'Off-The-Books',
  };

  static EventTag? fromString(String? value) => switch (value) {
    'VQ'            => EventTag.vq,
    'Convergence'   => EventTag.convergence,
    'F3versary'     => EventTag.f3versary,
    'Pre-Workout'   => EventTag.preWorkout,
    'Off-The-Books' => EventTag.offTheBooks,
    _               => null,
  };
}

/// Snapshot of a workout block sufficient for backblast rendering.
/// We store just label + exercise names so we don't drag in the full
/// Exercise graph (and can serialise cleanly).
class HistoryBlock {
  final String label;       // e.g. "Warm-O-Rama", "The Thang — Bodyweight"
  final String category;    // warmup | bodyweight | coupon | mary
  final int durationMinutes;
  final List<String> exerciseNames;
  final int rounds;         // number of rounds (default 1)

  const HistoryBlock({
    required this.label,
    required this.category,
    required this.durationMinutes,
    required this.exerciseNames,
    this.rounds = 1,
  });

  factory HistoryBlock.fromJson(Map<String, dynamic> json) => HistoryBlock(
        label: json['label'] as String? ?? '',
        category: json['category'] as String? ?? 'bodyweight',
        durationMinutes: json['durationMinutes'] as int? ?? 0,
        exerciseNames: (json['exerciseNames'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        rounds: json['rounds'] as int? ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'category': category,
        'durationMinutes': durationMinutes,
        'exerciseNames': exerciseNames,
        'rounds': rounds,
      };
}

/// A full saved beatdown session.
class WorkoutHistory {
  final String id;
  final String title;
  final DateTime date;
  final String ao;          // Area of Operations / location
  final String q;           // Q's name
  final List<String> pax;   // PAX names
  final int fngCount;       // First Time Guys
  final String notes;       // announcements / general observations
  final String cot;         // Closing Time / prayer / COT word
  final String wotd;        // Word of the Day
  final List<HistoryBlock> blocks; // plan summary
  final bool completed;     // false while in-progress (future use)
  final String? photoPath;  // placeholder — camera not yet implemented
  // 0 = unrated, 1 = thumbs-up (great session), -1 = thumbs-down (rough one)
  final int rating;
  // When true, this entry is a saved template (reusable plan, not a past session)
  final bool isTemplate;
  /// F3 Nation event type — matches the API's event_type values.
  final BeatdownType beatdownType;
  /// Optional F3 Nation event tag (VQ, Convergence, etc.). Null = no tag.
  final EventTag? eventTag;
  /// Real wall-clock minutes the Q Mode timer actually ran, if this session
  /// was run live. Null for plans saved without running the timer. This is
  /// the true time invested, distinct from the planned block minutes.
  final int? actualDurationMinutes;

  const WorkoutHistory({
    required this.id,
    required this.title,
    required this.date,
    this.ao = '',
    this.q = '',
    this.pax = const [],
    this.fngCount = 0,
    this.notes = '',
    this.cot = '',
    this.wotd = '',
    this.blocks = const [],
    this.completed = true,
    this.photoPath,
    this.rating = 0,
    this.isTemplate = false,
    this.beatdownType = BeatdownType.bootCamp,
    this.eventTag,
    this.actualDurationMinutes,
  });

  // ── Serialization ──────────────────────────────────────────────────────────

  factory WorkoutHistory.fromJson(Map<String, dynamic> json) => WorkoutHistory(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Beatdown',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        ao: json['ao'] as String? ?? '',
        q: json['q'] as String? ?? '',
        pax: (json['pax'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        fngCount: json['fngCount'] as int? ?? 0,
        notes: json['notes'] as String? ?? '',
        cot: json['cot'] as String? ?? '',
        wotd: json['wotd'] as String? ?? '',
        blocks: (json['blocks'] as List<dynamic>?)
                ?.map((b) =>
                    HistoryBlock.fromJson(b as Map<String, dynamic>))
                .toList() ??
            [],
        completed: json['completed'] as bool? ?? true,
        photoPath: json['photoPath'] as String?,
        rating: json['rating'] as int? ?? 0,
        isTemplate: json['isTemplate'] as bool? ?? false,
        beatdownType: BeatdownType.fromString(json['beatdownType'] as String?),
        eventTag: EventTag.fromString(json['eventTag'] as String?),
        actualDurationMinutes: json['actualDurationMinutes'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'ao': ao,
        'q': q,
        'pax': pax,
        'fngCount': fngCount,
        'notes': notes,
        'cot': cot,
        'wotd': wotd,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'completed': completed,
        if (photoPath != null) 'photoPath': photoPath,
        'rating': rating,
        'isTemplate': isTemplate,
        'beatdownType': beatdownType.storageValue,
        if (eventTag != null) 'eventTag': eventTag!.displayName,
        if (actualDurationMinutes != null)
          'actualDurationMinutes': actualDurationMinutes,
      };

  /// Encode to a JSON string (for storage).
  String toJsonString() => jsonEncode(toJson());

  /// Decode from a JSON string.
  static WorkoutHistory fromJsonString(String raw) =>
      WorkoutHistory.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Total PAX including FNGs.
  int get totalCount => pax.length + fngCount;

  /// Comma-joined PAX string (for display / backblast).
  String get paxDisplay => pax.isEmpty ? '—' : pax.join(', ');

  /// Short date string: "Sat Jan 4 2025".
  String get shortDate {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[date.weekday - 1]} ${months[date.month - 1]} ${date.day} ${date.year}';
  }

  /// Copy-with for edits.
  WorkoutHistory copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? ao,
    String? q,
    List<String>? pax,
    int? fngCount,
    String? notes,
    String? cot,
    List<HistoryBlock>? blocks,
    bool? completed,
    String? photoPath,
    int? rating,
    bool? isTemplate,
    BeatdownType? beatdownType,
    EventTag? eventTag,
    int? actualDurationMinutes,
  }) =>
      WorkoutHistory(
        id: id ?? this.id,
        title: title ?? this.title,
        date: date ?? this.date,
        ao: ao ?? this.ao,
        q: q ?? this.q,
        pax: pax ?? this.pax,
        fngCount: fngCount ?? this.fngCount,
        notes: notes ?? this.notes,
        cot: cot ?? this.cot,
        blocks: blocks ?? this.blocks,
        completed: completed ?? this.completed,
        photoPath: photoPath ?? this.photoPath,
        rating: rating ?? this.rating,
        isTemplate: isTemplate ?? this.isTemplate,
        beatdownType: beatdownType ?? this.beatdownType,
        eventTag: eventTag ?? this.eventTag,
        actualDurationMinutes:
            actualDurationMinutes ?? this.actualDurationMinutes,
      );
}
