// lib/screens/spartan_chat_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_plan.dart';
import '../services/current_workout_service.dart';
import '../services/exercise_service.dart';
import '../services/spartan_plan_builder.dart';
import '../services/spartan_plan_cache_service.dart';
import '../services/spartan_service.dart';
import '../theme/app_theme.dart';
import 'workout_screen.dart';

class SpartanChatScreen extends StatefulWidget {
  const SpartanChatScreen({super.key});

  @override
  State<SpartanChatScreen> createState() => _SpartanChatScreenState();
}

class _SpartanChatScreenState extends State<SpartanChatScreen> {
  final SpartanService _spartan = SpartanService.instance;
  final SpartanPlanCacheService _planCache = SpartanPlanCacheService();
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

    // Fired alongside the normal chat reply — not instead of it — so a
    // message that reads like "build me a weinke like this: ..." both gets
    // a normal Spartan reply AND, if it actually resolves, a "Build this
    // into my Weinke" action on that reply. Anything that doesn't look like
    // a workout request skips the extra call entirely.
    final askFuture = _spartan.askSpartan(text);
    final blocksFuture = _looksLikeWorkoutRequest(text)
        ? _spartan.generateWorkoutBlocks(text)
        : Future<List<dynamic>?>.value(null);

    final response = await askFuture;
    final blocksJson = await blocksFuture;

    if (!mounted) return;
    var plan = blocksJson == null
        ? null
        : buildPlanFromSpartanBlocks(blocksJson, context.read<ExerciseService>());
    var reply = response;

    if (blocksJson != null && plan != null) {
      // Real generation succeeded — bank it for the next time this fails.
      unawaited(_planCache.cache(text, blocksJson));
    } else if (_looksLikeWorkoutRequest(text)) {
      // Looked like a workout request but generation came back empty —
      // almost always a dead connection (generateWorkoutBlocks swallows its
      // own errors and returns null), exactly when a cached fallback earns
      // its keep. A genuinely non-workout message never reaches here.
      final cached = await _planCache.randomCached();
      if (cached != null && mounted) {
        plan = buildPlanFromSpartanBlocks(
            cached.blocksJson, context.read<ExerciseService>());
        if (plan != null) {
          reply =
              "$response\n\n(Couldn't reach Spartan for a fresh one — here's "
              'one from the stash: "${cached.label}".)';
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMsg.spartan(reply, plan: plan));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  /// Cheap local heuristic deciding whether a message is worth also running
  /// through structured plan generation — avoids an extra Gemini call on
  /// every single chat message. False positives just cost one harmless
  /// extra call that produces no button; false negatives just mean the
  /// dedicated "Build a Weinke" action is the way in instead.
  bool _looksLikeWorkoutRequest(String text) {
    final lower = text.toLowerCase();
    const keywords = [
      'weinke', 'beatdown', 'warm-up', 'warmup', 'warm up', 'thang', 'mary',
      'rounds', 'workout', 'build me', 'four corners', 'indian run',
    ];
    if (keywords.any(lower.contains)) return true;
    final nonEmptyLines =
        text.split('\n').where((l) => l.trim().isNotEmpty).length;
    final hasRepCounts = RegExp(r'\b\d+[\s-]*(?:sec|min|x)?\b').hasMatch(text);
    return nonEmptyLines >= 4 && hasRepCounts;
  }

  /// Loads a built plan as the draft Weinke and takes the Q straight to the
  /// editor — from there it's fully editable (swap, reorder, add exercise)
  /// same as any generated or blank plan.
  void _loadPlanAndOpenWeinke(WorkoutPlan plan) {
    context.read<CurrentWorkoutService>().setDraftPlan(plan);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WorkoutScreen()),
    );
  }

