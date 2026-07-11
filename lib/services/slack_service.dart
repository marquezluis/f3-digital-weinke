// lib/services/slack_service.dart
// Posts beatdown backblasts to a Slack Incoming Webhook URL.
// The URL is region-specific — each Q pastes their workspace's webhook in Settings.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/workout_history.dart';

class SlackService {
  /// Post a backblast to the configured Slack webhook.
  /// Returns null on success, or an error message string on failure.
  static Future<String?> postBackblast(
    String webhookUrl,
    WorkoutHistory session,
  ) async {
    if (webhookUrl.trim().isEmpty) return 'No Slack webhook URL configured.';

    final buf = StringBuffer();
    buf.writeln('*⚡ F3 BEATDOWN BACKBLAST*');
    buf.writeln('*${session.title}*');
    buf.writeln('📅 ${session.shortDate}');
    if (session.ao.isNotEmpty) buf.writeln('📍 AO: ${session.ao}');
    if (session.q.isNotEmpty) buf.writeln('👑 Q: ${session.q}');
    if (session.totalCount > 0) buf.writeln('💪 PAX Count: ${session.totalCount}');
    if (session.pax.isNotEmpty) buf.writeln('🏃 PAX: ${session.paxDisplay}');
    if (session.fngCount > 0) buf.writeln('🆕 FNGs: ${session.fngCount}');
    buf.writeln();
    buf.writeln('*WORKOUT PLAN*');
    for (final block in session.blocks) {
      buf.writeln('*${block.label.toUpperCase()}* (${block.durationMinutes} min)');
      for (final name in block.exerciseNames) {
        buf.writeln('  • $name');
      }
    }
    if (session.notes.isNotEmpty) {
      buf.writeln();
      buf.writeln('📝 ${session.notes}');
    }
    buf.writeln();
    buf.writeln('_Built with Digital Weinke — F3 Nation_');

    try {
      final response = await http
          .post(
            Uri.parse(webhookUrl.trim()),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': buf.toString()}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.body == 'ok') return null;
      return 'Slack error: ${response.body}';
    } catch (e) {
      return 'Network error: $e';
    }
  }
}
