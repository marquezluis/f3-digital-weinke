// lib/painters/f3_shield_painter.dart
// Public F3 shield CustomPainter — used in UI and for icon generation.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class F3ShieldPainter extends CustomPainter {
  const F3ShieldPainter({
    this.fillColor = F3Colors.accent,
    this.textColor = Colors.white,
    this.backgroundColor,
    this.backgroundRadius = 0.22,
  });

  final Color fillColor;
  final Color textColor;
  /// If set, draws a rounded-rect background first (for app icon use).
  final Color? backgroundColor;
  /// Corner radius as a fraction of the smaller dimension.
  final double backgroundRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    if (backgroundColor != null) {
      final r = size.shortestSide * backgroundRadius;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(r)),
        Paint()..color = backgroundColor!,
      );
    }

    // Inset the shield slightly when there's a background so it breathes
    final inset = backgroundColor != null ? 0.10 : 0.0;
    final sw = w * (1 - inset * 2);
    final sh = h * (1 - inset * 2);
    final ox = w * inset;
    final oy = h * inset;

    _drawShield(canvas, sw, sh, ox, oy);
  }

  void _drawShield(Canvas canvas, double w, double h, double ox, double oy) {
    // Shield silhouette
    final shieldPath = Path()
      ..moveTo(ox + w * 0.50, oy + h * 0.01)
      ..cubicTo(ox + w * 0.97, oy + h * 0.01, ox + w * 0.97, oy + h * 0.52,
          ox + w * 0.76, oy + h * 0.78)
      ..lineTo(ox + w * 0.50, oy + h * 0.99)
      ..lineTo(ox + w * 0.24, oy + h * 0.78)
      ..cubicTo(ox + w * 0.03, oy + h * 0.52, ox + w * 0.03, oy + h * 0.01,
          ox + w * 0.50, oy + h * 0.01)
      ..close();

    canvas.drawPath(shieldPath, Paint()..color = fillColor);

    // Inner highlight
    final innerPath = Path()
      ..moveTo(ox + w * 0.50, oy + h * 0.09)
      ..cubicTo(ox + w * 0.89, oy + h * 0.09, ox + w * 0.89, oy + h * 0.48,
          ox + w * 0.70, oy + h * 0.70)
      ..lineTo(ox + w * 0.50, oy + h * 0.87)
      ..lineTo(ox + w * 0.30, oy + h * 0.70)
      ..cubicTo(ox + w * 0.11, oy + h * 0.48, ox + w * 0.11, oy + h * 0.09,
          ox + w * 0.50, oy + h * 0.09)
      ..close();
    canvas.drawPath(
        innerPath, Paint()..color = Colors.white.withValues(alpha: 0.10));

    // Divider bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(ox + w * 0.18, oy + h * 0.44, w * 0.64, h * 0.05),
        Radius.circular(h * 0.02),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );

    // "F3" text
    final f3 = TextPainter(
      text: TextSpan(
        text: 'F3',
        style: TextStyle(
          color: textColor,
          fontSize: h * 0.32,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    f3.paint(canvas, Offset(ox + (w - f3.width) / 2, oy + h * 0.14));

    // "NATION" text
    final nation = TextPainter(
      text: TextSpan(
        text: 'NATION',
        style: TextStyle(
          color: textColor.withValues(alpha: 0.70),
          fontSize: h * 0.08,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    nation.paint(canvas, Offset(ox + (w - nation.width) / 2, oy + h * 0.52));
  }

  @override
  bool shouldRepaint(F3ShieldPainter old) =>
      old.fillColor != fillColor ||
      old.textColor != textColor ||
      old.backgroundColor != backgroundColor;
}
