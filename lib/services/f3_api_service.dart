// lib/services/f3_api_service.dart
// F3 Nation REST API client. All methods return null/empty on failure so
// callers can fall back to local data without crashing.
//
// The API key is baked in at build time via --dart-define=F3_API_KEY=...
// It is never stored on-device or exposed through any UI.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/f3_api_models.dart';

class F3ApiService extends ChangeNotifier {
  // Override with --dart-define=F3_API_BASE_URL=https://staging.api.f3nation.com
  // for end-to-end testing against the staging stack (pairs with
  // F3_AUTH_ISSUER=https://staging.auth2.f3nation.com — staging-issued OAuth
  // JWTs only verify against the staging API's JWKS lookup, not prod).
  static const _base = String.fromEnvironment(
    'F3_API_BASE_URL',
    defaultValue: 'https://api.f3nation.com',
  );
  static const _client = 'f3-digital-weinke';

  // Compile-time constants injected via --dart-define
  static const _apiKey = String.fromEnvironment('F3_API_KEY');
  static const _orgIdEnv = String.fromEnvironment('F3_API_ORG_ID');

  // Set at runtime from the signed-in user's home region (via applyF3Profile).
  // Prefer it over the build-time default so each PAX gets their own region
  // for upcoming-beatdown filtering and Slack routing, instead of one org
  // baked into the build.
  String? _userOrgId;
  set userOrgId(String? value) {
    if (value == _userOrgId) return;
    _userOrgId = (value != null && value.isNotEmpty) ? value : null;
    notifyListeners();
  }

  String? get orgId => _userOrgId ?? (_orgIdEnv.isNotEmpty ? _orgIdEnv : null);

  bool get isConfigured => _apiKey.isNotEmpty;

  // Set when a call authenticated with the signed-in PAX's own F3 Nation
  // token (bearerOverride, not the app's shared key) comes back 401 — a
  // genuine dead session (revoked/expired refresh token), never a network
  // failure or timeout, and never a 401 on an app-key call (that would mean
  // the app's own key is broken, not the user's — a different problem
  // re-signing in wouldn't fix). See _AppEntryState in main.dart for where
  // this routes back to the login gate.
  bool _sessionInvalid = false;
  bool get sessionInvalid => _sessionInvalid;

  void _markSessionInvalid() {
    if (_sessionInvalid) return;
    _sessionInvalid = true;
    notifyListeners();
  }

  /// Called after a successful re-sign-in so the flag doesn't stick forever.
  void clearSessionInvalid() {
    if (!_sessionInvalid) return;
    _sessionInvalid = false;
    notifyListeners();
  }

  F3UserProfile? _myProfile;
  F3UserProfile? get myProfile => _myProfile;

  // No-op — kept so main.dart callers don't need to change
  Future<void> load() async {}

  Map<String, String> _headers([String? bearerOverride]) => {
        'Authorization': 'Bearer ${bearerOverride ?? _apiKey}',
        'Client': _client,
        'Content-Type': 'application/json',
      };

  /// [bearerOverride] lets a caller authenticate as a specific signed-in user
  /// (their F3 Nation OAuth access token) instead of the app's shared API
  /// key. This matters for endpoints like /v1/me/profile: the API key
  /// resolves to whoever *owns* the key, not whichever PAX is using the app,
  /// so per-user endpoints need the user's own bearer token.
  Future<Map<String, dynamic>?> _get(String path,
      {String? bearerOverride}) async {
    if (bearerOverride == null && !isConfigured) return null;
    try {
      final res = await http
          .get(Uri.parse('$_base$path'), headers: _headers(bearerOverride))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
      if (res.statusCode == 401 && bearerOverride != null) {
        _markSessionInvalid();
      }
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>?> _getList(String path, {String? bearerOverride}) async {
    if (bearerOverride == null && !isConfigured) return null;
    try {
      final res = await http
          .get(Uri.parse('$_base$path'), headers: _headers(bearerOverride))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 401 && bearerOverride != null) {
        _markSessionInvalid();
      }
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body is List) return body;
        if (body is Map && body['data'] is List) return body['data'] as List;
        if (body is Map && body['eventInstances'] is List) {
          return body['eventInstances'] as List;
        }
        if (body is Map && body['events'] is List) {
          return body['events'] as List;
        }
        if (body is Map && body['orgs'] is List) {
          return body['orgs'] as List;
        }
        if (body is Map && body['locations'] is List) {
          return body['locations'] as List;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Generic authenticated DELETE. Returns (statusCode, decodedBodyOrNull).
  /// [payload], when given, is sent as a JSON body — confirmed against the
  /// real API (empirically, against staging) that routes without path
  /// template params (e.g. `/attendance/remove-q`) read their input from
  /// the DELETE body, not the query string; a query string there fails
  /// oRPC's own input validation with a 400 ("expected object, received
  /// undefined") before the handler ever runs.
  Future<({int status, dynamic body})> _delete(
    String path, {
    Map<String, dynamic>? payload,
    String? bearerOverride,
  }) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$_base$path'),
            headers: _headers(bearerOverride),
            body: payload != null ? json.encode(payload) : null,
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 401 && bearerOverride != null) {
        _markSessionInvalid();
      }
      dynamic decoded;
      try {
        decoded = res.body.isNotEmpty ? json.decode(res.body) : null;
      } catch (_) {}
      return (status: res.statusCode, body: decoded);
    } catch (e) {
      return (status: -1, body: e.toString());
    }
  }

