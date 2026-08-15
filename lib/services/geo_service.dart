// lib/services/geo_service.dart
// Thin wrapper around geolocator for the Browse AOs "nearby" sort. Never
// throws — callers get null/false back on any failure so the screen can
// fall back to an unsorted list instead of crashing.

import 'package:geolocator/geolocator.dart';

class GeoService {
  GeoService._();

  /// Requests (if needed) and returns the device's current position, or
  /// null if location services are off, permission is denied, or the
  /// request fails for any reason.
  ///
  /// Tries the OS's cached last-known position first — near-instant, and
  /// plenty accurate for a "which AOs are nearby" use case — before falling
  /// back to a fresh GPS request, which can take several real seconds
  /// (worse indoors) and was the actual cause of "this takes forever."
  static Future<Position?> getCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null &&
          DateTime.now().difference(lastKnown.timestamp).inMinutes < 15) {
        return lastKnown;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      return null;
    }
  }

  /// Shows the OS location prompt now if permission has never been decided,
  /// so it's already resolved by the time a feature (Browse AOs, F3 Near Me,
  /// At The Flag) actually needs a position — avoids a race between the user
  /// answering the OS dialog and this app's own request timing out first
  /// (that race is exactly what made At The Flag's GPS suggestion silently
  /// disappear the first time permission was ever asked). Called on every
  /// app open (see _AppEntryState._onAppResumed in main.dart); safe to call
  /// repeatedly — checkPermission()/requestPermission() only ever show OS UI
  /// once, so this is a silent no-op once the user has actually decided.
  static Future<void> primePermissionIfUndetermined() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (_) {}
  }

  /// Distance in miles between two coordinates.
  static double distanceMiles({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final meters = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    return meters / 1609.344;
  }
}
