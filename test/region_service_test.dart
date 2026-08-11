// test/region_service_test.dart
// Unit tests for local-first region operations.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:f3_nation_app/models/region_models.dart';
import 'package:f3_nation_app/models/workout_history.dart';
import 'package:f3_nation_app/services/region_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('records AO, PAX, and attendance from saved history', () async {
    final service = RegionService();
    await service.load();

    final history = WorkoutHistory(
      id: 'session-1',
      title: 'Saturday Beatdown',
      date: DateTime(2026, 5, 2),
      ao: 'The Flag',
      q: 'Digital',
      pax: const ['Alpha', 'Bravo'],
      fngCount: 1,
    );

    await service.recordAttendanceFromHistory(history, fngNotes: 'Text FNG');

    expect(service.aos.single.name, 'The Flag');
    expect(service.pax.map((p) => p.name), containsAll(['Alpha', 'Bravo']));
    expect(service.attendance.single.totalCount, 3);
    expect(service.fngCount, 1);
  });

  test('tracks hard commits', () async {
    final service = RegionService();
    await service.load();
    await service.upsertAo(name: 'The Hill');

    await service.addHardCommit(
      aoId: service.aos.single.id,
      date: DateTime(2026, 5, 9),
      paxNames: const ['Alpha', 'Alpha', 'Charlie'],
      q: 'Digital',
    );

    expect(service.hardCommits.single.paxNames, ['Alpha', 'Charlie']);
    expect(service.totalHcCount, 2);
  });

  group('EH prospect tracking', () {
    test('add, follow up, and promote to a real PAX', () async {
      final service = RegionService();
      await service.load();

      await service.addEhProspect(
          name: 'Newman', contactInfo: '555-1234', notes: 'Met at the gym');
      expect(service.ehProspects.single.name, 'Newman');
      expect(service.ehProspects.single.lastFollowUp, isNull);

      final id = service.ehProspects.single.id;
      await service.markProspectFollowedUp(id);
      expect(service.ehProspects.single.lastFollowUp, isNotNull);

      await service.promoteProspectToPax(id);
      expect(service.ehProspects, isEmpty);
      expect(service.pax.single.name, 'Newman');
      expect(service.pax.single.phoneOrSlack, '555-1234');
      expect(service.pax.single.firstPost, isNotNull);
    });

    test('remove drops a prospect without touching PAX', () async {
      final service = RegionService();
      await service.load();
      await service.addEhProspect(name: 'Kramer');
      final id = service.ehProspects.single.id;

      await service.removeEhProspect(id);

      expect(service.ehProspects, isEmpty);
      expect(service.pax, isEmpty);
    });

    group('prospectsNeedingFollowUp', () {
      test('a freshly-added prospect does not need follow-up yet', () async {
        final service = RegionService();
        await service.load();
        await service.addEhProspect(name: 'Newman');

        expect(service.prospectsNeedingFollowUp, isEmpty);
      });

      test('a prospect added more than 7 days ago with no follow-up logged needs one',
          () async {
        final service = RegionService();
        await service.load();
        await service.replaceSnapshot(RegionSnapshot(ehProspects: [
          EhProspect(
            id: '1',
            name: 'Newman',
            dateAdded: DateTime.now().subtract(const Duration(days: 10)),
          ),
        ]));

        expect(service.prospectsNeedingFollowUp, hasLength(1));
        expect(service.prospectsNeedingFollowUp.single.name, 'Newman');
      });

      test('a recent follow-up clears the need even if the prospect is old', () async {
        final service = RegionService();
        await service.load();
        await service.replaceSnapshot(RegionSnapshot(ehProspects: [
          EhProspect(
            id: '1',
            name: 'Newman',
            dateAdded: DateTime.now().subtract(const Duration(days: 30)),
            lastFollowUp: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ]));

        expect(service.prospectsNeedingFollowUp, isEmpty);
      });

      test('a stale follow-up (more than 7 days ago) needs another one', () async {
        final service = RegionService();
        await service.load();
        await service.replaceSnapshot(RegionSnapshot(ehProspects: [
          EhProspect(
            id: '1',
            name: 'Newman',
            dateAdded: DateTime.now().subtract(const Duration(days: 30)),
            lastFollowUp: DateTime.now().subtract(const Duration(days: 8)),
          ),
        ]));

        expect(service.prospectsNeedingFollowUp, hasLength(1));
      });
    });
  });
}
