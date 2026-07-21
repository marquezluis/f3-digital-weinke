// test/app_version_test.dart
// Release metadata should stay coherent with the displayed app version.

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/app_version.dart';

void main() {
  // Deliberately structural, not hardcoded to a specific version — the
  // Makefile auto-bumps pubspec.yaml's patch/build number on every release
  // build (scripts/bump_version.py), so a literal-value test here would
  // break on every single build rather than only when something's actually
  // inconsistent. AppVersion itself is NOT auto-bumped (release notes are
  // hand-written), so this only checks the pieces stay coherent with
  // *each other* whenever a human does update it.
  test('current version is represented in release notes', () {
    expect(AppVersion.current, AppVersion.versionName);
    expect(AppVersion.displayName, 'Digital Weinke v${AppVersion.versionName}');
    expect(AppVersion.fullDisplayName,
        'Digital Weinke v${AppVersion.versionName}+${AppVersion.buildNumber}');
    expect(int.tryParse(AppVersion.buildNumber), isNotNull);
    expect(AppVersion.releases.first.version, AppVersion.versionName);
  });

  test('each release has useful descriptions', () {
    for (final release in AppVersion.releases) {
      expect(release.version, isNotEmpty);
      expect(release.title, isNotEmpty);
      expect(release.summary, isNotEmpty);
      expect(
        release.newItems.length +
            release.enhancements.length +
            release.bugFixes.length,
        greaterThan(0),
      );
    }
  });
}
