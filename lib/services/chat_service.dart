// lib/services/chat_service.dart
// Region chat, ahead of the Slack bridge relay service landing. Messages
// persist on-device only right now — they are NOT sent to Slack and nobody
// else sees them yet. Once the relay service exists, sendMessage() will
// POST to it instead of just appending locally, and load() will hydrate
// from the relay's live feed (Firestore) instead of SharedPreferences.
//
// Channel-aware: a region bridges more than one Slack channel in practice
// (#general plus one #ao-<name> channel per AO), so messages are scoped by
// channelId rather than assuming a single region-wide stream. The set of
// available channels itself is derived from RegionService's AOs by the
// screen, not stored here — this service only knows about messages.
//
// The public interface (messagesFor, sendMessage, isBridged) is written to
// stay stable across the relay swap so ChatScreen doesn't need to change
// when it happens.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';

class ChatService extends ChangeNotifier {
  static const _key = 'region_chat_preview_v1';

  final _uuid = const Uuid();
  List<ChatMessage> _messages = [];
  SharedPreferences? _prefs;

  List<ChatMessage> messagesFor(String channelId) =>
      List.unmodifiable(_messages.where((m) => m.channelId == channelId));

  /// False until a real Slack bridge is wired up server-side. The screen
  /// uses this to show a "not connected yet" banner instead of silently
  /// pretending these messages reach anyone.
  bool get isBridged => false;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getStringList(_key);
    if (raw == null) return;
    try {
      _messages = raw
          .map((s) => ChatMessage.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _messages = [];
    }
  }

  Future<void> sendMessage({
    required String channelId,
    required String authorName,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _messages.add(ChatMessage(
      id: _uuid.v4(),
      channelId: channelId,
      authorName: authorName,
      text: trimmed,
      sentAt: DateTime.now(),
      status: ChatMessageStatus.sent,
      isMine: true,
    ));
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    if (_prefs == null) return;
    await _prefs!.setStringList(
      _key,
      _messages.map((m) => jsonEncode(m.toJson())).toList(),
    );
  }
}
