// lib/models/f3_api_models.dart
// Response models for the F3 Nation REST API (api.f3nation.com).

class F3UserProfile {
  final String id;
  final String f3Name;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? homeRegionId;
  final String? homeRegionName;
  final String? avatarUrl;
  final String? phone;

  const F3UserProfile({
    required this.id,
    required this.f3Name,
    required this.email,
    this.firstName,
    this.lastName,
    this.homeRegionId,
    this.homeRegionName,
    this.avatarUrl,
    this.phone,
  });

  /// Tolerant of the /me/profile shape: numeric ids arrive as ints (the API
  /// uses numeric user/org ids), the payload may be wrapped in a `profile`
  /// or `user` key (confirmed live: `/v1/me/profile` actually wraps in
  /// `user`, not `profile`), and homeRegion may be an expanded object or a
  /// flat name.
  factory F3UserProfile.fromJson(Map<String, dynamic> json) {
    final wrapper = json['profile'] ?? json['user'];
    final data =
        wrapper is Map<String, dynamic> ? wrapper : json;
    String? str(dynamic v) {
      final s = v?.toString();
      return (s == null || s.isEmpty || s == 'null') ? null : s;
    }

    final homeRegion = data['homeRegion'];
    return F3UserProfile(
      id: str(data['id']) ?? '',
      f3Name: str(data['f3Name']) ?? '',
      email: str(data['email']) ?? '',
      firstName: str(data['firstName']),
      lastName: str(data['lastName']),
      homeRegionId: str(data['homeRegionId']),
      homeRegionName: str(homeRegion is Map
          ? homeRegion['name']
          : data['homeRegionName'] ?? data['homeRegionOrgName']),
      avatarUrl: str(data['avatarUrl']),
      phone: str(data['phone']),
    );
  }

  /// Best display name: F3 handle, else first name, else email local part.
  String get displayName {
    if (f3Name.isNotEmpty) return f3Name;
    if (firstName != null && firstName!.isNotEmpty) return firstName!;
    return email.split('@').first;
  }
}

/// One recurring weekly meeting time for an AO, e.g. "tuesday" @ "0530"
/// doing a Bootcamp. Sourced from `GET /v1/event` (the recurring-series
/// entity — distinct from `/v1/event-instance`, which is a specific dated
/// occurrence).
class F3WeeklyWorkout {
  final String weekday; // lowercase: monday, tuesday, ...
  final String time; // military, e.g. "0530"
  final String? eventTypeName;

  const F3WeeklyWorkout(
      {required this.weekday, required this.time, this.eventTypeName});

  /// "5:30 AM"
  String get displayTime {
    final h = int.tryParse(time.length >= 2 ? time.substring(0, 2) : '');
    final m = int.tryParse(time.length >= 4 ? time.substring(2, 4) : '');
    if (h == null || m == null) return time;
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${m.toString().padLeft(2, '0')} $period';
  }

  /// "Tue"
  String get displayWeekday =>
      weekday.length >= 3 ? weekday[0].toUpperCase() + weekday.substring(1, 3) : weekday;
}

class F3Location {
  final String id;
  final String name;
  final double? lat;
  final double? lon;
  final String orgId; // the region org id (from /v1/location's regionId)
  final String? regionName;
  final String? description;
  final String? state;
  final String? street;
  final String? city;
  final List<F3WeeklyWorkout> schedule;
  // The AO's own display name (distinct from the region) — only known once
  // joined against `/v1/event`, since `/v1/location` itself doesn't carry it.
  final String? aoName;

  const F3Location({
    required this.id,
    required this.name,
    this.lat,
    this.lon,
    required this.orgId,
    this.regionName,
    this.description,
    this.state,
    this.street,
    this.city,
    this.schedule = const [],
    this.aoName,
  });

  F3Location withSchedule(List<F3WeeklyWorkout> schedule, {String? aoName}) =>
      F3Location(
        id: id,
        name: name,
        lat: lat,
        lon: lon,
        orgId: orgId,
        regionName: regionName,
        description: description,
        state: state,
        street: street,
        city: city,
        schedule: schedule,
        aoName: aoName ?? this.aoName,
      );

