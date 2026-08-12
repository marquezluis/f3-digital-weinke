// lib/services/codex_sync_service.dart
// Syncs against F3 Nation's live, official Exicon
// (codex.f3nation.com/api/exicon — confirmed public, no-auth JSON) in two
// ways:
//   1. Demo video links get overlaid onto matching bundled/custom exercises.
//   2. Every exercise gets tagged Official or Pending — bundled exercises
//      are Official by default (they were sourced from the Exicon at build
//      time); custom (Q-written) exercises stay Pending until a live sync
//      confirms the same name now exists in the real, canonical Exicon —
//      i.e., "this looks like something PAX everywhere would recognize."
//      Visible to any user browsing exercises, not admin-gated.
//
// Deliberately NOT a full data replacement: the live Exicon has richer
// descriptions and real YouTube demo links, but no category/equipment/
// intensity classification — the taxonomy WorkoutGenerator depends on to
// build balanced blocks. Attempting to guess that from the live API's
// freeform community tags would be inaccurate. So this only ever overlays
// videoLink and the official/pending tag, matched by exercise name.
// Manual/on-demand only — no background network calls, matching the app's
// offline-first default.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise.dart';

class CodexSyncResult {
  final int matched;
  final int total;
  final DateTime syncedAt;
  const CodexSyncResult(
      {required this.matched, required this.total, required this.syncedAt});
}

class CodexSyncService extends ChangeNotifier {
  static const _endpoint = 'https://codex.f3nation.com/api/exicon';
  static const _keyLinks = 'codex_video_links_v1';
  static const _keyOfficialNames = 'codex_official_names_v1';
  static const _keySyncedAt = 'codex_video_links_synced_at_v1';

  Map<String, String> _videoLinksByName = {};
  Set<String> _liveExiconNames = {};
  DateTime? _lastSyncedAt;

  /// Exercise name (normalized: lowercase, trimmed) → YouTube demo link.
  Map<String, String> get videoLinksByName =>
      Map.unmodifiable(_videoLinksByName);

  /// Every exercise name (normalized) confirmed present in the live Exicon
  /// as of the last successful sync. Empty until a sync has ever run.
  Set<String> get liveExiconNames => Set.unmodifiable(_liveExiconNames);

  DateTime? get lastSyncedAt => _lastSyncedAt;

  static String normalize(String name) => name.trim().toLowerCase();

  /// Pure parsing/matching step, split out from [sync] so it's testable
  /// without a live network call: given the live Exicon's decoded JSON body
  /// and the app's current exercise list, returns the video-link overlay
  /// (matched by normalized name) and the full set of live-Exicon names.
  static ({Map<String, String> videoLinks, Set<String> liveNames})
      parseAndMatch(List<dynamic> live, List<Exercise> currentExercises) {
    final liveByName = <String, String>{};
    final liveNames = <String>{};
    for (final entry in live) {
      if (entry is! Map<String, dynamic>) continue;
      final name = entry['name'] as String?;
      if (name == null || name.isEmpty) continue;
      final normalized = normalize(name);
      liveNames.add(normalized);
      final link = entry['videoLink'] as String?;
      if (link != null && link.isNotEmpty) liveByName[normalized] = link;
    }

    final matched = <String, String>{};
    for (final ex in currentExercises) {
      final link = liveByName[normalize(ex.name)];
      if (link != null) matched[normalize(ex.name)] = link;
    }

    return (videoLinks: matched, liveNames: liveNames);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLinks);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _videoLinksByName = decoded.map((k, v) => MapEntry(k, v as String));
      } catch (_) {
        _videoLinksByName = {};
      }
    }
    final namesRaw = prefs.getStringList(_keyOfficialNames);
    if (namesRaw != null) _liveExiconNames = namesRaw.toSet();
    final syncedAtMs = prefs.getInt(_keySyncedAt);
    if (syncedAtMs != null) {
      _lastSyncedAt = DateTime.fromMillisecondsSinceEpoch(syncedAtMs);
    }
  }

  /// Fetches the live Exicon, matches by name against [currentExercises],
  /// and persists both the video-link map and the full set of live-Exicon
  /// names. Returns null on any network/parse failure (caller shows an
  /// honest "couldn't sync" message — never silently pretends success).
  Future<CodexSyncResult?> sync(List<Exercise> currentExercises) async {
    final http.Response res;
    try {
      res = await http
          .get(Uri.parse(_endpoint))
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      return null;
    }
    if (res.statusCode != 200) return null;

    List<dynamic> live;
    try {
      live = jsonDecode(res.body) as List<dynamic>;
    } catch (_) {
      return null;
    }

    final result = parseAndMatch(live, currentExercises);

    _videoLinksByName = result.videoLinks;
    _liveExiconNames = result.liveNames;
    _lastSyncedAt = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLinks, jsonEncode(_videoLinksByName));
    await prefs.setStringList(_keyOfficialNames, _liveExiconNames.toList());
    await prefs.setInt(
        _keySyncedAt, _lastSyncedAt!.millisecondsSinceEpoch);

    notifyListeners();
    return CodexSyncResult(
      matched: result.videoLinks.length,
      total: currentExercises.length,
      syncedAt: _lastSyncedAt!,
    );
  }
}
