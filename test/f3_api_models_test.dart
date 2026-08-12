// test/f3_api_models_test.dart
// Unit tests for F3EventInstance.fromJson's hasPreblast derivation and
// copyWith — the crux of the "Edit Preblast button never showed the posted
// text" bug: calendar-home-schedule sends `hasPreblast` but never the
// preblast text; byId sends the text (and preblastTs) but no `hasPreblast`
// key. Run with: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/f3_api_models.dart';

void main() {
  group('F3EventInstance.fromJson hasPreblast', () {
    test('true from calendar-home-schedule shape (hasPreblast, no text)', () {
      final e = F3EventInstance.fromJson({'id': '1', 'hasPreblast': true});
      expect(e.hasPreblast, isTrue);
      expect(e.preblast, isNull);
    });

    test('false from calendar-home-schedule shape when not posted', () {
      final e = F3EventInstance.fromJson({'id': '1', 'hasPreblast': false});
      expect(e.hasPreblast, isFalse);
    });

    test('true from byId shape (preblastTs set, no hasPreblast key)', () {
      final e = F3EventInstance.fromJson({
        'id': '1',
        'preblast': 'THE PLAN: burpees',
        'preblastTs': 1753142400000,
      });
      expect(e.hasPreblast, isTrue);
      expect(e.preblast, 'THE PLAN: burpees');
    });

    test('false when neither signal nor text is present', () {
      final e = F3EventInstance.fromJson({'id': '1'});
      expect(e.hasPreblast, isFalse);
    });

    test('true when text is present even without an explicit flag', () {
      final e = F3EventInstance.fromJson({'id': '1', 'preblast': 'some plan'});
      expect(e.hasPreblast, isTrue);
    });
  });

  group('F3EventInstance.copyWith', () {
    test('folds a freshly-fetched preblast into a calendar-sourced event', () {
      final fromCalendar = F3EventInstance.fromJson({
        'id': '1',
        'orgName': 'The Ruckus',
        'hasPreblast': true,
      });
      expect(fromCalendar.preblast, isNull);

      final merged = fromCalendar.copyWith(
        preblast: 'THE PLAN: burpees',
        hasPreblast: true,
      );

      expect(merged.preblast, 'THE PLAN: burpees');
      expect(merged.hasPreblast, isTrue);
      expect(merged.orgName, 'The Ruckus'); // untouched fields preserved
      expect(merged.id, fromCalendar.id);
    });

    test('leaves fields unchanged when no overrides are given', () {
      final e = F3EventInstance.fromJson({'id': '1', 'preblast': 'plan'});
      final copy = e.copyWith();
      expect(copy.preblast, e.preblast);
      expect(copy.hasPreblast, e.hasPreblast);
    });

    test('reflects a just-taken Q — qF3Name/userIsQ are otherwise a stale '
        'snapshot from whenever the event was last fetched', () {
      final e = F3EventInstance.fromJson({'id': '1'});
      expect(e.hasQ, isFalse);
      expect(e.userIsQ, isFalse);

      final afterTakeQ = e.copyWith(userIsQ: true, qF3Name: 'PermVac');
      expect(afterTakeQ.hasQ, isTrue);
      expect(afterTakeQ.userIsQ, isTrue);
      expect(afterTakeQ.qF3Name, 'PermVac');
    });

    test('reflects a Drop Q — qF3Name clears so hasQ goes back to false', () {
      final e = F3EventInstance.fromJson({'id': '1', 'plannedQs': 'PermVac'});
      expect(e.hasQ, isTrue);

      final afterDropQ = e.copyWith(userIsQ: false, qF3Name: '');
      expect(afterDropQ.hasQ, isFalse);
      expect(afterDropQ.userIsQ, isFalse);
    });
  });

  group('F3EventInstance.fromJson slackChannels (F3-Nation/f3-nation#693)',
      () {
    test('parses resolved preblast and backblast channels', () {
      final e = F3EventInstance.fromJson({
        'id': '1',
        'slackChannels': {
          'preblast': {'channelId': 'C_REGION_PRE', 'source': 'region_settings'},
          'backblast': {'channelId': 'C_REGION_BACK', 'source': 'region_settings'},
        },
      });
      expect(e.preblastSlackChannelId, 'C_REGION_PRE');
      expect(e.preblastSlackChannelSource, 'region_settings');
      expect(e.backblastSlackChannelId, 'C_REGION_BACK');
      expect(e.backblastSlackChannelSource, 'region_settings');
    });

    test('null when slackChannels is absent (includeSlackChannelId not requested)',
        () {
      final e = F3EventInstance.fromJson({'id': '1'});
      expect(e.preblastSlackChannelId, isNull);
      expect(e.backblastSlackChannelId, isNull);
    });
  });

  group('F3Location.fromJson', () {
    test('parses the GET /v1/location list shape (locationName, regionId)', () {
      final loc = F3Location.fromJson({
        'id': 42,
        'locationName': 'The Bunker',
        'regionId': 7,
        'latitude': 35.1,
        'longitude': -80.8,
        'addressStreet': '123 Main St',
        'addressCity': 'Charlotte',
        'addressState': 'NC',
      });
      expect(loc.id, '42');
      expect(loc.name, 'The Bunker');
      expect(loc.orgId, '7');
      expect(loc.lat, 35.1);
      expect(loc.lon, -80.8);
      expect(loc.street, '123 Main St');
      expect(loc.city, 'Charlotte');
      expect(loc.state, 'NC');
    });

    test('parses the admin write-form fields (isActive, address2/zip/country, email)',
        () {
      final loc = F3Location.fromJson({
        'id': 42,
        'locationName': 'The Bunker',
        'regionId': 7,
        'isActive': false,
        'addressStreet2': 'Suite 5',
        'addressZip': '28202',
        'addressCountry': 'US',
        'email': 'q@example.com',
      });
      expect(loc.isActive, isFalse);
      expect(loc.addressStreet2, 'Suite 5');
      expect(loc.addressZip, '28202');
      expect(loc.addressCountry, 'US');
      expect(loc.email, 'q@example.com');
    });

    test('isActive defaults to true when absent', () {
      final loc = F3Location.fromJson({'id': '1', 'name': 'Test AO'});
      expect(loc.isActive, isTrue);
    });

    test('withSchedule preserves the admin write-form fields', () {
      const loc = F3Location(
        id: '1',
        name: 'The Bunker',
        orgId: '7',
        isActive: false,
        addressStreet2: 'Suite 5',
        addressZip: '28202',
        addressCountry: 'US',
        email: 'q@example.com',
      );
      final withSchedule = loc.withSchedule(const []);
      expect(withSchedule.isActive, isFalse);
      expect(withSchedule.addressStreet2, 'Suite 5');
      expect(withSchedule.addressZip, '28202');
      expect(withSchedule.addressCountry, 'US');
      expect(withSchedule.email, 'q@example.com');
    });
  });
}
