// test/region_service_test.dart
// Unit tests for local-first region operations.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
}
