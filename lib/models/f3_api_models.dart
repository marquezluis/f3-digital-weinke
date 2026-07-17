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

  const F3UserProfile({
    required this.id,
    required this.f3Name,
    required this.email,
    this.firstName,
    this.lastName,
    this.homeRegionId,
    this.homeRegionName,
    this.avatarUrl,
  });

  /// Tolerant of the /me/profile shape: numeric ids arrive as ints (the API
  /// uses numeric user/org ids), the payload may or may not be wrapped in a
  /// `profile` key, and homeRegion may be an expanded object or a flat name.
  factory F3UserProfile.fromJson(Map<String, dynamic> json) {
    final data = json['profile'] is Map<String, dynamic>
        ? json['profile'] as Map<String, dynamic>
        : json;
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
    );
  }

  /// Best display name: F3 handle, else first name, else email local part.
  String get displayName {
    if (f3Name.isNotEmpty) return f3Name;
    if (firstName != null && firstName!.isNotEmpty) return firstName!;
    return email.split('@').first;
  }
}

class F3Location {
  final String id;
  final String name;
  final double? lat;
  final double? lon;
  final String orgId;
  final String? description;

  const F3Location({
    required this.id,
    required this.name,
    this.lat,
    this.lon,
    required this.orgId,
    this.description,
  });

  factory F3Location.fromJson(Map<String, dynamic> json) => F3Location(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        lat: (json['lat'] as num?)?.toDouble(),
        lon: (json['lon'] as num?)?.toDouble(),
        orgId: json['orgId'] as String? ?? '',
        description: json['description'] as String?,
      );
}

class F3EventInstance {
  final String id;
  final String eventId;
  final DateTime date;
  final String? name;
  final String? orgName;
  final String? qUserId;
  final String? qF3Name;
  final String? locationName;
  final String? eventTypeName;

  const F3EventInstance({
    required this.id,
    required this.eventId,
    required this.date,
    this.name,
    this.orgName,
    this.qUserId,
    this.qF3Name,
    this.locationName,
    this.eventTypeName,
  });

  bool get hasQ => qUserId != null && qUserId!.isNotEmpty;
  int? get numericId => int.tryParse(id);

  /// Best display label for a picker row.
  String get displayLabel {
    final where = orgName ?? locationName ?? name ?? 'Event';
    return '$where · ${date.month}/${date.day}';
  }

  /// Tolerant of both the calendar-home shape and the past-qs shape (numeric
  /// ids, `startDate`, `orgName`).
  factory F3EventInstance.fromJson(Map<String, dynamic> json) {
    String? str(dynamic v) => v?.toString();
    final rawDate = str(json['date']) ?? str(json['startDate']) ?? '';
    return F3EventInstance(
      id: str(json['id']) ?? '',
      eventId: str(json['eventId']) ?? '',
      date: DateTime.tryParse(rawDate) ?? DateTime.now(),
      name: str(json['name']),
      orgName: str(json['orgName']),
      qUserId: str(json['qUserId']),
      qF3Name: str(json['qUser'] is Map ? json['qUser']['f3Name'] : null),
      locationName:
          str(json['location'] is Map ? json['location']['name'] : null),
      eventTypeName:
          str(json['eventType'] is Map ? json['eventType']['name'] : null),
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
