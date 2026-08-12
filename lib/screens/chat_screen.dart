// lib/screens/chat_screen.dart
// Region chat — a Digital Weinke-native front end for a region's Slack
// channels, bridged through a bot so PAX never need a separate Slack
// account or login. Local-only preview until the relay service exists —
// see ChatService for why.
//
// Channel-aware: #general plus one channel per AO the PAX tracks locally,
// matching how a real F3 region's Slack workspace is actually laid out
// (#general, #ao-agoge, #ao-darkroast, ...) rather than one flat stream.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../services/app_profile_service.dart';
import '../services/chat_service.dart';
import '../services/region_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String _selectedChannelId = ChatChannel.general.id;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<ChatChannel> _channelsFor(RegionService region) => [
        ChatChannel.general,
        ...region.aos.map((ao) => ChatChannel.forAo(aoName: ao.name)),
      ];

  void _send(ChatService chat, String authorName) {
    if (_controller.text.trim().isEmpty) return;
    chat.sendMessage(
      channelId: _selectedChannelId,
      authorName: authorName,
      text: _controller.text,
    );
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppProfileService>();
    final region = context.watch<RegionService>();
    final chat = context.watch<ChatService>();
    final authorName = profile.displayName.isNotEmpty ? profile.displayName : 'PAX';

    final channels = _channelsFor(region);
    // If a previously-selected AO channel disappeared (AO removed), fall
    // back to General rather than pointing at nothing.
    if (!channels.any((c) => c.id == _selectedChannelId)) {
      _selectedChannelId = ChatChannel.general.id;
    }
    final messages = chat.messagesFor(_selectedChannelId);

    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: Text(
          profile.region.isNotEmpty ? '${profile.region.toUpperCase()} CHAT' : 'REGION CHAT',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        backgroundColor: context.f3bg,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!chat.isBridged) const _PreviewBanner(),
            _ChannelSwitcher(
              channels: channels,
              selectedId: _selectedChannelId,
              onSelect: (id) => setState(() => _selectedChannelId = id),
              chat: chat,
            ),
            Expanded(
              child: messages.isEmpty
                  ? const _EmptyChat()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      itemCount: messages.length,
                      itemBuilder: (context, i) => _MessageBubble(message: messages[i]),
                    ),
            ),
            _Composer(controller: _controller, onSend: () => _send(chat, authorName)),
          ],
        ),
      ),
    );
  }
}

class _ChannelSwitcher extends StatelessWidget {
  final List<ChatChannel> channels;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final ChatService chat;

  const _ChannelSwitcher({
    required this.channels,
    required this.selectedId,
    required this.onSelect,
    required this.chat,
  });

  @override
  Widget build(BuildContext context) {
    if (channels.length <= 1) return const SizedBox.shrink();
    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.f3divider, width: 0.5)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: channels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final channel = channels[i];
          final selected = channel.id == selectedId;
          final channelMessages = chat.messagesFor(channel.id);
          // No relay yet (see ChatService header), so every message here
          // was sent by the local PAX themselves — there's no honest
          // "unread from someone else" signal to show yet. A last-message
          // preview is real and useful today without pretending otherwise.
          final last = channelMessages.isEmpty ? null : channelMessages.last;
          return Tooltip(
            message: last == null
                ? 'No messages yet'
                : '${last.authorName}: ${last.text}',
            triggerMode: TooltipTriggerMode.longPress,
            child: ChoiceChip(
              label: Text('#${channel.label}'),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : context.f3textSecondary,
              ),
              avatar: last == null
                  ? null
                  : Icon(Icons.circle,
                      size: 6,
                      color: selected ? Colors.white : F3Colors.accent),
              selected: selected,
              onSelected: (_) => onSelect(channel.id),
              selectedColor: F3Colors.accent,
              backgroundColor: context.f3card,
              side: BorderSide(color: selected ? F3Colors.accent : context.f3divider),
              visualDensity: VisualDensity.compact,
            ),
          );
        },
      ),
    );
  }
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: context.f3elevated,
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: context.f3textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Preview — not connected to Slack yet. Messages stay on this device only.',
              style: TextStyle(fontSize: 12, color: context.f3textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_rounded, color: context.f3textMuted, size: 40),
            const SizedBox(height: 12),
            Text(
              'No messages yet — say something to the crew.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.f3textSecondary, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// Real F3 Slack shows an avatar for every PAX; this local-only chat had
// nothing but a plain text name, which reads as a generic message board
// rather than the actual crew talking. No photo data exists for other PAX
// here, so a colored initial — stable per name, like Slack's own fallback
// avatars — is the honest approximation.
class _ChatAvatar extends StatelessWidget {
  final String name;
  const _ChatAvatar({required this.name});

  static const _palette = [
    Color(0xFF5B9BD5),
    Color(0xFF9C6FE0),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF26A69A),
  ];

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    final color = _palette[trimmed.hashCode.abs() % _palette.length];
    return CircleAvatar(
      radius: 15,
      backgroundColor: color.withValues(alpha: 0.25),
      child: Text(initial,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w800, fontSize: 13)),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  static String _time(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final align = message.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = message.isMine ? F3Colors.accent : context.f3card;
    final textColor = message.isMine ? Colors.white : context.f3textPrimary;

    final bubble = Column(
      crossAxisAlignment: align,
      children: [
        if (!message.isMine)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 2),
            child: Text(
              message.authorName,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.f3textMuted),
            ),
          ),
        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.62),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(14),
            border: message.isMine ? null : Border.all(color: context.f3divider),
          ),
          child: Text(message.text, style: TextStyle(color: textColor, fontSize: 14)),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_time(message.sentAt), style: TextStyle(fontSize: 10, color: context.f3textMuted)),
              if (message.isMine && message.status == ChatMessageStatus.sending) ...[
                const SizedBox(width: 4),
                SizedBox(
                  width: 8,
                  height: 8,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: context.f3textMuted),
                ),
              ],
              if (message.isMine && message.status == ChatMessageStatus.failed) ...[
                const SizedBox(width: 4),
                Icon(Icons.error_outline_rounded, size: 10, color: Colors.red.shade300),
              ],
            ],
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: message.isMine
            ? [Flexible(child: bubble)]
            : [
                _ChatAvatar(name: message.authorName),
                const SizedBox(width: 8),
                Flexible(child: bubble),
              ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _Composer({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: context.f3bg,
        border: Border(top: BorderSide(color: context.f3divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Message the crew…',
                filled: true,
                fillColor: context.f3card,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: context.f3divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: context.f3divider),
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: F3Colors.accent),
            icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}
