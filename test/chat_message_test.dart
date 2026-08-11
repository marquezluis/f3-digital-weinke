// test/chat_message_test.dart
// Unit tests for ChatChannel's name-to-channel-id slugging.

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/chat_message.dart';

void main() {
  group('ChatChannel.forAo', () {
    test('slugs a simple AO name to lowercase', () {
      expect(ChatChannel.forAo(aoName: 'Agoge').id, 'ao-agoge');
    });

    test('replaces spaces and punctuation with a single hyphen', () {
      expect(ChatChannel.forAo(aoName: 'Dark Roast!').id, 'ao-dark-roast');
      expect(ChatChannel.forAo(aoName: "Guts & Glory").id, 'ao-guts-glory');
    });

    test('trims leading/trailing hyphens from punctuation at the edges', () {
      expect(ChatChannel.forAo(aoName: '  Common Ground  ').id, 'ao-common-ground');
    });

    test('two devices naming the same AO converge on the same channel id', () {
      final a = ChatChannel.forAo(aoName: 'Iron Mountain');
      final b = ChatChannel.forAo(aoName: 'iron   mountain');
      expect(a.id, b.id);
    });

    test('keeps the original name as the display label', () {
      expect(ChatChannel.forAo(aoName: 'Agoge').label, 'Agoge');
    });
  });
}
