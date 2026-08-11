// test/feed_reaction_service_test.dart
// Unit tests for the local, single-user "salute" reaction toggle.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:f3_nation_app/services/feed_reaction_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts with nothing saluted', () async {
    final service = FeedReactionService();
    await service.load();

    expect(service.isSaluted('backblast_2026-01-01_x'), isFalse);
  });

  test('toggle salutes an unsaluted item and notifies listeners', () async {
    final service = FeedReactionService();
    await service.load();

    var notified = 0;
    service.addListener(() => notified++);

    await service.toggle('item-1');

    expect(notified, 1);
    expect(service.isSaluted('item-1'), isTrue);
  });

  test('toggle un-salutes an already-saluted item', () async {
    final service = FeedReactionService();
    await service.load();

    await service.toggle('item-1');
    await service.toggle('item-1');

    expect(service.isSaluted('item-1'), isFalse);
  });

  test('salutes are independent per item id', () async {
    final service = FeedReactionService();
    await service.load();

    await service.toggle('item-1');

    expect(service.isSaluted('item-1'), isTrue);
    expect(service.isSaluted('item-2'), isFalse);
  });

  test('persists across a fresh instance', () async {
    final service = FeedReactionService();
    await service.load();
    await service.toggle('item-1');
    await service.toggle('item-2');
    await service.toggle('item-2'); // un-salute item-2 again

    final reloaded = FeedReactionService();
    await reloaded.load();

    expect(reloaded.isSaluted('item-1'), isTrue);
    expect(reloaded.isSaluted('item-2'), isFalse);
  });
}
