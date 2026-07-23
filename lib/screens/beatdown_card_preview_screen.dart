// lib/screens/beatdown_card_preview_screen.dart
// Renders a BeatdownCard off-screen-scale, lets the Q preview it, then
// captures it as a PNG (RepaintBoundary — no extra package needed) and
// shares it via share_plus. Posts more naturally to Slack than raw text.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_history.dart';
import '../theme/app_theme.dart';
import '../widgets/beatdown_card.dart';

class BeatdownCardPreviewScreen extends StatefulWidget {
  final WorkoutHistory entry;
  const BeatdownCardPreviewScreen({super.key, required this.entry});

  @override
  State<BeatdownCardPreviewScreen> createState() =>
      _BeatdownCardPreviewScreenState();
}

class _BeatdownCardPreviewScreenState
    extends State<BeatdownCardPreviewScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _sharing = false;

  Future<void> _shareCard() async {
    setState(() => _sharing = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file =
          File('${dir.path}/beatdown_card_${const Uuid().v4()}.png');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)],
          subject: widget.entry.title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not export card: $e')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: F3Colors.background,
      appBar: AppBar(
        title: const Text('Share as Image'),
        backgroundColor: F3Colors.background,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: FittedBox(
                  child: RepaintBoundary(
                    key: _boundaryKey,
                    child: BeatdownCard(entry: widget.entry),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _sharing ? null : _shareCard,
                  icon: _sharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.share_rounded),
                  label: Text(_sharing ? 'PREPARING…' : 'SHARE IMAGE'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
