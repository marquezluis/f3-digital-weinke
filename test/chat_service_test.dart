// test/chat_service_test.dart
// Unit tests for the local-only, channel-aware chat preview, ahead of the
// Slack bridge.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:f3_nation_app/models/chat_message.dart';
import 'package:f3_nation_app/services/chat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts empty and not bridged', () async {
    final service = ChatService();
    await service.load();

    expect(service.messagesFor('general'), isEmpty);
    expect(service.isBridged, isFalse);
  });

  test('sendMessage appends a sent, mine message to its own channel and notifies', () async {
    final service = ChatService();
    await service.load();

    var notified = 0;
    service.addListener(() => notified++);

    await service.sendMessage(
      channelId: 'general',
      authorName: 'PermVac',
      text: 'On my way to DarkRoast',
    );

    expect(notified, 1);
    expect(service.messagesFor('general'), hasLength(1));
    final message = service.messagesFor('general').single;
    expect(message.channelId, 'general');
    expect(message.authorName, 'PermVac');
    expect(message.text, 'On my way to DarkRoast');
    expect(message.status, ChatMessageStatus.sent);
    expect(message.isMine, isTrue);
  });

  test('messages in one channel do not show up in another', () async {
    final service = ChatService();
    await service.load();

    await service.sendMessage(channelId: 'general', authorName: 'PermVac', text: 'general hey');
    await service.sendMessage(channelId: 'ao-1', authorName: 'PermVac', text: 'darkroast hey');

    expect(service.messagesFor('general'), hasLength(1));
    expect(service.messagesFor('general').single.text, 'general hey');
    expect(service.messagesFor('ao-1'), hasLength(1));
    expect(service.messagesFor('ao-1').single.text, 'darkroast hey');
  });

  test('sendMessage trims whitespace and ignores an empty/blank message', () async {
    final service = ChatService();
    await service.load();

    await service.sendMessage(channelId: 'general', authorName: 'PermVac', text: '  hey  ');
    await service.sendMessage(channelId: 'general', authorName: 'PermVac', text: '   ');

    expect(service.messagesFor('general'), hasLength(1));
    expect(service.messagesFor('general').single.text, 'hey');
  });

  test('persists messages (with channel) and reloads across a fresh instance', () async {
    final service = ChatService();
    await service.load();
    await service.sendMessage(
      channelId: 'ao-1',
      authorName: 'PermVac',
      text: 'Q tomorrow at Iron Mtn',
    );

    final reloaded = ChatService();
    await reloaded.load();

    expect(reloaded.messagesFor('ao-1'), hasLength(1));
    expect(reloaded.messagesFor('ao-1').single.text, 'Q tomorrow at Iron Mtn');
    expect(reloaded.messagesFor('general'), isEmpty);
  });

  test('messagesFor result is unmodifiable', () async {
    final service = ChatService();
    await service.load();
    await service.sendMessage(channelId: 'general', authorName: 'PermVac', text: 'hey');

    expect(
      () => service.messagesFor('general').add(service.messagesFor('general').first),
      throwsUnsupportedError,
    );
  });

  test('ChatMessage.fromJson defaults missing channelId to general (pre-channel data)', () {
    final message = ChatMessage.fromJson({
      'id': 'abc',
      'authorName': 'PermVac',
      'text': 'legacy message',
      'sentAt': DateTime(2026, 1, 1).toIso8601String(),
      'status': 'sent',
      'isMine': true,
    });

    expect(message.channelId, 'general');
  });
}