  Future<void> _openBuildWeinkeSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BuildWeinkeSheet(onBuilt: _loadPlanAndOpenWeinke),
    );
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
      backgroundColor: context.f3bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: context.f3bg,
        title: Row(children: [
          const _SpartanAvatar(size: 30),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Spartan Co-Q',
                  style: TextStyle(
                      color: context.f3textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900)),
              Text('Powered by Gemini',
                  style: TextStyle(
                      color: context.f3textMuted,
                      fontSize: 10,
                      letterSpacing: 0.5)),
            ],
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.construction_rounded),
            tooltip: 'Build a Weinke',
            onPressed: _openBuildWeinkeSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'New conversation',
            onPressed: _reset,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Message list / Hero section ────────────────────────────────────
          Expanded(
            child: showPrompts
                ? _SpartanHeroSection(prompts: _quickPrompts, onPromptTap: _send)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _messages.length) return const _TypingBubble();
                      return _MessageBubble(
                        msg: _messages[i],
                        onBuildPlan: _loadPlanAndOpenWeinke,
                      );
                    },
                  ),
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
  // Set when this reply's request also resolved to a buildable workout —
  // see _looksLikeWorkoutRequest. Lets the bubble offer "Build this into my
  // Weinke" without the user having to use the dedicated builder separately.
  final WorkoutPlan? plan;

  const _ChatMsg.user(this.text)
      : isUser = true,
        plan = null;
  const _ChatMsg.spartan(this.text, {this.plan}) : isUser = false;
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _ChatMsg msg;
  final void Function(WorkoutPlan) onBuildPlan;
  const _MessageBubble({required this.msg, required this.onBuildPlan});

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
                color: isUser ? F3Colors.accent : context.f3elevated,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : context.f3textPrimary,
                      fontSize: 14.5,
                      height: 1.45,
                    ),
                  ),
                  if (msg.plan != null) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => onBuildPlan(msg.plan!),
                      icon: const Icon(Icons.construction_rounded, size: 16),
                      label: const Text('BUILD THIS INTO MY WEINKE'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: F3Colors.accent,
                        side: BorderSide(
                            color: F3Colors.accent.withValues(alpha: 0.5)),
                        textStyle: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
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
            decoration: BoxDecoration(
              color: context.f3elevated,
              borderRadius: const BorderRadius.only(
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
              child: CircleAvatar(
                  radius: 4, backgroundColor: context.f3textSecondary),
            );
          }),
        );
      },
    );
  }
}

// ── Spartan hero section (empty state) ───────────────────────────────────────

class _SpartanHeroSection extends StatelessWidget {
  final List<(String, IconData)> prompts;
  final void Function(String) onPromptTap;

