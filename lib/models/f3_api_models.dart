// lib/models/f3_api_models.dart
// Response models for the F3 Nation REST API (api.f3nation.com).

class F3UserProfile {
  final String id;
  final String f3Name;
  final String email;
  final String? homeRegionId;
  final String? homeRegionName;

  const F3UserProfile({
    required this.id,
    required this.f3Name,
    required this.email,
    this.homeRegionId,
    this.homeRegionName,
  });

  factory F3UserProfile.fromJson(Map<String, dynamic> json) => F3UserProfile(
        id: json['id'] as String? ?? '',
        f3Name: json['f3Name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        homeRegionId: json['homeRegionId'] as String?,
        homeRegionName: json['homeRegion']?['name'] as String?,
      );
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
  final String? qUserId;
  final String? qF3Name;
  final String? locationName;
  final String? eventTypeName;

  const F3EventInstance({
    required this.id,
    required this.eventId,
    required this.date,
    this.qUserId,
    this.qF3Name,
    this.locationName,
    this.eventTypeName,
  });

  bool get hasQ => qUserId != null && qUserId!.isNotEmpty;

  factory F3EventInstance.fromJson(Map<String, dynamic> json) =>
      F3EventInstance(
        id: json['id'] as String? ?? '',
        eventId: json['eventId'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        qUserId: json['qUserId'] as String?,
        qF3Name: json['qUser']?['f3Name'] as String?,
        locationName: json['location']?['name'] as String?,
        eventTypeName: json['eventType']?['name'] as String?,
      );
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
