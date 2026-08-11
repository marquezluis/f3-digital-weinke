// lib/models/chat_message.dart
// A single message in a region's chat. `status` tracks local delivery
// state for messages this device sent; anything that arrives from the
// Slack bridge (once the relay service exists) is always `sent`.

enum ChatMessageStatus { sending, sent, failed }

class ChatMessage {
  final String id;

  /// Which bridged channel this belongs to — 'general', or 'ao-<aoId>' for
  /// an AO-specific channel. See ChatChannel.
  final String channelId;
  final String authorName;
  final String text;
  final DateTime sentAt;
  final ChatMessageStatus status;
  final bool isMine;

  const ChatMessage({
    required this.id,
    required this.channelId,
    required this.authorName,
    required this.text,
    required this.sentAt,
    this.status = ChatMessageStatus.sent,
    this.isMine = false,
  });

  ChatMessage copyWith({ChatMessageStatus? status}) => ChatMessage(
        id: id,
        channelId: channelId,
        authorName: authorName,
        text: text,
        sentAt: sentAt,
        status: status ?? this.status,
        isMine: isMine,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'channelId': channelId,
        'authorName': authorName,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
        'status': status.name,
        'isMine': isMine,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        // Messages persisted before channels existed have no channelId —
        // treat them as 'general' rather than dropping them.
        channelId: json['channelId'] as String? ?? 'general',
        authorName: json['authorName'] as String,
        text: json['text'] as String,
        sentAt: DateTime.parse(json['sentAt'] as String),
        status: ChatMessageStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => ChatMessageStatus.sent,
        ),
        isMine: json['isMine'] as bool? ?? false,
      );
}

/// A bridgeable Slack channel for a region: always 'general', plus one per
/// AO the PAX tracks locally (mirroring that region's real #ao-<name>
/// channel convention). Purely a display/routing concept on this side —
/// the actual Slack channel ID mapping lives server-side in the relay
/// service once it exists.
class ChatChannel {
  final String id;
  final String label;

  const ChatChannel({required this.id, required this.label});

  static const general = ChatChannel(id: 'general', label: 'General');

  /// Keyed by a slug of the AO's *name*, not its local id — AO ids are
  /// randomly generated per-device (see RegionService.upsertAo), so two PAX
  /// who each add "Agoge" to their own local AO list would otherwise land
  /// on two different, unreconcilable channel keys. A name slug is stable
  /// across devices, and happens to match the real #ao-<name> convention
  /// F3 region Slack workspaces already use.
  factory ChatChannel.forAo({required String aoName}) =>
      ChatChannel(id: 'ao-${_slug(aoName)}', label: aoName);

  static String _slug(String name) => name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
