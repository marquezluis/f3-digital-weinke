// test/shared_plan_importer_test.dart
// Unit tests for parsing a Co-Q "share plan" clipboard payload. The
// Clipboard/HistoryService side effects aren't covered here — just the
// pure "is this a valid shared plan, and what does it become" logic.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/workout_history.dart';
import 'package:f3_nation_app/utils/shared_plan_importer.dart';

String _payload(WorkoutHistory entry) =>
    jsonEncode({'app': 'digital_weinke_plan', 'version': 1, 'entry': entry.toJson()});

void main() {
  group('parseSharedPlan', () {
    test('parses a valid payload into an importable template entry', () {
      final original = WorkoutHistory(
        id: 'original-id',
        title: 'Saturday Beatdown',
        date: DateTime(2026, 1, 1),
        ao: 'The Ruckus',
        rating: 1,
        photoPaths: const ['/some/local/path.jpg'],
      );

      final imported = parseSharedPlan(_payload(original));

      expect(imported.title, 'Saturday Beatdown');
      expect(imported.ao, 'The Ruckus');
      // Not a record that this PAX personally ran it — a fresh starting
      // point instead.
      expect(imported.isTemplate, isTrue);
      expect(imported.rating, 0);
      // The sender's local file paths don't exist on this device.
      expect(imported.photoPaths, isEmpty);
      expect(imported.id, isNot('original-id'));
    });

    test('rejects a payload missing the app marker', () {
      final raw = jsonEncode({'version': 1, 'entry': {}});
      expect(() => parseSharedPlan(raw), throwsFormatException);
    });

    test('rejects a payload from a different app', () {
      final raw = jsonEncode({'app': 'some_other_app', 'entry': {}});
      expect(() => parseSharedPlan(raw), throwsFormatException);
    });

    test('rejects malformed JSON', () {
      expect(() => parseSharedPlan('not json at all'), throwsFormatException);
    });
  });
}
