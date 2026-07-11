// lib/services/music_launcher.dart
// Launches the user's preferred music provider via deep link when a workout starts.
// Uses url_launcher — no SDK required, no OAuth, works offline once the app is open.
//
// Provider deep links:
//   Spotify       spotify:playlist:<id>   → falls back to https://open.spotify.com/playlist/<id>
//   Apple Music   https://music.apple.com/... (opens in Music app on iOS)
//   YouTube Music https://music.youtube.com/... (opens in YT Music app or browser)
//   Amazon Music  music://                → falls back to Amazon Music web
//   Custom        whatever URL the user pastes

import 'package:url_launcher/url_launcher.dart';

enum MusicProvider {
  spotify,
  appleMusic,
  youtubeMusic,
  amazonMusic,
  custom;

  String get displayName {
    switch (this) {
      case spotify:      return 'Spotify';
      case appleMusic:   return 'Apple Music';
      case youtubeMusic: return 'YouTube Music';
      case amazonMusic:  return 'Amazon Music';
      case custom:       return 'Custom URL';
    }
  }

  String get icon {
    switch (this) {
      case spotify:      return '🎵';
      case appleMusic:   return '🎵';
      case youtubeMusic: return '▶️';
      case amazonMusic:  return '🎵';
      case custom:       return '🔗';
    }
  }

  // Returns a launchable URI for the given playlist URL.
  // [playlistUrl] is whatever the user pasted (Spotify share link, Apple Music link, etc.)
  Uri? buildUri(String playlistUrl) {
    final trimmed = playlistUrl.trim();
    if (trimmed.isEmpty) {
      // No playlist — just open the app.
      switch (this) {
        case spotify:      return Uri.parse('spotify:');
        case appleMusic:   return Uri.parse('music://');
        case youtubeMusic: return Uri.parse('https://music.youtube.com');
        case amazonMusic:  return Uri.parse('amznmp3://');
        case custom:       return null;
      }
    }

    switch (this) {
      case spotify:
        // Convert web share URL to native URI: spotify:playlist:<id>
        final match = RegExp(r'playlist/([A-Za-z0-9]+)').firstMatch(trimmed);
        if (match != null) return Uri.parse('spotify:playlist:${match.group(1)}');
        if (trimmed.startsWith('spotify:')) return Uri.parse(trimmed);
        return Uri.parse(trimmed); // already a web URL
      case appleMusic:
      case youtubeMusic:
      case amazonMusic:
      case custom:
        return Uri.tryParse(trimmed);
    }
  }

  // Fallback web URL when the native URI fails (app not installed).
  Uri? fallbackUri(String playlistUrl) {
    final trimmed = playlistUrl.trim();
    switch (this) {
      case spotify:
        final match = RegExp(r'playlist/([A-Za-z0-9]+)').firstMatch(trimmed);
        if (match != null) {
          return Uri.parse(
              'https://open.spotify.com/playlist/${match.group(1)}');
        }
        return Uri.tryParse(trimmed);
      case amazonMusic:
        return Uri.parse('https://music.amazon.com');
      default:
        return Uri.tryParse(trimmed);
    }
  }
}

class MusicLauncher {
  static Future<bool> launch(
      MusicProvider provider, String playlistUrl) async {
    final uri = provider.buildUri(playlistUrl);
    if (uri == null) return false;

    // Try native deep link first.
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    // Fall back to web URL.
    final fallback = provider.fallbackUri(playlistUrl);
    if (fallback != null && await canLaunchUrl(fallback)) {
      return launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
