// test/ao_milestones_test.dart
// Unit tests for AO loyalty milestone detection and ordinal formatting.

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/utils/ao_milestones.dart';

void main() {
  group('aoMilestoneCrossed', () {
    test('returns the milestone when after lands exactly on one', () {
      expect(aoMilestoneCrossed(9, 10), 10);
      expect(aoMilestoneCrossed(49, 50), 50);
      expect(aoMilestoneCrossed(99, 100), 100);
    });

    test('returns null for a count that is not a milestone', () {
      expect(aoMilestoneCrossed(10, 11), isNull);
      expect(aoMilestoneCrossed(4, 5), isNull);
    });

    test('returns null when after does not exceed before', () {
      expect(aoMilestoneCrossed(10, 10), isNull);
      expect(aoMilestoneCrossed(10, 9), isNull);
    });
  });

  group('ordinalSuffix', () {
    test('handles the common cases', () {
      expect(ordinalSuffix(1), 'st');
      expect(ordinalSuffix(2), 'nd');
      expect(ordinalSuffix(3), 'rd');
      expect(ordinalSuffix(4), 'th');
      expect(ordinalSuffix(10), 'th');
    });

    test('the 11th/12th/13th exception overrides the usual 1/2/3 rule', () {
      expect(ordinalSuffix(11), 'th');
      expect(ordinalSuffix(12), 'th');
      expect(ordinalSuffix(13), 'th');
    });

    test('handles the 20s, including 21st', () {
      expect(ordinalSuffix(21), 'st');
      expect(ordinalSuffix(22), 'nd');
      expect(ordinalSuffix(23), 'rd');
      expect(ordinalSuffix(24), 'th');
    });

    test('handles larger numbers, including 111th (not 111st)', () {
      expect(ordinalSuffix(100), 'th');
      expect(ordinalSuffix(101), 'st');
      expect(ordinalSuffix(111), 'th');
    });
  });
}