  const _SpartanHeroSection({required this.prompts, required this.onPromptTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Column(
          children: [
            // Big shield
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: F3Colors.accent,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: F3Colors.accent.withValues(alpha: 0.45),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: CustomPaint(painter: _SpartanHelmPainter()),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SPARTAN CO-Q',
              style: TextStyle(
                color: context.f3textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your AI beatdown partner — powered by Gemini',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.f3textMuted,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 28),
            // Capability pills
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: const [
                _CapabilityChip(icon: Icons.bolt_rounded, label: 'Audibles'),
                _CapabilityChip(icon: Icons.fitness_center_rounded, label: 'Beatdown Plans'),
                _CapabilityChip(icon: Icons.people_rounded, label: 'COT'),
                _CapabilityChip(icon: Icons.person_add_alt_1_rounded, label: 'FNG Names'),
                _CapabilityChip(icon: Icons.self_improvement_rounded, label: 'Mary'),
                _CapabilityChip(icon: Icons.wb_cloudy_rounded, label: 'Weather Prep'),
              ],
            ),
            const SizedBox(height: 28),
            Divider(color: context.f3divider),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'QUICK PROMPTS',
                  style: TextStyle(
                    color: context.f3textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            // Inline quick prompts grid (2 per row)
            ...List.generate((prompts.length / 2).ceil(), (row) {
              final left = prompts[row * 2];
              final right = row * 2 + 1 < prompts.length ? prompts[row * 2 + 1] : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: _HeroPromptTile(prompt: left, onTap: onPromptTap)),
                    const SizedBox(width: 8),
                    right != null
                        ? Expanded(child: _HeroPromptTile(prompt: right, onTap: onPromptTap))
                        : const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CapabilityChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: F3Colors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: F3Colors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: F3Colors.accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: F3Colors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPromptTile extends StatelessWidget {
  final (String, IconData) prompt;
  final void Function(String) onTap;

  const _HeroPromptTile({required this.prompt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (label, icon) = prompt;
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.f3elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.f3divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: F3Colors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: context.f3textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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
      color: context.f3card,
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                  color: context.f3textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Ask Spartan anything…',
                hintStyle: TextStyle(color: context.f3textMuted),
                filled: true,
                fillColor: context.f3elevated,
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
                    ? context.f3textMuted
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

// ── Build a Weinke sheet — dedicated entry point, skips free chat ────────────
// Reached via the AppBar's construction icon. Sends the description straight
// to SpartanService.generateWorkoutBlocks rather than the prose chat session,
// so there's no ambiguity about whether the reply is "just talk" or a plan.

class _BuildWeinkeSheet extends StatefulWidget {
  final void Function(WorkoutPlan) onBuilt;
  const _BuildWeinkeSheet({required this.onBuilt});

  @override
  State<_BuildWeinkeSheet> createState() => _BuildWeinkeSheetState();
}

class _BuildWeinkeSheetState extends State<_BuildWeinkeSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _build() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final blocksJson = await SpartanService.instance.generateWorkoutBlocks(text);
    if (!mounted) return;

    if (blocksJson == null) {
      // Almost always a dead connection — generateWorkoutBlocks swallows its
      // own network errors and returns null either way. Fall back to a plan
      // cached from an earlier successful generation rather than just
      // failing outright.
      final cached = await SpartanPlanCacheService().randomCached();
      if (!mounted) return;
      final fallbackPlan = cached == null
          ? null
          : buildPlanFromSpartanBlocks(
              cached.blocksJson, context.read<ExerciseService>());
      if (fallbackPlan != null) {
        Navigator.pop(context);
        widget.onBuilt(fallbackPlan);
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Couldn\'t find a workout in that. Try listing sections, '
            'exercises, and rounds — like a warm-up, a few rounds of '
            'exercises, and a Mary block.';
      });
      return;
    }

    final plan = buildPlanFromSpartanBlocks(
        blocksJson, context.read<ExerciseService>());
    if (plan == null) {
      setState(() {
        _loading = false;
        _error = 'Spartan understood a workout was requested, but couldn\'t '
            'pin down any actual exercises. Try being more specific.';
      });
      return;
    }
    unawaited(SpartanPlanCacheService().cache(text, blocksJson));

    if (!mounted) return;
    Navigator.pop(context);
    widget.onBuilt(plan);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: context.f3bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: context.f3divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text(
              'BUILD A WEINKE WITH SPARTAN',
              style: TextStyle(
                color: F3Colors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Paste or describe the workout you want — sections, exercises, '
              'rounds. Spartan will build it directly into your Weinke.',
              style: TextStyle(color: context.f3textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLines: 8,
              minLines: 4,
              style: TextStyle(color: context.f3textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Warm-up: 15 Michael Phelps OYO, 10 SSH IC...\n'
                    'Part 1 — 3 rounds: 20 Coupon Squats, 15 Curls...\n'
                    'Mary: 20 LBCs, 30-sec Plank...',
                hintStyle: TextStyle(color: context.f3textMuted, fontSize: 12.5),
                filled: true,
                fillColor: context.f3elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _build,
                style: ElevatedButton.styleFrom(
                  backgroundColor: F3Colors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.construction_rounded),
                label: Text(_loading ? 'BUILDING…' : 'BUILD MY WEINKE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
