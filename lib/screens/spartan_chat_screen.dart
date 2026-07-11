// lib/screens/spartan_chat_screen.dart
import 'package:flutter/material.dart';
import '../services/spartan_service.dart';
import '../theme/app_theme.dart';

class SpartanChatScreen extends StatefulWidget {
  const SpartanChatScreen({super.key});

  @override
  State<SpartanChatScreen> createState() => _SpartanChatScreenState();
}

class _SpartanChatScreenState extends State<SpartanChatScreen> {
  final SpartanService _spartan = SpartanService.instance;
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_ChatMsg> _messages = [];
  bool _isLoading = false;

  static const _quickPrompts = [
    ('Suggest an audible for right now', Icons.bolt_rounded),
    ('Give me a 10-min Thang', Icons.fitness_center_rounded),
    ('Help me write COT', Icons.people_rounded),
    ('Name this FNG', Icons.person_add_alt_1_rounded),
    ('Mary ideas — go', Icons.self_improvement_rounded),
    ('Audit my beatdown', Icons.checklist_rounded),
    ('Weather prep for the Gloom', Icons.wb_cloudy_rounded),
    ('Motivational callout for the PAX', Icons.campaign_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(const _ChatMsg.spartan(
      'Fell in at 5:30 and I\'m ready. '
      'Need an audible, FNG name, COT, or a beatdown plan? '
      'Ask away, Q — or pick one below.',
    ));
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? override]) async {
    final text = (override ?? _textCtrl.text).trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMsg.user(text));
      _isLoading = true;
    });
    _textCtrl.clear();
    _scrollToBottom();

    final response = await _spartan.askSpartan(text);

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMsg.spartan(response));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _reset() {
    setState(() {
      _messages
        ..clear()
        ..add(const _ChatMsg.spartan('New session. What do you need, Q?'));
    });
  }

  @override
  Widget build(BuildContext context) {
    final showPrompts = _messages.length <= 1 && !_isLoading;

    return Scaffold(
      backgroundColor: F3Colors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: F3Colors.background,
        title: const Row(children: [
          _SpartanAvatar(size: 30),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Spartan Co-Q',
                  style: TextStyle(
                      color: F3Colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900)),
              Text('Powered by Gemini',
                  style: TextStyle(
                      color: F3Colors.textMuted,
                      fontSize: 10,
                      letterSpacing: 0.5)),
            ],
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'New conversation',
            onPressed: _reset,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Message list ───────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) return const _TypingBubble();
                return _MessageBubble(msg: _messages[i]);
              },
            ),
          ),

          // ── Quick prompts ──────────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: showPrompts
                ? _QuickPromptsBar(prompts: _quickPrompts, onTap: _send)
                : const SizedBox.shrink(),
          ),

          // ── Input bar ─────────────────────────────────────────────────────
          _InputBar(
            controller: _textCtrl,
            isLoading: _isLoading,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ── Spartan avatar ────────────────────────────────────────────────────────────

class _SpartanAvatar extends StatelessWidget {
  final double size;
  const _SpartanAvatar({this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: F3Colors.accent,
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
              color: F3Colors.accent.withValues(alpha: 0.40),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.11),
        child: const CustomPaint(painter: _SpartanHelmPainter()),
      ),
    );
  }
}

// ── Spartan helmet painter ────────────────────────────────────────────────────

class _SpartanHelmPainter extends CustomPainter {
  const _SpartanHelmPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Helmet dome
    final helmPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final helmPath = Path()
      ..moveTo(w * 0.50, 0)
      ..cubicTo(w * 0.95, 0, w * 0.95, h * 0.50, w * 0.82, h * 0.66)
      ..lineTo(w * 0.72, h * 0.68)
      ..lineTo(w * 0.72, h * 0.76)
      ..lineTo(w * 0.28, h * 0.76)
      ..lineTo(w * 0.28, h * 0.68)
      ..lineTo(w * 0.18, h * 0.66)
      ..cubicTo(w * 0.05, h * 0.50, w * 0.05, 0, w * 0.50, 0)
      ..close();
    canvas.drawPath(helmPath, helmPaint);

    // Eye slit (dark cutout)
    final eyePaint = Paint()
      ..color = const Color(0xFF242A2B)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.38, w * 0.64, h * 0.14),
        Radius.circular(h * 0.04),
      ),
      eyePaint,
    );

    // Nose guard
    final nosePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.80)
      ..style = PaintingStyle.fill;
    final nosePath = Path()
      ..moveTo(w * 0.43, h * 0.52)
      ..lineTo(w * 0.57, h * 0.52)
      ..lineTo(w * 0.57, h * 0.73)
      ..lineTo(w * 0.50, h * 0.82)
      ..lineTo(w * 0.43, h * 0.73)
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    // Top crest highlight bar
    final crestPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.28, h * 0.10, w * 0.44, h * 0.07),
        Radius.circular(h * 0.02),
      ),
      crestPaint,
    );
  }

  @override
  bool shouldRepaint(_SpartanHelmPainter old) => false;
}

// ── Message model ─────────────────────────────────────────────────────────────

class _ChatMsg {
  final bool isUser;
  final String text;

  const _ChatMsg.user(this.text) : isUser = true;
  const _ChatMsg.spartan(this.text) : isUser = false;
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _ChatMsg msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const _SpartanAvatar(size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78),
              decoration: BoxDecoration(
                color: isUser ? F3Colors.accent : F3Colors.elevated,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isUser ? Colors.white : F3Colors.textPrimary,
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _SpartanAvatar(size: 28),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: F3Colors.elevated,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: const SizedBox(
              width: 36,
              height: 10,
              child: _DotIndicator(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatefulWidget {
  const _DotIndicator();

  @override
  State<_DotIndicator> createState() => _DotIndicatorState();
}

class _DotIndicatorState extends State<_DotIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (i) {
            final opacity = ((_ctrl.value * 3 - i) % 1.0).clamp(0.2, 1.0);
            return Opacity(
              opacity: opacity,
              child: const CircleAvatar(
                  radius: 4, backgroundColor: F3Colors.textSecondary),
            );
          }),
        );
      },
    );
  }
}

// ── Quick prompts bar ─────────────────────────────────────────────────────────

class _QuickPromptsBar extends StatelessWidget {
  final List<(String, IconData)> prompts;
  final void Function(String) onTap;

  const _QuickPromptsBar({required this.prompts, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: F3Colors.card,
        border: Border(top: BorderSide(color: F3Colors.divider, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              'QUICK PROMPTS',
              style: TextStyle(
                color: F3Colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: prompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final (label, icon) = prompts[i];
                return GestureDetector(
                  onTap: () => onTap(label),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: F3Colors.elevated,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: F3Colors.accent.withValues(alpha: 0.30)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 13, color: F3Colors.accent),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: const TextStyle(
                            color: F3Colors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: F3Colors.card,
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                  color: F3Colors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Ask Spartan anything…',
                hintStyle: const TextStyle(color: F3Colors.textMuted),
                filled: true,
                fillColor: F3Colors.elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              maxLines: 4,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isLoading ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isLoading
                    ? F3Colors.textMuted
                    : F3Colors.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLoading ? Icons.hourglass_top_rounded : Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
