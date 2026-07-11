// lib/services/region_service.dart
// Local-first region operations: AOs, PAX, HCs, and attendance.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/region_models.dart';
import '../models/workout_history.dart';

class RegionService extends ChangeNotifier {
  static const _key = 'region_ops_v1';

  final _uuid = const Uuid();
  List<AreaOfOperations> _aos = [];
  List<PaxProfile> _pax = [];
  List<HardCommit> _hardCommits = [];
  List<AttendanceRecord> _attendance = [];
  SharedPreferences? _prefs;

  List<AreaOfOperations> get aos => List.unmodifiable(_aos);
  List<PaxProfile> get pax => List.unmodifiable(_pax);
  List<HardCommit> get hardCommits => List.unmodifiable(_hardCommits);
  List<AttendanceRecord> get attendance => List.unmodifiable(_attendance);

  int get totalHcCount =>
      _hardCommits.fold(0, (sum, hc) => sum + hc.paxNames.length);

  int get totalAttendance =>
      _attendance.fold(0, (sum, entry) => sum + entry.totalCount);

  int get fngCount => _attendance.fold(0, (sum, entry) => sum + entry.fngCount);

  List<AttendanceRecord> get recentAttendance {
    final copy = [..._attendance]..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(copy);
  }

  RegionSnapshot toSnapshot() => RegionSnapshot(
        aos: _aos,
        pax: _pax,
        hardCommits: _hardCommits,
        attendance: _attendance,
      );

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final snapshot = RegionSnapshot.fromJsonString(raw);
      _aos = snapshot.aos;
      _pax = snapshot.pax;
      _hardCommits = snapshot.hardCommits;
      _attendance = snapshot.attendance;
    } catch (_) {
      _aos = [];
      _pax = [];
      _hardCommits = [];
      _attendance = [];
    }
    notifyListeners();
  }

  Future<void> upsertAo({
    String? id,
    required String name,
    String location = '',
    String terrain = '',
    String notes = '',
  }) async {
    final ao = AreaOfOperations(
      id: id ?? _uuid.v4(),
      name: name.trim(),
      location: location.trim(),
      terrain: terrain.trim(),
      notes: notes.trim(),
    );
    _aos = [..._aos.where((item) => item.id != ao.id), ao]
      ..sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    await _save();
  }

  Future<void> upsertPax({
    String? id,
    required String name,
    String phoneOrSlack = '',
    DateTime? birthday,
    DateTime? firstPost,
    String sponsor = '',
    String notes = '',
  }) async {
    final pax = PaxProfile(
      id: id ?? _uuid.v4(),
      name: name.trim(),
      phoneOrSlack: phoneOrSlack.trim(),
      birthday: birthday,
      firstPost: firstPost,
      sponsor: sponsor.trim(),
      notes: notes.trim(),
    );
    _pax = [..._pax.where((item) => item.id != pax.id), pax]
      ..sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    await _save();
  }

  Future<void> addHardCommit({
    required String aoId,
    required DateTime date,
    required List<String> paxNames,
    String q = '',
    String notes = '',
  }) async {
    _hardCommits = [
      HardCommit(
        id: _uuid.v4(),
        aoId: aoId,
        date: date,
        paxNames: _cleanNames(paxNames),
        q: q.trim(),
        notes: notes.trim(),
      ),
      ..._hardCommits,
    ];
    notifyListeners();
    await _save();
  }

  Future<void> recordAttendanceFromHistory(
    WorkoutHistory history, {
    String fngNotes = '',
  }) async {
    for (final name in history.pax) {
      if (!_pax.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
        await upsertPax(name: name);
      }
    }
    if (history.ao.isNotEmpty &&
        !_aos.any((ao) => ao.name.toLowerCase() == history.ao.toLowerCase())) {
      await upsertAo(name: history.ao);
    }

    final record = AttendanceRecord(
      id: _uuid.v4(),
      historyId: history.id,
      aoName: history.ao,
      date: history.date,
      q: history.q,
      paxNames: _cleanNames(history.pax),
      fngCount: history.fngCount,
      fngNotes: fngNotes.trim(),
    );
    _attendance = [
      ..._attendance.where((item) => item.historyId != history.id),
      record,
    ];
    notifyListeners();
    await _save();
  }

  Future<void> replaceSnapshot(RegionSnapshot snapshot) async {
    _aos = snapshot.aos;
    _pax = snapshot.pax;
    _hardCommits = snapshot.hardCommits;
    _attendance = snapshot.attendance;
    notifyListeners();
    await _save();
  }

  List<String> _cleanNames(List<String> names) {
    return names
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _save() async {
    _prefs ??= await SharedPreferences.getInstance();
    final snapshot = RegionSnapshot(
      aos: _aos,
      pax: _pax,
      hardCommits: _hardCommits,
      attendance: _attendance,
    );
    await _prefs!.setString(_key, snapshot.toJsonString());
  }
}
