// test/workout_history_test.dart
// Unit tests for WorkoutHistory model, JSON round-trip, and BackblastFormatter.
// Run with: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/workout_history.dart';
import 'package:f3_nation_app/services/backblast_formatter.dart';

void main() {
  // ── HistoryBlock ───────────────────────────────────────────────────────────
  group('HistoryBlock JSON round-trip', () {
    test('serialises and deserialises correctly', () {
      const block = HistoryBlock(
        label: 'Warm-O-Rama',
        category: 'warmup',
        durationMinutes: 7,
        exerciseNames: ['SSH', 'Don Quixote'],
      );
      final json = block.toJson();
      final restored = HistoryBlock.fromJson(json);

      expect(restored.label, block.label);
      expect(restored.category, block.category);
      expect(restored.durationMinutes, block.durationMinutes);
      expect(restored.exerciseNames, block.exerciseNames);
    });

    test('fromJson handles missing fields gracefully', () {
      final block = HistoryBlock.fromJson({});
      expect(block.label, '');
      expect(block.category, 'bodyweight');
      expect(block.durationMinutes, 0);
      expect(block.exerciseNames, isEmpty);
    });
  });

  // ── WorkoutHistory ─────────────────────────────────────────────────────────
  group('WorkoutHistory JSON round-trip', () {
    late WorkoutHistory sample;

    setUp(() {
      sample = WorkoutHistory(
        id: 'abc-123',
        title: 'Test Beatdown',
        date: DateTime(2025, 1, 4, 5, 30),
        ao: 'The Shovel Flag',
        q: 'Dredd',
        pax: ['Mayhem', 'Roscoe', 'Slim Shady'],
        fngCount: 2,
        notes: 'Rainy but PAX delivered.',
        blocks: [
          const HistoryBlock(
            label: 'Warm-O-Rama',
            category: 'warmup',
            durationMinutes: 7,
            exerciseNames: ['SSH'],
          ),
        ],
        completed: true,
      );
    });

    test('toJson / fromJson preserves all fields', () {
      final json = sample.toJson();
      final restored = WorkoutHistory.fromJson(json);

      expect(restored.id, sample.id);
      expect(restored.title, sample.title);
      expect(restored.date.toIso8601String(), sample.date.toIso8601String());
      expect(restored.ao, sample.ao);
      expect(restored.q, sample.q);
      expect(restored.pax, sample.pax);
      expect(restored.fngCount, sample.fngCount);
      expect(restored.notes, sample.notes);
      expect(restored.completed, sample.completed);
      expect(restored.blocks.length, 1);
      expect(restored.blocks.first.label, 'Warm-O-Rama');
    });

    test('toJsonString / fromJsonString round-trip', () {
      final s = sample.toJsonString();
      final restored = WorkoutHistory.fromJsonString(s);
      expect(restored.id, sample.id);
      expect(restored.pax, sample.pax);
    });

    test('fromJson handles missing fields gracefully', () {
      final h = WorkoutHistory.fromJson({});
      expect(h.id, '');
      expect(h.title, 'Beatdown');
      expect(h.pax, isEmpty);
      expect(h.fngCount, 0);
    });

    test('totalCount = pax.length + fngCount', () {
      expect(sample.totalCount, 3 + 2);
    });

    test('paxDisplay joins names with commas', () {
      expect(sample.paxDisplay, 'Mayhem, Roscoe, Slim Shady');
    });

    test('paxDisplay returns dash for empty pax', () {
      final h = WorkoutHistory(
          id: 'x', title: 'X', date: DateTime.now(), pax: const []);
      expect(h.paxDisplay, '—');
    });

    test('shortDate formats correctly', () {
      // 2025-01-04 is a Saturday
      expect(sample.shortDate, 'Sat Jan 4 2025');
    });

    test('copyWith changes only specified fields', () {
      final copy = sample.copyWith(title: 'Modified', fngCount: 0);
      expect(copy.title, 'Modified');
      expect(copy.fngCount, 0);
      expect(copy.id, sample.id);       // unchanged
      expect(copy.pax, sample.pax);    // unchanged
    });

    test('photoPath serialises when present', () {
      final h = sample.copyWith(photoPath: '/data/photo.jpg');
      final json = h.toJson();
      expect(json['photoPath'], '/data/photo.jpg');
      final restored = WorkoutHistory.fromJson(json);
      expect(restored.photoPath, '/data/photo.jpg');
    });

    test('photoPath absent when null', () {
      final json = sample.toJson();
      expect(json.containsKey('photoPath'), isFalse);
    });
  });

  // ── BackblastFormatter ────────────────────────────────────────────────────
  group('BackblastFormatter', () {
    late WorkoutHistory full;

    setUp(() {
      full = WorkoutHistory(
        id: 'fmt-1',
        title: 'Saturday Storm',
        date: DateTime(2025, 3, 15, 5, 30),
        ao: 'Shovel Flag Park',
        q: 'Dredd',
        pax: ['Mayhem', 'Roscoe'],
        fngCount: 1,
        notes: 'Cold and windy but zero quitters.',
        blocks: [
          const HistoryBlock(
            label: 'Warm-O-Rama',
            category: 'warmup',
            durationMinutes: 7,
            exerciseNames: ['SSH', 'Don Quixote', 'Windmill'],
          ),
          const HistoryBlock(
            label: 'The Thang — Bodyweight',
            category: 'bodyweight',
            durationMinutes: 20,
            exerciseNames: ['Merkin', 'Squat'],
          ),
          const HistoryBlock(
            label: 'The Thang — Coupons',
            category: 'coupon',
            durationMinutes: 12,
            exerciseNames: ['Curls for the Girls', 'Overhead Press'],
          ),
          const HistoryBlock(
            label: 'Mary',
            category: 'mary',
            durationMinutes: 6,
            exerciseNames: ['LBC', 'Flutter'],
          ),
        ],
      );
    });

    test('contains title', () {
      final text = BackblastFormatter.format(full);
      expect(text, contains('Saturday Storm'));
    });

    test('contains date', () {
      final text = BackblastFormatter.format(full);
      expect(text, contains('Mar 15 2025'));
    });

    test('contains AO', () {
      final text = BackblastFormatter.format(full);
      expect(text, contains('Shovel Flag Park'));
    });

    test('contains Q name', () {
      final text = BackblastFormatter.format(full);
      expect(text, contains('Dredd'));
    });

    test('contains PAX names', () {
      final text = BackblastFormatter.format(full);
      expect(text, contains('Mayhem'));
      expect(text, contains('Roscoe'));
    });

    test('FNG count shown as number when > 0', () {
      final text = BackblastFormatter.format(full);
      expect(text, contains('FNG: 1'));
    });

    test('FNG shown as None when 0', () {
      final h = full.copyWith(fngCount: 0);
      final text = BackblastFormatter.format(h);
      expect(text, contains('FNG: None'));
    });

    test('count includes FNG', () {
      // pax = 2, fng = 1 → total = 3
      final text = BackblastFormatter.format(full);
      expect(text, contains('Count: 3'));
    });

    test('warmup exercises appear', () {
      final text = BackblastFormatter.format(full);
      expect(text, contains('SSH'));
    });

    test('bodyweight exercises appear', () {
      final text = BackblastFormatter.format(full);
      expect(text, contains('Merkin'));
    });

    test('coupon exercises appear', () {
      final text = BackblastFormatter.format(full);
      expect(text, contains('Curls for the Girls'));
    });

    test('mary exercises appear', () {
      final text = BackblastFormatter.format(full);
      expect(text, contains('LBC'));
    });

    test('notes appear when present', () {
      final text = BackblastFormatter.format(full);
      expect(text, contains('Cold and windy but zero quitters.'));
    });

    test('notes section absent when empty', () {
      final h = full.copyWith(notes: '');
      final text = BackblastFormatter.format(h);
      expect(text.contains('*Notes:*'), isFalse);
    });

    test('shows dashes for missing AO and Q', () {
      final h = WorkoutHistory(
        id: 'x',
        title: 'Minimal',
        date: DateTime(2025, 1, 1),
      );
      final text = BackblastFormatter.format(h);
      expect(text, contains('AO: —'));
      expect(text, contains('Q: —'));
    });

    test('exercise list truncates at 8 with ellipsis', () {
      final manyExercises = List.generate(10, (i) => 'Exercise$i');
      final h = WorkoutHistory(
        id: 'trunc',
        title: 'Truncation Test',
        date: DateTime(2025, 1, 1),
        blocks: [
          HistoryBlock(
            label: 'Warm-O-Rama',
            category: 'warmup',
            durationMinutes: 7,
            exerciseNames: manyExercises,
          ),
        ],
      );
      final text = BackblastFormatter.format(h);
      expect(text, contains('…'));
      // Only first 8 should appear as separate tokens
      expect(text, contains('Exercise0'));
      expect(text, contains('Exercise7'));
      expect(text, isNot(contains('Exercise9')));
    });

    test('empty blocks falls back to placeholder line', () {
      final h = WorkoutHistory(
          id: 'empty', title: 'No Plan', date: DateTime(2025, 1, 1));
      final text = BackblastFormatter.format(h);
      expect(text, contains('No workout plan recorded'));
    });

    test('footer present', () {
      final text = BackblastFormatter.format(full);
      expect(text, contains('Digital Weinke'));
    });

    test('disclaimer/COT line present', () {
      final text = BackblastFormatter.format(full);
      expect(text, contains('Disclaimer given'));
    });
  });
}
