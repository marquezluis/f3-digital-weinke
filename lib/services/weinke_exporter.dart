// lib/services/weinke_exporter.dart
// Formats a WorkoutPlan as a shareable plain-text Weinke.
//
// Output structure mirrors the F3 Q Cheat Sheet format:
//   Header
//   DISCLAIMER
//   per-block sections (label, duration, rounds, exercises)
//   COT
//
// Each exercise line shows the F3 name and a concise action hint derived from
// the exercise description.

import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/workout_plan.dart';
import '../models/workout_settings.dart';
import 'exercise_service.dart';

class WeinkeExporter {
  static const _divider = '─────────────────────────────────────────';
  static const _thick = '═════════════════════════════════════════';

  static String format(WorkoutPlan plan) {
    final buf = StringBuffer();
    final dt = plan.generatedAt;
    final dateStr =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    // ── Header ────────────────────────────────────────────────────────────────
    buf.writeln(_thick);
    buf.writeln('  DIGITAL WEINKE  ·  $dateStr  $timeStr');
    buf.writeln('  ${plan.settings.durationMinutes} min  ·  '
        '${plan.allExercises.length} exercises  ·  '
        '${plan.blocks.length} blocks');
    buf.writeln(_thick);
    buf.writeln();

    // ── Disclaimer ────────────────────────────────────────────────────────────
    buf.writeln('DISCLAIMER  (1 min)');
    buf.writeln(
        '"I am not a professional. Modify as needed. Participation is voluntary."');
    buf.writeln();

    // ── Exercise blocks ───────────────────────────────────────────────────────
    for (final block in plan.blocks) {
      buf.writeln(_divider);
      final roundsLabel =
          block.rounds > 1 ? '  ·  ${block.rounds} ROUNDS' : '';
      buf.writeln(
          '${block.label.toUpperCase()}  (${block.durationMinutes} min$roundsLabel)');
      if (block.notes.isNotEmpty) {
        buf.writeln(block.notes);
      }
      buf.writeln(_divider);

      if (block.exercises.isEmpty) {
        buf.writeln('  (no exercises)');
      } else {
        for (int i = 0; i < block.exercises.length; i++) {
          final ex = block.exercises[i];
          final num = '${i + 1}.'.padRight(3);
          final hint = _hint(ex);
          if (hint.isNotEmpty) {
            buf.writeln('  $num ${ex.name}');
            buf.writeln('       ↳ $hint');
          } else {
            buf.writeln('  $num ${ex.name}');
          }
        }
        if (block.rounds > 1) {
          buf.writeln();
          buf.writeln('  ↺ Repeat all ${block.exercises.length} exercises '
              '× ${block.rounds} rounds');
        }
      }
      buf.writeln();
    }

    // ── COT ───────────────────────────────────────────────────────────────────
    buf.writeln(_divider);
    buf.writeln('COT  (4 min)');
    buf.writeln(_divider);
    buf.writeln('  Count-O-Rama  ·  Name-O-Rama  ·  FNG Naming');
    buf.writeln('  Announcements  ·  Closing Word  ·  Prayer');
    buf.writeln();
    buf.writeln(_thick);
    buf.writeln('  F3 — Fitness, Fellowship, Faith');
    buf.writeln(_thick);

    return buf.toString();
  }

  /// Preblast format — posted before the beatdown to announce the plan.
  static String formatPreblast(
    WorkoutPlan plan, {
    String ao = '',
    String time = '0530',
    String qName = '',
  }) {
    final buf = StringBuffer();
    final dt = plan.generatedAt;
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dayStr = '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}';

    final aoLabel = ao.isNotEmpty ? ao : 'TBD';

    buf.writeln('Preblast: $aoLabel');
    buf.writeln('Date: $dayStr');
    buf.writeln('Time: ${time.isNotEmpty ? time : "0530"}');
    buf.writeln('Where: $aoLabel');
    buf.writeln('Event Type: Bootcamp');
    if (qName.isNotEmpty) buf.writeln('Q: @$qName');
    buf.writeln();

    // THE PLAN — list phases + block labels
    buf.writeln('THE PLAN:');
    buf.writeln();
    buf.writeln('DISCLAIMER  (1 min)');
    for (final block in plan.blocks) {
      final roundsLabel = block.rounds > 1 ? '  ·  ${block.rounds} rounds' : '';
      buf.writeln('${block.label}  (${block.durationMinutes} min$roundsLabel)');
      for (final ex in block.exercises) {
        buf.writeln('  - ${ex.name}');
      }
      buf.writeln();
    }
    buf.writeln('COT  (4 min)');
    buf.writeln();

    // Coupon indicator
    final hasCoupon = plan.blocks.any((b) => b.category.name == 'coupon');
    buf.writeln('COUPON: ${hasCoupon ? "Yes — bring your brick/sandbag" : "No coupon today"}');

    return buf.toString().trimRight();
  }

  /// Just the block-by-block plan body, no header — used to seed a real F3
  /// event's preblast "The Plan" field, where AO/date/time/Q are already
  /// known from the event itself and shouldn't be re-typed or guessed.
  ///
  /// The trailing `[category]` tag on each block header is what makes
  /// [parseSummary] a reliable reverse of this — as long as this text is
  /// always machine-generated (never hand-typed/edited), rebuilding the
  /// Weinke from a posted preblast becomes a deterministic parse of our own
  /// format instead of an unreliable guess at arbitrary prose.
  static String planSummaryOnly(WorkoutPlan plan) {
    final buf = StringBuffer();
    for (final block in plan.blocks) {
      final roundsLabel = block.rounds > 1 ? '  · ${block.rounds} rounds' : '';
      buf.writeln(
          '${block.label} (${block.durationMinutes} min$roundsLabel) [${block.category.name}]');
      for (final ex in block.exercises) {
        buf.writeln('- ${ex.name}');
      }
      buf.writeln();
    }
    return buf.toString().trimRight();
  }

