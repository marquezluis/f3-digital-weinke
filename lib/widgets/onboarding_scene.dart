// lib/widgets/onboarding_scene.dart
// Original, painted hero visual for onboarding — a sunrise circle-up scene
// with simple geometric PAX silhouettes. Digital Weinke isn't F3-Nation-
// approved yet, so real beatdown photography/video can't be bundled here;
// this is a from-scratch illustration (no traced photo, no F3 trademark)
// that still carries the sweat/sunrise/community principles the audit asked
// for (#2, #86) instead of a static icon-in-a-circle.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class OnboardingScene extends StatefulWidget {
  final double height;
  const OnboardingScene({super.key, this.height = 200});

  @override
  State<OnboardingScene> createState() => _OnboardingSceneState();
}

class _OnboardingSceneState extends State<OnboardingScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respects both the OS-level accessibility setting and the app's own
    // Reduced Motion toggle (Settings) — a single static frame instead of a
    // loop either way.
    final reduceMotion = MediaQuery.of(context).disableAnimations ||
        context.watch<SettingsService>().reducedMotion;
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: reduceMotion
            ? CustomPaint(painter: _ScenePainter(0), child: Container())
            : AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) =>
                    CustomPaint(painter: _ScenePainter(_ctrl.value), child: Container()),
              ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  final double t; // 0..1, looping
  _ScenePainter(this.t);

  static const _figureCount = 5;
  static const _groundColor = Color(0xFF0B0B0A);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF141311),
          F3Colors.accentDim.withValues(alpha: 0.55),
          F3Colors.accent.withValues(alpha: 0.85),
        ],
        stops: const [0, 0.65, 1],
      ).createShader(rect);
    canvas.drawRect(rect, sky);

    // Rising sun with a slow breathing glow.
    final sunCenter = Offset(size.width * 0.5, size.height * 0.76);
    final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
    for (var i = 3; i >= 1; i--) {
      canvas.drawCircle(
        sunCenter,
        26.0 * i + 8 * pulse,
        Paint()..color = Colors.white.withValues(alpha: 0.05 * i * (0.6 + 0.4 * pulse)),
      );
    }
    canvas.drawCircle(sunCenter, 24, Paint()..color = Colors.white.withValues(alpha: 0.92));

    // Ground
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.8, size.width, size.height * 0.2),
      Paint()..color = _groundColor,
    );

    // PAX in a circle-up formation — geometric figures, gently bobbing as
    // if mid-cadence, arms alternating up/down like a call-and-response IC.
    for (var i = 0; i < _figureCount; i++) {
      final fx = size.width * (0.12 + 0.19 * i);
      final phase = t * 2 * math.pi + i * 0.9;
      final bob = 3 * math.sin(phase);
      final fy = size.height * 0.8 - bob.abs();
      _drawFigure(canvas, Offset(fx, fy), 28, math.sin(phase) > 0);
    }
  }

  void _drawFigure(Canvas canvas, Offset base, double h, bool armsUp) {
    final fill = Paint()..color = _groundColor;
    final stroke = Paint()
      ..color = _groundColor
      ..strokeWidth = h * 0.11
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final headCenter = base.translate(0, -h);
    canvas.drawCircle(headCenter, h * 0.16, fill);

    final torsoTop = headCenter.translate(0, h * 0.16 * 2);
    canvas.drawLine(torsoTop, base, stroke);

    final armY = torsoTop.dy + h * 0.15;
    if (armsUp) {
      canvas.drawLine(
          Offset(base.dx, armY), Offset(base.dx - h * 0.35, armY - h * 0.4), stroke);
      canvas.drawLine(
          Offset(base.dx, armY), Offset(base.dx + h * 0.35, armY - h * 0.4), stroke);
    } else {
      canvas.drawLine(
          Offset(base.dx, armY), Offset(base.dx - h * 0.3, armY + h * 0.2), stroke);
      canvas.drawLine(
          Offset(base.dx, armY), Offset(base.dx + h * 0.3, armY + h * 0.2), stroke);
    }

    canvas.drawLine(base, Offset(base.dx - h * 0.22, base.dy + h * 0.4), stroke);
    canvas.drawLine(base, Offset(base.dx + h * 0.22, base.dy + h * 0.4), stroke);
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) => oldDelegate.t != t;
}
