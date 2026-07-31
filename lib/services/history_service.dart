// lib/services/history_service.dart
// Local-only workout history persistence via shared_preferences.
// Uses ChangeNotifier so the History screen rebuilds automatically.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_history.dart';

class HistoryService extends ChangeNotifier {
  static const _key = 'workout_history_v1';

  final List<WorkoutHistory> _items = [];
  SharedPreferences? _prefs;

  /// Immutable, newest-first view.
  List<WorkoutHistory> get all => List.unmodifiable(_items);

  List<Map<String, dynamic>> toJsonList() =>
      _items.map((entry) => entry.toJson()).toList();

  /// Exercise names used across the last [sessions] real (non-template)
  /// beatdowns — feeds WorkoutGenerator's recency bias so a Q doesn't get
  /// Merkins and Burpees in every random plan just because they're common in
  /// the pool. Templates are excluded: a saved reusable plan isn't a signal
  /// that "this was just run," so it shouldn't suppress itself from future
  /// random generation.
  Set<String> recentlyUsedExerciseNames({int sessions = 5}) {
    final names = <String>{};
    for (final entry in _items.where((e) => !e.isTemplate).take(sessions)) {
      for (final block in entry.blocks) {
        names.addAll(block.exerciseNames);
      }
    }
    return names;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Load persisted history.  Call once at app startup.
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final loaded = decoded
          .map((e) => WorkoutHistory.fromJson(e as Map<String, dynamic>))
          .toList();
      _items
        ..clear()
        ..addAll(loaded);
      _sort();
    } catch (_) {
      // Corrupt data — start fresh rather than crash.
      _items.clear();
    }
    notifyListeners();
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  /// Add a new entry and persist.
  Future<void> add(WorkoutHistory entry) async {
    _items.add(entry);
    _sort();
    notifyListeners();
    await _save();
  }

  /// Replace an existing entry (same id) and persist.
  Future<void> update(WorkoutHistory updated) async {
    final idx = _items.indexWhere((e) => e.id == updated.id);
    if (idx == -1) {
      await add(updated);
      return;
    }
    _items[idx] = updated;
    _sort();
    notifyListeners();
    await _save();
  }

  /// Delete by id and persist.
  Future<void> delete(String id) async {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    await _save();
  }

  /// Wipe all history and persist.
  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _save();
  }

  Future<void> replaceAll(List<WorkoutHistory> entries) async {
    _items
      ..clear()
      ..addAll(entries);
    _sort();
    notifyListeners();
    await _save();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _sort() {
    _items.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _save() async {
    _prefs ??= await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.map((e) => e.toJson()).toList());
    await _prefs!.setString(_key, encoded);
  }
}
