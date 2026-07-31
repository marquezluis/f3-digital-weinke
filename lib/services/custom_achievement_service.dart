// lib/services/custom_achievement_service.dart
// Local persistence for Site-Q-defined achievements (see CustomAchievement).
// Unlock status itself is computed on demand by AchievementService.computeCustom
// — this service only owns the definitions, same split as the built-in
// badges (achievement_service.dart) vs. history (history_service.dart).

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/custom_achievement.dart';

class CustomAchievementService extends ChangeNotifier {
  static const _key = 'custom_achievements_v1';
  static const _uuid = Uuid();

  List<CustomAchievement> _items = [];
  SharedPreferences? _prefs;

  List<CustomAchievement> get all => List.unmodifiable(_items);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _items = decoded
          .whereType<Map<String, dynamic>>()
          .map(CustomAchievement.fromJson)
          .toList();
    } catch (_) {
      _items = [];
    }
    notifyListeners();
  }

  Future<void> add({
    required String title,
    String emoji = '🎖️',
    required CustomAchievementThreshold thresholdType,
    required int thresholdValue,
    String? aoFilter,
  }) async {
    _items = [
      ..._items,
      CustomAchievement(
        id: 'custom_${_uuid.v4()}',
        title: title.trim(),
        emoji: emoji,
        thresholdType: thresholdType,
        thresholdValue: thresholdValue,
        aoFilter: aoFilter?.trim(),
      ),
    ];
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _items = _items.where((a) => a.id != id).toList();
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!
        .setString(_key, jsonEncode(_items.map((a) => a.toJson()).toList()));
  }
}
