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

import '../models/exercise.dart';
import '../models/workout_plan.dart';

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
  static String planSummaryOnly(WorkoutPlan plan) {
    final buf = StringBuffer();
    for (final block in plan.blocks) {
      final roundsLabel = block.rounds > 1 ? '  · ${block.rounds} rounds' : '';
      buf.writeln('${block.label} (${block.durationMinutes} min$roundsLabel)');
      for (final ex in block.exercises) {
        buf.writeln('- ${ex.name}');
      }
      buf.writeln();
    }
    return buf.toString().trimRight();
  }

  static bool hasCoupon(WorkoutPlan plan) =>
      plan.blocks.any((b) => b.category == ExerciseCategory.coupon);

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
