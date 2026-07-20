// test/app_version_test.dart
// Release metadata should stay coherent with the displayed app version.

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/app_version.dart';

void main() {
  test('current version is represented in release notes', () {
    expect(AppVersion.versionName, '2.4.0');
    expect(AppVersion.buildNumber, '12');
    expect(AppVersion.displayName, 'Digital Weinke v2.4.0');
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
