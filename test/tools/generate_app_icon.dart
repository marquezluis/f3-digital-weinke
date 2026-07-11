// test/tools/generate_app_icon.dart
// Run with: flutter test test/tools/generate_app_icon.dart
// Renders the F3 shield to a 1024x1024 PNG and saves it to assets/icon/app_icon.png.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// F3 orange — same value as F3Colors.accent, inlined to avoid importing theme.
const _accent = Color(0xFFFF6B00);
const _bg = Color(0xFF12100E); // F3Colors.background

void main() {
  test('render F3 shield icon to PNG', () async {
    const int dim = 1024;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, 1024, 1024),
    );

    _paintIcon(canvas, const Size(1024, 1024));

    final picture = recorder.endRecording();
    final image = await picture.toImage(dim, dim);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);

    final outFile = File('assets/icon/app_icon.png');
    await outFile.create(recursive: true);
    await outFile.writeAsBytes(bytes!.buffer.asUint8List());

    // ignore: avoid_print
    print('Saved ${bytes.lengthInBytes} bytes → ${outFile.path}');
    expect(bytes.lengthInBytes, greaterThan(1000));
  });
}

// ---------------------------------------------------------------------------
// Inline painter (no TextPainter — avoids font-loading issues in test env).
// Uses pure path geometry for "F3" lettering so the icon is fully vectorized.
// ---------------------------------------------------------------------------

void _paintIcon(Canvas canvas, Size size) {
  final w = size.width, h = size.height;

  // ── Background rounded square ──────────────────────────────────────────
  final r = w * 0.22;
  canvas.drawRRect(
    RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(r)),
    Paint()..color = _bg,
  );

  // ── Shield ────────────────────────────────────────────────────────────
  const inset = 0.09;
  final sw = w * (1 - inset * 2);
  final sh = h * (1 - inset * 2);
  final ox = w * inset;
  final oy = h * inset;

  final shield = Path()
    ..moveTo(ox + sw * 0.50, oy + sh * 0.01)
    ..cubicTo(ox + sw * 0.97, oy + sh * 0.01, ox + sw * 0.97, oy + sh * 0.52,
        ox + sw * 0.76, oy + sh * 0.78)
    ..lineTo(ox + sw * 0.50, oy + sh * 0.99)
    ..lineTo(ox + sw * 0.24, oy + sh * 0.78)
    ..cubicTo(ox + sw * 0.03, oy + sh * 0.52, ox + sw * 0.03, oy + sh * 0.01,
        ox + sw * 0.50, oy + sh * 0.01)
    ..close();
  canvas.drawPath(shield, Paint()..color = _accent);

  // Inner highlight
  final inner = Path()
    ..moveTo(ox + sw * 0.50, oy + sh * 0.09)
    ..cubicTo(ox + sw * 0.89, oy + sh * 0.09, ox + sw * 0.89, oy + sh * 0.48,
        ox + sw * 0.70, oy + sh * 0.70)
    ..lineTo(ox + sw * 0.50, oy + sh * 0.87)
    ..lineTo(ox + sw * 0.30, oy + sh * 0.70)
    ..cubicTo(ox + sw * 0.11, oy + sh * 0.48, ox + sw * 0.11, oy + sh * 0.09,
        ox + sw * 0.50, oy + sh * 0.09)
    ..close();
  canvas.drawPath(
      inner, Paint()..color = const Color(0x1AFFFFFF)); // white 10%

  // Divider bar
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(
          ox + sw * 0.18, oy + sh * 0.44, sw * 0.64, sh * 0.045),
      Radius.circular(sh * 0.02),
    ),
    Paint()..color = const Color(0x38FFFFFF), // white 22%
  );

  // ── "F3" lettering via vector paths ────────────────────────────────────
  // Drawn relative to a glyph bounding box centred in the upper shield area.
  final gw = sw * 0.42; // total glyph width
  final gh = sh * 0.28; // glyph height
  final gx = ox + (sw - gw) / 2; // left edge
  final gy = oy + sh * 0.15; // top edge
  final stroke = gh * 0.18; // stroke thickness

  final glyphPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  // "F" glyph (left half)
  final fW = gw * 0.42;
  // vertical bar
  canvas.drawRect(Rect.fromLTWH(gx, gy, stroke, gh), glyphPaint);
  // top horizontal
  canvas.drawRect(Rect.fromLTWH(gx, gy, fW, stroke), glyphPaint);
  // mid horizontal
  canvas.drawRect(
      Rect.fromLTWH(gx, gy + gh * 0.48, fW * 0.80, stroke), glyphPaint);

  // gap between F and 3
  final gapX = gx + fW + gw * 0.09;

  // "3" glyph (right half)
  final tW = gw * 0.44;
  final tX = gapX;
  final r3 = stroke * 0.5;
  // top horizontal
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(tX, gy, tW, stroke), Radius.circular(r3)),
    glyphPaint,
  );
  // mid horizontal
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(tX, gy + gh * 0.48, tW, stroke), Radius.circular(r3)),
    glyphPaint,
  );
  // bottom horizontal
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(tX, gy + gh - stroke, tW, stroke), Radius.circular(r3)),
    glyphPaint,
  );
  // right top vertical bar
  canvas.drawRect(
      Rect.fromLTWH(tX + tW - stroke, gy, stroke, gh * 0.52), glyphPaint);
  // right bottom vertical bar
  canvas.drawRect(
      Rect.fromLTWH(tX + tW - stroke, gy + gh * 0.48, stroke, gh * 0.52),
      glyphPaint);

  // ── "NATION" band ──────────────────────────────────────────────────────
  // Small dots/dashes — simplified to a thin line since no font available.
  final nPaint = Paint()
    ..color = const Color(0xB3FFFFFF) // 70%
    ..strokeWidth = sh * 0.012
    ..strokeCap = StrokeCap.round;
  final nY = oy + sh * 0.55;
  // Draw 6 short equal-width rects representing N-A-T-I-O-N letters as blocks
  final totalNW = sw * 0.52;
  final nX = ox + (sw - totalNW) / 2;
  const letterCount = 6;
  final letterW = totalNW / (letterCount * 1.6);
  final letterGap = letterW * 0.6;
  final letterH = sh * 0.04;
  final letterPaint = Paint()
    ..color = const Color(0xB3FFFFFF)
    ..style = PaintingStyle.fill;
  for (int i = 0; i < letterCount; i++) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            nX + i * (letterW + letterGap), nY, letterW, letterH),
        const Radius.circular(2),
      ),
      letterPaint,
    );
  }
  // suppress unused warning
  nPaint.toString();
}