  /// Generic authenticated POST. Returns (statusCode, decodedBodyOrNull).
  /// Used by the publish flow to write event instances and attendance.
  Future<({int status, dynamic body})> _post(
    String path,
    Map<String, dynamic> payload, {
    String? bearerOverride,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base$path'),
            headers: _headers(bearerOverride),
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 401 && bearerOverride != null) {
        _markSessionInvalid();
      }
      dynamic decoded;
      try {
        decoded = res.body.isNotEmpty ? json.decode(res.body) : null;
      } catch (_) {}
      return (status: res.statusCode, body: decoded);
    } catch (e) {
      return (status: -1, body: e.toString());
    }
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  /// Fetches the signed-in user's own profile. Pass [userAccessToken] (the
  /// F3 Nation OAuth access token from [AuthService.getF3AccessToken]) to get
  /// the actual signed-in PAX's profile — without it, this authenticates
  /// with the shared app API key and returns that key's owner instead.
  Future<F3UserProfile?> getMyProfile({String? userAccessToken}) async {
    final data = await _get('/v1/me/profile', bearerOverride: userAccessToken);
    if (data == null) return null;
    _myProfile = F3UserProfile.fromJson(data);
    notifyListeners();
    return _myProfile;
  }

  /// Updates the signed-in PAX's own F3 Nation user record. Uses the app's
  /// trusted API key (`POST /v1/user`), not the user's own token — Tackle's
  /// guidance: `/v1/me/profile` (PATCH) is user-token self-service, but a
  /// third-party app should write through its own trusted key instead. Only
  /// non-null fields are sent, so callers can update just what changed.
  /// Returns null on success, else an error string.
  Future<String?> updateUserProfile({
    required int userId,
    String? f3Name,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    final payload = <String, dynamic>{
      'id': userId,
      if (f3Name != null) 'f3Name': f3Name,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    };
    final res = await _post('/v1/user', payload);
    if (res.status == 200 || res.status == 201) return null;
    return 'Profile update failed (${res.status}): ${res.body}';
  }

  Future<F3UserProfile?> findPaxByF3Name(String f3Name) async {
    final data = await _get('/v1/user/f3name/${Uri.encodeComponent(f3Name)}');
    if (data == null) return null;
    return F3UserProfile.fromJson(data);
  }

  // ── Locations / AOs ───────────────────────────────────────────────────────

  /// All active AOs nationwide (Browse AOs is a national/GPS-sorted browse,
  /// not scoped to the signed-in user's region). The response is wrapped in
  /// a `locations` key, not a bare list or `data`/`eventInstances`/`events`.
  List<F3Location>? _cachedLocations;

  Future<List<F3Location>> getLocations({bool forceRefresh = false}) async {
    if (_cachedLocations != null && !forceRefresh) return _cachedLocations!;
    final data = await _get('/v1/location?pageSize=5000');
    if (data == null) return _cachedLocations ?? [];
    final list = data['locations'] as List<dynamic>? ?? [];
    final locations = list
        .map((e) => F3Location.fromJson(e as Map<String, dynamic>))
        .toList();
    _cachedLocations = locations;
    return locations;
  }

  Map<int, F3Location>? _cachedAoLocations;

  /// Maps each AO's org id to its physical location (lat/lon + address).
  /// Neither `/v1/event-instance` nor `/v1/location` alone carries this —
  /// `/v1/location`'s own `orgId` is the *region*, not the AO — so this
  /// joins `/v1/event`'s `parents[].parentId` (the AO org id) against
  /// `/v1/location` on `locationId`. Used for a "get directions" action on
  /// a Schedule event, which only has the AO org id to work with.
  Future<Map<int, F3Location>> getAoLocations(
      {bool forceRefresh = false}) async {
    if (_cachedAoLocations != null && !forceRefresh) return _cachedAoLocations!;
    final results = await Future.wait([
      getLocations(forceRefresh: forceRefresh),
      _get('/v1/event?pageSize=10000'),
    ]);
    final locations = results[0] as List<F3Location>;
    final locById = {for (final l in locations) l.id: l};
    final eventData = results[1] as Map<String, dynamic>?;
    final events = eventData?['events'] as List<dynamic>? ?? [];
    final map = <int, F3Location>{};
    for (final e in events) {
      if (e is! Map) continue;
      final loc = locById[e['locationId']?.toString()];
      if (loc == null) continue;
      final parents = e['parents'];
      if (parents is! List) continue;
      for (final p in parents) {
        if (p is! Map) continue;
        final aoOrgId = p['parentId'] is int
            ? p['parentId'] as int
            : int.tryParse(p['parentId']?.toString() ?? '');
        if (aoOrgId != null) map[aoOrgId] = loc;
      }
    }
    _cachedAoLocations = map;
    return map;
  }

  /// Recurring weekly workout series, keyed by `locationId` — sourced from
  /// `GET /v1/event` (the recurring-series entity; distinct from
  /// `/v1/event-instance`, which is one dated occurrence). This is the same
  /// data the F3 Nation admin's "Events" table shows (AO, Location, Day of
  /// Week). Also carries each location's AO display name, which
  /// `/v1/location` itself doesn't expose.
  Future<Map<String, ({List<F3WeeklyWorkout> schedule, String? aoName})>>
      getLocationSchedules() async {
    final data = await _get('/v1/event?pageSize=10000');
    if (data == null) return {};
    final events = data['events'] as List<dynamic>? ?? [];
    final result =
        <String, ({List<F3WeeklyWorkout> schedule, String? aoName})>{};
    for (final e in events) {
      if (e is! Map) continue;
      final locationId = e['locationId']?.toString();
      final weekday = e['dayOfWeek']?.toString();
      final time = e['startTime']?.toString();
      if (locationId == null || weekday == null || time == null) continue;
      final types = e['eventTypes'];
      String? typeName;
      if (types is List && types.isNotEmpty && types.first is Map) {
        typeName = (types.first as Map)['eventTypeName']?.toString();
      }
      final parents = e['parents'];
      String? aoName;
      if (parents is List && parents.isNotEmpty && parents.first is Map) {
        aoName = (parents.first as Map)['parentName']?.toString();
      }
      final existing = result[locationId];
      final schedule = [
        ...?existing?.schedule,
        F3WeeklyWorkout(weekday: weekday, time: time, eventTypeName: typeName),
      ];
      result[locationId] =
          (schedule: schedule, aoName: aoName ?? existing?.aoName);
    }
    return result;
  }

  // ── Events / Beatdowns ────────────────────────────────────────────────────

  /// [userId] is required by the API (`regionOrgId` + `userId` together
  /// select the signed-in PAX's calendar) — without it the endpoint 400s
  /// and this silently falls back to an empty list. Recurring series now
  /// generate instances far into the future (seen out past a year), so this
  /// pins `startDate` to [from] (date-only — still includes that day's
  /// events even if their time already passed) to avoid pulling and paging
  /// through a huge, mostly-irrelevant backlog. Defaults to today for the
  /// Schedule list view; the calendar view passes the viewed month's start
  /// (including past months, so backblasts can still be added after the
  /// fact for days that already happened).
  Future<List<F3EventInstance>> getUpcomingBeatdowns(
      {String? userAccessToken,
      int? userId,
      DateTime? from,
      int limit = 200}) async {
    if (orgId == null || userId == null) return [];
    final d = from ?? DateTime.now();
    final startDate =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final path =
        '/v1/event-instance/calendar-home-schedule?regionOrgId=$orgId&userId=$userId&startDate=$startDate&limit=$limit';
    final data = await _getList(path, bearerOverride: userAccessToken);
    if (data == null) return [];
    return data
        .map((e) => F3EventInstance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Who's HC'd (planned attendance) for one event instance — names + role
  /// (PAX/Q/Co-Q). The API deliberately allows any authenticated caller to
  /// read this ("for preblast visibility"), so the app's own key works here
  /// same as the other read endpoints.
  Future<List<F3AttendanceRecord>> getAttendanceForEvent(
      int eventInstanceId) async {
    final data = await _get(
        '/v1/attendance/event-instance/$eventInstanceId?isPlanned=true');
    final list = data?['attendance'] as List?;
    if (list == null) return [];
    return list
        .map((e) => F3AttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<F3EventInstance>> getOpenQSlots() async {
    final path = orgId != null
        ? '/v1/event-instance/without-q?regionOrgId=$orgId'
        : '/v1/event-instance/without-q';
    final data = await _getList(path);
    if (data == null) return [];
    return data
        .map((e) => F3EventInstance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Orgs / Regions ────────────────────────────────────────────────────────

  List<F3Org>? _cachedOrgs;

  /// All regions nationwide (492 as of 2026-07 — small enough to load in one
  /// call and search client-side; the endpoint defaults to `pageSize=10`
  /// without this override). `/v1/org` has no server-side name/search filter
  /// (confirmed: `name`/`search`/`q` params are silently ignored, `total`
  /// stays 492 regardless) so there's no cheaper query to make per-keystroke
  /// — caching the one full fetch is what actually avoids the repeat ~220KB
  /// pull every time the region picker sheet is reopened.
  Future<List<F3Org>> getOrgs({bool forceRefresh = false}) async {
    if (_cachedOrgs != null && !forceRefresh) return _cachedOrgs!;
    final data = await _getList('/v1/org?pageSize=5000');
    if (data == null) return _cachedOrgs ?? [];
    try {
      final orgs =
          data.map((e) => F3Org.fromJson(e as Map<String, dynamic>)).toList();
      _cachedOrgs = orgs;
      return orgs;
    } catch (_) {
      // Matches this file's return-empty-on-failure contract instead of
      // letting a shape-drift bug hang the region picker mid-load (see
      // F3Org.fromJson — this already bit us once against real staging data).
      return _cachedOrgs ?? [];
    }
  }

  // ── Publish flow (backblast + attendance to F3 Nation) ────────────────────
  // These write real records. Attendance type IDs (confirmed from the F3
  // Nation seed data): 1 = PAX, 2 = Q, 3 = Co-Q.

  static const int attendanceTypePax = 1;
  static const int attendanceTypeQ = 2;

  /// Past events where [userId] was Q/Co-Q, filtered server-side to those with
  /// no backblast posted yet. Requires the user's own token (protected route).
  Future<List<F3EventInstance>> getPastQsWithoutBackblast({
    required String userId,
    required String regionOrgId,
    required String userAccessToken,
  }) async {
    final data = await _getList(
      '/v1/event-instance/past-qs?userId=$userId&regionOrgId=$regionOrgId&notPostedOnly=true',
      bearerOverride: userAccessToken,
    );
    if (data == null) return [];
    return data
        .map((e) => F3EventInstance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Writes the backblast text + counts onto an event instance. Pass
  /// [eventInstanceId] to update an existing one — in that case [orgId] must
  /// be that event's own AO-level org (never the signed-in user's region, or
  /// the write reassigns the event to the region). Leave [eventInstanceId]
  /// null to create a brand-new unscheduled event, in which case [orgId] is
  /// the AO to create it under. [startDate] (`YYYY-MM-DD`) is required by the
  /// API in both cases. Uses the app API key (the trusted-app write model).
  /// Returns null on success, else an error string.
  Future<String?> publishBackblast({
    int? eventInstanceId,
    required String orgId,
    required String startDate,
    required String backblast,
    required int paxCount,
    required int fngCount,
    String? eventTypeId,
  }) async {
    final payload = <String, dynamic>{
      if (eventInstanceId != null) 'id': eventInstanceId,
      'orgId': int.tryParse(orgId) ?? orgId,
      'startDate': startDate,
      'backblast': backblast,
      'backblastTs': DateTime.now().millisecondsSinceEpoch,
      'paxCount': paxCount,
      'fngCount': fngCount,
      if (eventTypeId != null) 'eventTypeId': int.tryParse(eventTypeId),
      'isActive': true,
    };
    final res = await _post('/v1/event-instance', payload);
    if (res.status == 200 || res.status == 201) return null;
    return 'Event write failed (${res.status}): ${res.body}';
  }

  /// Records actual attendance for one PAX on an event instance.
  Future<String?> recordAttendance({
    required int eventInstanceId,
    required int userId,
    required int attendanceTypeId,
  }) async {
    final res = await _post('/v1/attendance/actual', {
      'eventInstanceId': eventInstanceId,
      'userId': userId,
      'attendanceTypeIds': [attendanceTypeId],
    });
    if (res.status == 200 || res.status == 201) return null;
    return 'Attendance write failed (${res.status}): ${res.body}';
  }

  // ── Schedule / signups (Tier 1) ───────────────────────────────────────────

  /// HC / sign up the signed-in PAX for an upcoming beatdown (planned
  /// attendance). Self-signup is allowed with the user's own token — no editor
  /// role needed. Returns null on success, else an error string.
  Future<String?> signUpForEvent({
    required int eventInstanceId,
    required int userId,
  }) async {
    final res = await _post(
      '/v1/attendance',
      {
        'eventInstanceId': eventInstanceId,
        'userId': userId,
        'attendanceTypeIds': [attendanceTypePax],
      },
    );
    if (res.status == 200 || res.status == 201) return null;
    return 'Sign-up failed (${res.status}): ${res.body}';
  }

  /// Remove the signed-in PAX's planned attendance (un-HC). Deletes the
  /// whole attendance record — if they're Q, this drops the Q too, matching
  /// the real F3 Nation route (`DELETE /attendance/event-instance/{id}/user/{id}`).
  /// Use [removeQ] instead to step down from Q while staying HC'd.
  Future<String?> withdrawFromEvent({
    required int eventInstanceId,
    required int userId,
  }) async {
    final res = await _delete(
      '/v1/attendance/event-instance/$eventInstanceId/user/$userId',
    );
    if (res.status == 200 || res.status == 201) return null;
    return 'Withdraw failed (${res.status}): ${res.body}';
  }

  /// Take the Q for an open event.
  Future<String?> takeQ({
    required int eventInstanceId,
    required int userId,
  }) async {
    final res = await _post(
      '/v1/attendance/take-q',
      {'eventInstanceId': eventInstanceId, 'userId': userId},
    );
    if (res.status == 200 || res.status == 201) return null;
    return 'Take-Q failed (${res.status}): ${res.body}';
  }

  /// Steps down from Q for an event, keeping the PAX's HC/attendance intact.
  Future<String?> removeQ({
    required int eventInstanceId,
    required int userId,
  }) async {
    final res = await _delete(
      '/v1/attendance/remove-q',
      payload: {'eventInstanceId': eventInstanceId, 'userId': userId},
    );
    if (res.status == 200 || res.status == 201) return null;
    return 'Remove-Q failed (${res.status}): ${res.body}';
  }

  /// Post/update the preblast (the plan announced before a beatdown). [orgId]
  /// must be the event's own AO-level org, not the signed-in user's region —
  /// sending the region org here reassigns the event to it. [startDate]
  /// (`YYYY-MM-DD`) is required by the API even on an update of an existing
  /// event.
  ///
  /// Also sends `preblastRich` — per Moneyball (2026-07-20), the API's
  /// `hasPreblast` flag (used by the slackbot's reminder nag and by other
  /// consumers) is computed server-side as `preblastRich IS NOT NULL`, not
  /// from the plain `preblast` column. Without this, a preblast posted here
  /// would display fine inside Digital Weinke but read as "no preblast" to
  /// Slack and anything else trusting that flag. Sent as a minimal valid
  /// Slack rich_text block wrapping the plain text (matching the format
  /// slackbot itself populates) — best-effort pending confirmation from
  /// Moneyball that this exact shape is what downstream consumers expect.
  Future<String?> postPreblast({
    required int eventInstanceId,
    required String orgId,
    required String startDate,
    required String preblast,
  }) async {
    final res = await _post('/v1/event-instance', {
      'id': eventInstanceId,
      'orgId': int.tryParse(orgId) ?? orgId,
      'startDate': startDate,
      'preblast': preblast,
      'preblastRich': {
        'type': 'rich_text',
        'elements': [
          {
            'type': 'rich_text_section',
            'elements': [
              {'type': 'text', 'text': preblast},
            ],
          },
        ],
      },
      'preblastTs': DateTime.now().millisecondsSinceEpoch,
      'isActive': true,
    });
    if (res.status == 200 || res.status == 201) return null;
    return 'Preblast failed (${res.status}): ${res.body}';
  }

  /// Fetches one event instance's full record, including the actual
  /// preblast text — unlike calendar-home-schedule (Schedule's main list
  /// fetch), which only sends a `hasPreblast` boolean, never the text.
  Future<F3EventInstance?> getEventInstanceById(int id) async {
    final data = await _get('/v1/event-instance/id/$id');
    if (data == null) return null;
    return F3EventInstance.fromJson(data);
  }

  // ── Health check ─────────────────────────────────────────────────────────

  Future<bool> ping() async {
    final data = await _get('/v1/ping');
    return data != null;
  }
}
