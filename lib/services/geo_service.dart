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

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      return null;
    }
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