  /// `GET /v1/location` returns `locationName`/`latitude`/`longitude`/
  /// `regionId` (numeric), not `name`/`lat`/`lon`/`orgId` (string) — tolerant
  /// of both so older/other callers of this model don't break.
  factory F3Location.fromJson(Map<String, dynamic> json) => F3Location(
        id: json['id']?.toString() ?? '',
        name: (json['name'] ?? json['locationName'])?.toString() ?? '',
        lat: ((json['lat'] ?? json['latitude']) as num?)?.toDouble(),
        lon: ((json['lon'] ?? json['longitude']) as num?)?.toDouble(),
        orgId: (json['orgId'] ?? json['regionId'])?.toString() ?? '',
        regionName: json['regionName'] as String?,
        description: json['description'] as String?,
        state: (json['addressState'] as String?)?.trim(),
        street: json['addressStreet'] as String?,
        city: json['addressCity'] as String?,
      );
}

class F3EventInstance {
  final String id;
  final String eventId;
  final DateTime date;
  final String? name;
  final int? orgId;
  final String? orgName;
  final String? startTime;
  final String? qF3Name;
  final String? locationName;
  final String? eventTypeName;
  final String? preblast;
  final int? hcCount;
  final bool userAttending;
  final bool userIsQ;

  const F3EventInstance({
    required this.id,
    required this.eventId,
    required this.date,
    this.name,
    this.orgId,
    this.orgName,
    this.startTime,
    this.qF3Name,
    this.locationName,
    this.eventTypeName,
    this.preblast,
    this.hcCount,
    this.userAttending = false,
    this.userIsQ = false,
  });

  bool get hasQ => qF3Name != null && qF3Name!.isNotEmpty;
  int? get numericId => int.tryParse(id);

  /// [date] combined with the military [startTime] ("0530") — falls back to
  /// midnight on [date] if there's no start time. Used to schedule
  /// day-before/hour-before reminders.
  DateTime get dateTime {
    final t = startTime;
    if (t == null || t.length < 4) return date;
    final h = int.tryParse(t.substring(0, 2));
    final m = int.tryParse(t.substring(2, 4));
    if (h == null || m == null) return date;
    return DateTime(date.year, date.month, date.day, h, m);
  }

  /// Best display label for a picker row.
  String get displayLabel {
    final where = orgName ?? locationName ?? name ?? 'Event';
    return '$where · ${date.month}/${date.day}';
  }

  /// Tolerant of the several event-instance response shapes the API returns:
  /// calendar-home-schedule (`plannedQs` as a comma-separated name string,
  /// `eventTypes: [{id, name}]`, `userAttending`/`userIsQ` flags), the single
  /// -event GET (`eventTypes: [{eventTypeId, eventTypeName}]`), and the
  /// past-qs shape (numeric ids, `startDate`, `orgName`).
  factory F3EventInstance.fromJson(Map<String, dynamic> json) {
    String? str(dynamic v) => v?.toString();
    final rawDate = str(json['date']) ?? str(json['startDate']) ?? '';
    final hc = json['hcCount'] ?? json['paxCount'];
    final eventTypes = json['eventTypes'];
    String? typeName;
    if (eventTypes is List && eventTypes.isNotEmpty) {
      final first = eventTypes.first;
      if (first is Map) {
        typeName = str(first['name'] ?? first['eventTypeName']);
      }
    } else if (json['eventType'] is Map) {
      typeName = str(json['eventType']['name']);
    }
    return F3EventInstance(
      id: str(json['id']) ?? '',
      eventId: str(json['eventId']) ?? '',
      date: DateTime.tryParse(rawDate) ?? DateTime.now(),
      name: str(json['name']),
      // The AO-level org (not the region) — writes must reuse this, never
      // the signed-in user's region orgId, or the event gets reassigned to
      // the region org on update.
      orgId: json['orgId'] is int
          ? json['orgId'] as int
          : int.tryParse(str(json['orgId']) ?? ''),
      orgName: str(json['orgName'] ?? (json['org'] is Map ? json['org']['name'] : null)),
      startTime: str(json['startTime']),
      qF3Name: str(json['plannedQs'] ?? (json['qUser'] is Map ? json['qUser']['f3Name'] : null)),
      locationName:
          str(json['location'] is Map ? json['location']['name'] : null),
      eventTypeName: typeName,
      preblast: str(json['preblast']),
      hcCount: hc is int ? hc : int.tryParse(hc?.toString() ?? ''),
      userAttending: json['userAttending'] == true,
      userIsQ: json['userIsQ'] == true,
    );
  }
}

class F3Org {
  final String id;
  final String name;
  final String type;
  final String? parentId;

  const F3Org({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
  });

  factory F3Org.fromJson(Map<String, dynamic> json) => F3Org(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? '',
        parentId: json['parentId'] as String?,
      );
}
