// lib/services/backblast_formatter.dart
// Generates a plain-text backblast matching the F3 Nation standard format.
// Pure Dart — no Flutter dependency.

import '../models/workout_history.dart';

class BackblastFormatter {
  BackblastFormatter._();

  /// Returns the full backblast string ready to paste into Slack / F3 Nation / email.
  static String format(WorkoutHistory h) {
    final buf = StringBuffer();
    final dt = h.date;
    final dateStr = '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)}';
    final aoName = h.ao.isNotEmpty ? h.ao : h.title;

    // ── Header ───────────────────────────────────────────────────────────────
    buf.writeln('Backblast! $aoName');
    buf.writeln('DATE: $dateStr');
    buf.writeln('AO: ${h.ao.isNotEmpty ? h.ao : "—"}');
    buf.writeln('Q: ${h.q.isNotEmpty ? _at(h.q) : "—"}');

    // PAX: @-prefixed, space-separated
    if (h.pax.isEmpty) {
      buf.writeln('PAX: —');
    } else {
      buf.writeln('PAX: ${h.pax.map(_at).join(" ")}');
    }

    buf.writeln('FNGs: ${h.fngCount > 0 ? h.fngCount.toString() : "None"}');
    buf.writeln('COUNT: ${h.totalCount > 0 ? h.totalCount.toString() : "—"}');

    if (h.blocks.isEmpty) {
      buf.writeln();
      buf.writeln('(No workout plan recorded)');
    } else {
      final warmup   = h.blocks.where((b) => b.category == 'warmup').toList();
      final thang    = h.blocks.where((b) => b.category == 'bodyweight' || b.category == 'coupon').toList();
      final mary     = h.blocks.where((b) => b.category == 'mary').toList();

      // ── WARMUP ──────────────────────────────────────────────────────────────
      if (warmup.isNotEmpty) {
        buf.writeln();
        buf.writeln('WARMUP:');
        buf.writeln();
        for (final block in warmup) {
          for (final ex in block.exerciseNames) {
            buf.writeln(ex);
          }
        }
      }

      // ── THE THANG ───────────────────────────────────────────────────────────
      if (thang.isNotEmpty) {
        buf.writeln();
        buf.writeln('THE THANG:');
        for (int i = 0; i < thang.length; i++) {
          final block = thang[i];
          buf.writeln();
          buf.writeln('Part ${i + 1} — ${block.label}');
          buf.writeln();
          if (block.rounds > 1) {
            buf.writeln('${block.rounds} Rounds:');
          }
          for (final ex in block.exerciseNames) {
            buf.writeln(ex);
          }
        }
      }

      // ── MARY ────────────────────────────────────────────────────────────────
      if (mary.isNotEmpty) {
        buf.writeln();
        buf.writeln('MARY:');
        buf.writeln();
        for (final block in mary) {
          for (final ex in block.exerciseNames) {
            buf.writeln(ex);
          }
        }
      }
    }

    // ── ANNOUNCEMENTS ────────────────────────────────────────────────────────
    buf.writeln();
    buf.writeln('ANNOUNCEMENTS:');
    buf.writeln();
    if (h.notes.isNotEmpty) buf.writeln(h.notes);

    // ── COT ─────────────────────────────────────────────────────────────────
    buf.writeln();
    buf.writeln('COT:');
    buf.writeln();
    if (h.cot.isNotEmpty) buf.writeln(h.cot);

    // ── WORD OF THE DAY ──────────────────────────────────────────────────────
    if (h.wotd.isNotEmpty) {
      buf.writeln();
      buf.writeln('WORD OF THE DAY: ${h.wotd}');
    }

    return buf.toString().trimRight();
  }

  static String _at(String name) =>
      name.startsWith('@') ? name : '@$name';

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
