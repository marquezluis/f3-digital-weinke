// lib/services/spartan_plan_cache_service.dart
// Opportunistic offline fallback for Spartan's "build me a Weinke" flow.
//
// generateWorkoutBlocks (spartan_service.dart) needs a live Gemini call —
// it fails outright with no signal or cell service, which is exactly when a
// Q leaning on Spartan at 5:15 AM in the Gloom would want it most. Rather
// than proactively burning API quota generating plans nobody asked for,
// this caches every successful real generation (from spartan_chat_screen)
// as it happens, rotating out the oldest, so a later offline request has
// something real to fall back to instead of just failing.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CachedSpartanPlan {
  final String label;
  final List<dynamic> blocksJson;
  final DateTime cachedAt;

  const CachedSpartanPlan({
    required this.label,
    required this.blocksJson,
    required this.cachedAt,
  });

  factory CachedSpartanPlan.fromJson(Map<String, dynamic> json) =>
      CachedSpartanPlan(
        label: json['label'] as String? ?? 'Spartan plan',
        blocksJson: json['blocksJson'] as List<dynamic>? ?? const [],
        cachedAt: DateTime.tryParse(json['cachedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'blocksJson': blocksJson,
        'cachedAt': cachedAt.toIso8601String(),
      };
}

class SpartanPlanCacheService {
  static const _key = 'spartan_plan_cache_v1';
  static const maxEntries = 5;

  /// Adds a freshly (successfully) generated plan to the cache, newest
  /// first, trimmed to [maxEntries]. Best-effort — a caching failure should
  /// never surface as an error to a Q who was just trying to build a plan.
  Future<void> cache(String label, List<dynamic> blocksJson) async {
    if (blocksJson.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await _load(prefs);
      final updated = [
        CachedSpartanPlan(
          label: label.trim().isEmpty ? 'Spartan plan' : label.trim(),
          blocksJson: blocksJson,
          cachedAt: DateTime.now(),
        ),
        ...existing,
      ].take(maxEntries).toList();
      await prefs.setString(
        _key,
        jsonEncode(updated.map((e) => e.toJson()).toList()),
      );
    } catch (_) {
      // Best-effort, see doc comment above.
    }
  }

  Future<List<CachedSpartanPlan>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return _load(prefs);
  }

  Future<List<CachedSpartanPlan>> _load(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(CachedSpartanPlan.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// A random cached plan's blocks, or null if nothing's been cached yet —
  /// e.g. a fresh install that's never had a successful online generation.
  Future<CachedSpartanPlan?> randomCached() async {
    final cached = await load();
    if (cached.isEmpty) return null;
    return (List.of(cached)..shuffle()).first;
  }
}
