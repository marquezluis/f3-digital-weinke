// test/f3_api_models_test.dart
// Unit tests for F3EventInstance.fromJson's hasPreblast derivation and
// copyWith — the crux of the "Edit Preblast button never showed the posted
// text" bug: calendar-home-schedule sends `hasPreblast` but never the
// preblast text; byId sends the text (and preblastTs) but no `hasPreblast`
// key. Run with: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/f3_api_models.dart';

void main() {
  group('F3EventInstance.fromJson hasPreblast', () {
    test('true from calendar-home-schedule shape (hasPreblast, no text)', () {
      final e = F3EventInstance.fromJson({'id': '1', 'hasPreblast': true});
      expect(e.hasPreblast, isTrue);
      expect(e.preblast, isNull);
    });

    test('false from calendar-home-schedule shape when not posted', () {
      final e = F3EventInstance.fromJson({'id': '1', 'hasPreblast': false});
      expect(e.hasPreblast, isFalse);
    });

    test('true from byId shape (preblastTs set, no hasPreblast key)', () {
      final e = F3EventInstance.fromJson({
        'id': '1',
        'preblast': 'THE PLAN: burpees',
        'preblastTs': 1753142400000,
      });
      expect(e.hasPreblast, isTrue);
      expect(e.preblast, 'THE PLAN: burpees');
    });

    test('false when neither signal nor text is present', () {
      final e = F3EventInstance.fromJson({'id': '1'});
      expect(e.hasPreblast, isFalse);
    });

    test('true when text is present even without an explicit flag', () {
      final e = F3EventInstance.fromJson({'id': '1', 'preblast': 'some plan'});
      expect(e.hasPreblast, isTrue);
    });
  });

  group('F3EventInstance.copyWith', () {
    test('folds a freshly-fetched preblast into a calendar-sourced event', () {
      final fromCalendar = F3EventInstance.fromJson({
        'id': '1',
        'orgName': 'The Ruckus',
        'hasPreblast': true,
      });
      expect(fromCalendar.preblast, isNull);

      final merged = fromCalendar.copyWith(
        preblast: 'THE PLAN: burpees',
        hasPreblast: true,
      );

      expect(merged.preblast, 'THE PLAN: burpees');
      expect(merged.hasPreblast, isTrue);
      expect(merged.orgName, 'The Ruckus'); // untouched fields preserved
      expect(merged.id, fromCalendar.id);
    });

    test('leaves fields unchanged when no overrides are given', () {
      final e = F3EventInstance.fromJson({'id': '1', 'preblast': 'plan'});
      final copy = e.copyWith();
      expect(copy.preblast, e.preblast);
      expect(copy.hasPreblast, e.hasPreblast);
    });
  });
}
