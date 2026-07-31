// lib/models/region_models.dart
// Local-first region data: AOs, PAX, HCs, and attendance records.

import 'dart:convert';

class AreaOfOperations {
  final String id;
  final String name;
  final String location;
  final String terrain;
  final String notes;

  const AreaOfOperations({
    required this.id,
    required this.name,
    this.location = '',
    this.terrain = '',
    this.notes = '',
  });

  factory AreaOfOperations.fromJson(Map<String, dynamic> json) =>
      AreaOfOperations(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        location: json['location'] as String? ?? '',
        terrain: json['terrain'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'terrain': terrain,
        'notes': notes,
      };
}

class PaxProfile {
  final String id;
  final String name;
  final String phoneOrSlack;
  final DateTime? birthday;
  final DateTime? firstPost;
  final String sponsor;
  final String notes;

  const PaxProfile({
    required this.id,
    required this.name,
    this.phoneOrSlack = '',
    this.birthday,
    this.firstPost,
    this.sponsor = '',
    this.notes = '',
  });

  factory PaxProfile.fromJson(Map<String, dynamic> json) => PaxProfile(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phoneOrSlack: json['phoneOrSlack'] as String? ?? '',
        birthday: DateTime.tryParse(json['birthday'] as String? ?? ''),
        firstPost: DateTime.tryParse(json['firstPost'] as String? ?? ''),
        sponsor: json['sponsor'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phoneOrSlack': phoneOrSlack,
        if (birthday != null) 'birthday': birthday!.toIso8601String(),
        if (firstPost != null) 'firstPost': firstPost!.toIso8601String(),
        'sponsor': sponsor,
        'notes': notes,
      };
}

class HardCommit {
  final String id;
  final String aoId;
  final DateTime date;
  final List<String> paxNames;
  final String q;
  final String notes;

  const HardCommit({
    required this.id,
    required this.aoId,
    required this.date,
    this.paxNames = const [],
    this.q = '',
    this.notes = '',
  });

  factory HardCommit.fromJson(Map<String, dynamic> json) => HardCommit(
        id: json['id'] as String? ?? '',
        aoId: json['aoId'] as String? ?? '',
        date:
            DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        paxNames: (json['paxNames'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        q: json['q'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'aoId': aoId,
        'date': date.toIso8601String(),
        'paxNames': paxNames,
        'q': q,
        'notes': notes,
      };
}

class AttendanceRecord {
  final String id;
  final String historyId;
  final String aoName;
  final DateTime date;
  final String q;
  final List<String> paxNames;
  final int fngCount;
  final String fngNotes;

  const AttendanceRecord({
    required this.id,
    required this.historyId,
    required this.aoName,
    required this.date,
    this.q = '',
    this.paxNames = const [],
    this.fngCount = 0,
    this.fngNotes = '',
  });

  int get totalCount => paxNames.length + fngCount;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: json['id'] as String? ?? '',
        historyId: json['historyId'] as String? ?? '',
        aoName: json['aoName'] as String? ?? '',
        date:
            DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        q: json['q'] as String? ?? '',
        paxNames: (json['paxNames'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        fngCount: json['fngCount'] as int? ?? 0,
        fngNotes: json['fngNotes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'historyId': historyId,
        'aoName': aoName,
        'date': date.toIso8601String(),
        'q': q,
        'paxNames': paxNames,
        'fngCount': fngCount,
        'fngNotes': fngNotes,
      };
}

/// Someone a PAX has EH'd (Exhort/Harass/invite) but who hasn't posted yet —
/// distinct from [PaxProfile], which represents someone already in the
/// roster. Promoting a prospect to a real PAX (once they post) removes it
/// from here rather than converting in place, since a PaxProfile's `sponsor`
/// field already covers "who brought them" once they exist.
class EhProspect {
  final String id;
  final String name;
  final String contactInfo;
  final DateTime dateAdded;
  final DateTime? lastFollowUp;
  final String notes;

  const EhProspect({
    required this.id,
    required this.name,
    this.contactInfo = '',
    required this.dateAdded,
    this.lastFollowUp,
    this.notes = '',
  });

  factory EhProspect.fromJson(Map<String, dynamic> json) => EhProspect(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        contactInfo: json['contactInfo'] as String? ?? '',
        dateAdded:
            DateTime.tryParse(json['dateAdded'] as String? ?? '') ??
                DateTime.now(),
        lastFollowUp: DateTime.tryParse(json['lastFollowUp'] as String? ?? ''),
        notes: json['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'contactInfo': contactInfo,
        'dateAdded': dateAdded.toIso8601String(),
        if (lastFollowUp != null)
          'lastFollowUp': lastFollowUp!.toIso8601String(),
        'notes': notes,
      };
}

class RegionSnapshot {
  final List<AreaOfOperations> aos;
  final List<PaxProfile> pax;
  final List<HardCommit> hardCommits;
  final List<AttendanceRecord> attendance;
  final List<EhProspect> ehProspects;

  const RegionSnapshot({
    this.aos = const [],
    this.pax = const [],
    this.hardCommits = const [],
    this.attendance = const [],
    this.ehProspects = const [],
  });

  factory RegionSnapshot.fromJsonString(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return RegionSnapshot(
      aos: (json['aos'] as List<dynamic>?)
              ?.map((e) => AreaOfOperations.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pax: (json['pax'] as List<dynamic>?)
              ?.map((e) => PaxProfile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      hardCommits: (json['hardCommits'] as List<dynamic>?)
              ?.map((e) => HardCommit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      attendance: (json['attendance'] as List<dynamic>?)
              ?.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ehProspects: (json['ehProspects'] as List<dynamic>?)
              ?.map((e) => EhProspect.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String toJsonString() => jsonEncode({
        'aos': aos.map((e) => e.toJson()).toList(),
        'pax': pax.map((e) => e.toJson()).toList(),
        'hardCommits': hardCommits.map((e) => e.toJson()).toList(),
        'attendance': attendance.map((e) => e.toJson()).toList(),
        'ehProspects': ehProspects.map((e) => e.toJson()).toList(),
      });
}
