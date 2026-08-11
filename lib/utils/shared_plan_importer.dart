// lib/utils/shared_plan_importer.dart
// Co-Q plan import (BackblastScreen's "Share plan with Co-Q" clipboard
// payload) — shared between History's dedicated import button and Home's
// Quick Actions entry, so the action isn't only discoverable by someone
// who already happened to open History.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/workout_history.dart';
import '../services/history_service.dart';

/// Parses a shared-plan clipboard payload into the WorkoutHistory entry
/// it should become. Pure and testable — no Clipboard/HistoryService side
/// effects here, just "is this raw string a valid shared plan, and if so
/// what's the resulting entry".
WorkoutHistory parseSharedPlan(String raw) {
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  if (decoded['app'] != 'digital_weinke_plan') {
    throw const FormatException('This is not a shared Digital Weinke plan.');
  }
  final entryJson = decoded['entry'] as Map<String, dynamic>;
  final shared = WorkoutHistory.fromJson(entryJson);
  return shared.copyWith(
    id: 'shared_${DateTime.now().millisecondsSinceEpoch}',
    isTemplate: true,
    rating: 0,
    photoPaths: const [], // sender's local file paths don't exist on this device
  );
}

/// Reads the clipboard, imports if it's a valid shared plan, and reports
/// the outcome via a SnackBar — the full user-facing action both entry
/// points trigger.
Future<void> importSharedPlanFromClipboard(
    BuildContext context, HistoryService history) async {
  final messenger = ScaffoldMessenger.of(context);
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  final raw = data?.text ?? '';
  if (raw.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text('Clipboard is empty.')));
    return;
  }
  try {
    final imported = parseSharedPlan(raw);
    await history.add(imported);
    if (!context.mounted) return;
    messenger.showSnackBar(
        const SnackBar(content: Text('Plan imported — check your History list.')));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
  }
}
