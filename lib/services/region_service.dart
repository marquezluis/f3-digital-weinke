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
  List<EhProspect> _ehProspects = [];
  SharedPreferences? _prefs;

  List<AreaOfOperations> get aos => List.unmodifiable(_aos);
  List<PaxProfile> get pax => List.unmodifiable(_pax);
  List<HardCommit> get hardCommits => List.unmodifiable(_hardCommits);
  List<AttendanceRecord> get attendance => List.unmodifiable(_attendance);
  List<EhProspect> get ehProspects => List.unmodifiable(
      [..._ehProspects]..sort((a, b) => b.dateAdded.compareTo(a.dateAdded)));

  static const followUpDueAfter = Duration(days: 7);

  /// Prospects whose last contact (a logged follow-up, or the date they
  /// were added if none has been logged yet) is old enough to need another
  /// nudge — the signal the Home widget uses to flag "these need you today"
  /// instead of just showing a flat count.
  List<EhProspect> get prospectsNeedingFollowUp {
    final now = DateTime.now();
    return ehProspects.where((p) {
      final lastContact = p.lastFollowUp ?? p.dateAdded;
      return now.difference(lastContact) >= followUpDueAfter;
    }).toList();
  }

  int get totalHcCount =>
      _hardCommits.fold(0, (sum, hc) => sum + hc.paxNames.length);

  int get totalAttendance =>
      _attendance.fold(0, (sum, entry) => sum + entry.totalCount);

  int get fngCount => _attendance.fold(0, (sum, entry) => sum + entry.fngCount);

  List<AttendanceRecord> get recentAttendance {
    final copy = [..._attendance]..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(copy);
  }

  /// The PAX with the most posts in the last 90 days, from this device's
  /// own locally-logged attendance — there's no nation-wide leaderboard API
  /// to pull from (see [[f3-nation-ecosystem]]), so this is honestly scoped
  /// to what this Q has actually recorded. Returns null rather than crowning
  /// someone off a single beatdown — needs at least 3 recorded posts in the
  /// window to surface at all.
  ({String paxName, int postCount})? get paxOfTheQuarter {
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final counts = <String, int>{};
    for (final entry in _attendance) {
      if (entry.date.isBefore(cutoff)) continue;
      for (final name in entry.paxNames) {
        if (name.trim().isEmpty) continue;
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    final top = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    if (top.value < 3) return null;
    return (paxName: top.key, postCount: top.value);
  }

  RegionSnapshot toSnapshot() => RegionSnapshot(
        aos: _aos,
        pax: _pax,
        hardCommits: _hardCommits,
        attendance: _attendance,
        ehProspects: _ehProspects,
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
      _ehProspects = snapshot.ehProspects;
    } catch (_) {
      _aos = [];
      _pax = [];
      _hardCommits = [];
      _attendance = [];
      _ehProspects = [];
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
    _ehProspects = snapshot.ehProspects;
    notifyListeners();
    await _save();
  }

  // ── EH tracker ─────────────────────────────────────────────────────────────
  // Someone EH'd but not yet posted — see EhProspect's doc comment for how
  // this differs from PaxProfile.

  Future<void> addEhProspect({
    required String name,
    String contactInfo = '',
    String notes = '',
  }) async {
    _ehProspects = [
      ..._ehProspects,
      EhProspect(
        id: _uuid.v4(),
        name: name.trim(),
        contactInfo: contactInfo.trim(),
        dateAdded: DateTime.now(),
        notes: notes.trim(),
      ),
    ];
    notifyListeners();
    await _save();
  }

  Future<void> markProspectFollowedUp(String id) async {
    _ehProspects = _ehProspects
        .map((p) => p.id == id
            ? EhProspect(
                id: p.id,
                name: p.name,
                contactInfo: p.contactInfo,
                dateAdded: p.dateAdded,
                lastFollowUp: DateTime.now(),
                notes: p.notes,
              )
            : p)
        .toList();
    notifyListeners();
    await _save();
  }

  /// They posted — add them as a real PAX and drop them from the prospect
  /// list. Firstpost is set to today; a Q editing history after the fact can
  /// still correct it from the PAX detail screen like any other PaxProfile.
  Future<void> promoteProspectToPax(String id) async {
    final prospect = _ehProspects.where((p) => p.id == id).firstOrNull;
    if (prospect == null) return;
    await upsertPax(
      name: prospect.name,
      phoneOrSlack: prospect.contactInfo,
      firstPost: DateTime.now(),
      notes: prospect.notes,
    );
    _ehProspects = _ehProspects.where((p) => p.id != id).toList();
    notifyListeners();
    await _save();
  }

  Future<void> removeEhProspect(String id) async {
    _ehProspects = _ehProspects.where((p) => p.id != id).toList();
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
      ehProspects: _ehProspects,
    );
    await _prefs!.setString(_key, snapshot.toJsonString());
  }
}
