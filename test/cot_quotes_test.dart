// test/cot_quotes_test.dart
// Unit tests for the Circle of Trust closing-quote rotation.

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/cot_quotes.dart';

void main() {
  group('cotQuoteFor', () {
    test('always returns one of the curated quotes', () {
      for (var m = 1; m <= 12; m++) {
        final quote = cotQuoteFor(DateTime(2026, m, 15));
        expect(cotQuotes, contains(quote));
      }
    });

    test('is deterministic for the same day', () {
      final day = DateTime(2026, 8, 11);
      expect(cotQuoteFor(day), cotQuoteFor(day));
    });

    test('the quote list is non-empty', () {
      expect(cotQuotes, isNotEmpty);
    });
  });
}
