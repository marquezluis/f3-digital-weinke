// lib/services/exercise_service.dart
// Loads exercises.json from Flutter assets + custom exercises from SharedPreferences.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise.dart';

class ExerciseService extends ChangeNotifier {
  static const String _assetPath = 'assets/data/exercises.json';
  static const String _customKey = 'custom_exercises_v1';

  List<Exercise> _exercises = [];
  List<Exercise> _customExercises = [];
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString(_assetPath);
    final Map<String, dynamic> data = json.decode(raw) as Map<String, dynamic>;
    final List<dynamic> list = data['exercises'] as List<dynamic>;
    _exercises = list.map((e) => Exercise.fromJson(e as Map<String, dynamic>)).toList();

    // Load custom exercises from SharedPreferences.
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getString(_customKey);
    if (customRaw != null && customRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(customRaw) as List<dynamic>;
        _customExercises = decoded
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _customExercises = [];
      }
    }
    _loaded = true;
  }

  /// All exercises: bundled + custom.
  List<Exercise> get all =>
      List.unmodifiable([..._exercises, ..._customExercises]);

  List<Exercise> get customExercises => List.unmodifiable(_customExercises);

  List<Exercise> byCategory(ExerciseCategory category) =>
      all.where((e) => e.category == category).toList();

  List<Exercise> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return all;
    return all.where((e) {
      return e.name.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q) ||
          e.aliases.any((a) => a.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> addCustomExercise(Exercise exercise) async {
    _customExercises = [..._customExercises, exercise];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customKey,
      jsonEncode(_customExercises.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> deleteCustomExercise(String id) async {
    _customExercises = _customExercises.where((e) => e.id != id).toList();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customKey,
      jsonEncode(_customExercises.map((e) => e.toJson()).toList()),
    );
  }

  // ignore: invalid_use_of_visible_for_testing_member
  void injectForTesting(List<Exercise> exercises) {
    _exercises = List<Exercise>.from(exercises);
    _loaded = true;
  }

  Exercise? findById(String id) => all.where((e) => e.id == id).firstOrNull;

  Map<ExerciseCategory, int> get categoryCounts {
    final counts = <ExerciseCategory, int>{};
    for (final cat in ExerciseCategory.values) {
      counts[cat] = byCategory(cat).length;
    }
    return counts;
  }
}