  static final _blockHeaderRe = RegExp(
    r'^(.+?)\s*\((\d+)\s*min(?:\s*·\s*(\d+)\s*rounds)?\)\s*\[(\w+)\]$',
  );

  /// Reverses [planSummaryOnly]. Returns null if [text] doesn't contain at
  /// least one recognizable block header — e.g. hand-typed prose from
  /// before this format existed, which this deliberately does not attempt
  /// to guess-parse.
  static WorkoutPlan? parseSummary(String text, ExerciseService service) {
    final blocks = <WorkoutBlock>[];
    String? label;
    int duration = 0;
    int rounds = 1;
    ExerciseCategory category = ExerciseCategory.bodyweight;
    var exercises = <Exercise>[];

    void flush() {
      if (label == null) return;
      blocks.add(WorkoutBlock(
        label: label,
        category: category,
        exercises: exercises,
        durationMinutes: duration,
        rounds: rounds,
      ));
    }

    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final m = _blockHeaderRe.firstMatch(line);
      if (m != null) {
        flush();
        label = m.group(1);
        duration = int.tryParse(m.group(2) ?? '') ?? 0;
        rounds = int.tryParse(m.group(3) ?? '') ?? 1;
        category = ExerciseCategory.fromString(m.group(4) ?? '');
        exercises = [];
      } else if (line.startsWith('- ')) {
        exercises.add(_resolveExercise(line.substring(2).trim(), service));
      }
    }
    flush();
    if (blocks.isEmpty) return null;
    return WorkoutPlan(
      id: const Uuid().v4(),
      generatedAt: DateTime.now(),
      blocks: blocks,
    );
  }

  /// Matches a parsed exercise name against the real catalog (name or
  /// alias, case-insensitive) so it keeps its real description/hint/
  /// equipment; falls back to a lightweight ad-hoc entry (same idea as a
  /// custom exercise) so an unrecognized name still shows up in the block
  /// instead of silently vanishing.
  static Exercise _resolveExercise(String name, ExerciseService service) {
    final lower = name.toLowerCase();
    for (final ex in service.all) {
      if (ex.name.toLowerCase() == lower ||
          ex.aliases.any((a) => a.toLowerCase() == lower)) {
        return ex;
      }
    }
    return Exercise(
      id: 'parsed-${name.hashCode}',
      name: name,
      description: '',
      aliases: const [],
      category: ExerciseCategory.bodyweight,
      equipment: Equipment.none,
      intensity: Intensity.intermediate,
    );
  }

  static bool hasCoupon(WorkoutPlan plan) =>
      plan.blocks.any((b) => b.category == ExerciseCategory.coupon);

  /// Infers which [CouponMode] a loaded/parsed plan actually reflects.
  ///
  /// CouponMode is a persisted *global* preference (WorkoutSettings), not a
  /// property of any one plan — so after [parseSummary] preloads someone
  /// else's existing plan as the draft, the coupon-mode dropdown otherwise
  /// keeps showing whatever this device's own last preference was, with no
  /// connection to what's actually in the loaded blocks. That mismatch is
  /// dangerous, not just confusing: hitting "Regenerate" would silently
  /// apply the wrong mode to a plan the Q thinks they're just tweaking.
  /// Returns null when the structure doesn't clearly match one mode (rare —
  /// e.g. a custom-edited plan with an odd block mix), in which case the
  /// caller should leave the existing preference alone rather than guess.
  static CouponMode? inferCouponMode(WorkoutPlan plan) {
    final thangBlocks = plan.blocks
        .where((b) =>
            (b.category == ExerciseCategory.bodyweight ||
                b.category == ExerciseCategory.coupon) &&
            b.exercises.isNotEmpty)
        .toList();
    if (thangBlocks.isEmpty) return null;

    bool hasBoth(WorkoutBlock b) =>
        b.exercises.any((e) => e.category == ExerciseCategory.bodyweight) &&
        b.exercises.any((e) => e.category == ExerciseCategory.coupon);
    if (thangBlocks.any(hasBoth)) return CouponMode.mixedInterleaved;

    final hasBwOnly = thangBlocks.any(
        (b) => b.exercises.every((e) => e.category != ExerciseCategory.coupon));
    final hasCouponOnly = thangBlocks.any(
        (b) => b.exercises.every((e) => e.category == ExerciseCategory.coupon));

    if (hasBwOnly && hasCouponOnly) return CouponMode.mixed;
    if (hasCouponOnly) return CouponMode.coupons;
    if (hasBwOnly) return CouponMode.noCoupons;
    return null;
  }

  // Derive a short action hint from the exercise description.
  static String _hint(Exercise ex) {
    final desc = ex.description;
    if (desc.isEmpty) return '';
    // Take the first sentence (up to the first period or 80 chars).
    final period = desc.indexOf('.');
    final raw = period > 0 && period < 90 ? desc.substring(0, period) : desc;
    final trimmed = raw.trim();
    return trimmed.length > 85 ? '${trimmed.substring(0, 82)}…' : trimmed;
  }
}
