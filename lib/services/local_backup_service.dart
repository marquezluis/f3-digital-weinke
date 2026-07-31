// lib/services/local_backup_service.dart
// Local backup/import for users who want portability without accounts.

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/region_models.dart';
import '../models/workout_history.dart';
import 'app_profile_service.dart';
import 'history_service.dart';
import 'region_service.dart';

class LocalBackupService {
  static const int currentVersion = 1;
  static const _keyLastAutoBackup = 'local_backup_last_auto_v1';
  static const _autoBackupInterval = Duration(days: 7);
  static const _maxAutoBackups = 3;

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

  // ── Automatic rotating backups ────────────────────────────────────────────
  // Silent safety net on top of the manual export above: most PAX will never
  // remember to export before reinstalling or clearing app data. Throttled to
  // once a week and capped at _maxAutoBackups snapshots so this never grows
  // unbounded on-device.

  static Future<Directory> _autoBackupDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/auto_backups');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Call on every cold start. No-ops if a backup was already taken within
  /// [_autoBackupInterval], or if there's nothing worth protecting yet.
  static Future<void> maybeAutoBackup({
    required AppProfileService profile,
    required HistoryService history,
    required RegionService region,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRaw = prefs.getString(_keyLastAutoBackup);
      final last = lastRaw != null ? DateTime.tryParse(lastRaw) : null;
      if (last != null &&
          DateTime.now().difference(last) < _autoBackupInterval) {
        return;
      }
      if (history.all.isEmpty && profile.displayName.isEmpty) return;

      final json =
          exportJson(profile: profile, history: history, region: region);
      final dir = await _autoBackupDir();
      final file = File(
          '${dir.path}/backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(json);
      await _pruneAutoBackups(dir);
      await prefs.setString(
          _keyLastAutoBackup, DateTime.now().toIso8601String());
    } catch (_) {
      // Best-effort — a failed silent backup should never surface as an
      // error to a PAX who never asked for this in the first place.
    }
  }

  static Future<void> _pruneAutoBackups(Directory dir) async {
    final files = dir.listSync().whereType<File>().toList()
      ..sort((a, b) => b.path.compareTo(a.path)); // newest first (timestamped names)
    for (final f in files.skip(_maxAutoBackups)) {
      try {
        await f.delete();
      } catch (_) {}
    }
  }

  /// Available snapshots, newest first.
  static Future<List<File>> listAutoBackups() async {
    final dir = await _autoBackupDir();
    final files = dir.listSync().whereType<File>().toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  static DateTime? autoBackupTimestamp(File file) {
    final name = file.uri.pathSegments.last;
    final match = RegExp(r'backup_(\d+)\.json').firstMatch(name);
    final millis = match != null ? int.tryParse(match.group(1)!) : null;
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  static Future<void> restoreAutoBackup({
    required File file,
    required AppProfileService profile,
    required HistoryService history,
    required RegionService region,
  }) async {
    final raw = await file.readAsString();
    await importJson(
        raw: raw, profile: profile, history: history, region: region);
  }
}
