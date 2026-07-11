// lib/services/local_backup_service.dart
// Local backup/import for users who want portability without accounts.

import 'dart:convert';

import '../models/region_models.dart';
import '../models/workout_history.dart';
import 'app_profile_service.dart';
import 'history_service.dart';
import 'region_service.dart';

class LocalBackupService {
  static const int currentVersion = 1;

  LocalBackupService._();

  static String exportJson({
    required AppProfileService profile,
    required HistoryService history,
    required RegionService region,
  }) {
    final payload = {
      'app': 'digital_weinke',
      'version': currentVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile.toJson(),
      'history': history.toJsonList(),
      'region': jsonDecode(region.toSnapshot().toJsonString()),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static Future<void> importJson({
    required String raw,
    required AppProfileService profile,
    required HistoryService history,
    required RegionService region,
  }) async {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    if (decoded['app'] != 'digital_weinke') {
      throw const FormatException('This is not a Digital Weinke backup.');
    }

    final profileJson = decoded['profile'] as Map<String, dynamic>? ?? {};
    final historyJson = decoded['history'] as List<dynamic>? ?? [];
    final regionJson = decoded['region'] as Map<String, dynamic>? ?? {};

    final sessions = historyJson
        .map((item) => WorkoutHistory.fromJson(item as Map<String, dynamic>))
        .toList();
    final regionSnapshot =
        RegionSnapshot.fromJsonString(jsonEncode(regionJson));

    await profile.importJson(profileJson);
    await history.replaceAll(sessions);
    await region.replaceSnapshot(regionSnapshot);
  }
}
