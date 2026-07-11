// test/qsource_data_test.dart
// Unit tests for the QSource / Q Field Guide data model.
// Pure Dart — no Flutter, no assets, no network.
// Run with: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:f3_nation_app/models/qsource_data.dart';

void main() {
  // ── QSourceData static content ────────────────────────────────────────────
  group('QSourceData.allSections', () {
    test('contains exactly 12 sections', () {
      expect(QSourceData.allSections.length, 12);
    });

    test('every section has a non-empty title', () {
      for (final section in QSourceData.allSections) {
        expect(section.title.trim().isNotEmpty, isTrue,
            reason: 'Section title must not be blank');
      }
    });

    test('every section has at least one entry', () {
      for (final section in QSourceData.allSections) {
        expect(section.entries.isNotEmpty, isTrue,
            reason: '${section.title} has no entries');
      }
    });

    test('every entry has a non-empty label', () {
      for (final section in QSourceData.allSections) {
        for (final entry in section.entries) {
          expect(entry.label.trim().isNotEmpty, isTrue,
              reason: 'Empty label in section ${section.title}');
        }
      }
    });
  });

  // ── Named sections exist ──────────────────────────────────────────────────
  group('Named sections', () {
    test('workoutPrinciples has 5 entries (one per F3 principle)', () {
      expect(QSourceData.workoutPrinciples.entries.length, 5);
    });

    test('workoutPrinciples all entries are check style', () {
      for (final e in QSourceData.workoutPrinciples.entries) {
        expect(e.style, QEntryStyle.check,
            reason: 'Workout principles should be checkable items');
      }
    });

    test('disclaimer has 5 entries', () {
      expect(QSourceData.disclaimer.entries.length, 5);
    });

    test('workoutStructure has 5 phases (numbered)', () {
      expect(QSourceData.workoutStructure.entries.length, 5);
      for (final e in QSourceData.workoutStructure.entries) {
        expect(e.style, QEntryStyle.numbered);
      }
    });

    test('qPrepReminders has 9 entries, all check style', () {
      expect(QSourceData.qPrepReminders.entries.length, 9);
      for (final e in QSourceData.qPrepReminders.entries) {
        expect(e.style, QEntryStyle.check);
      }
    });

    test('cadenceAssistant has 7 entries', () {
      expect(QSourceData.cadenceAssistant.entries.length, 7);
    });

    test('cadenceAssistant last entry is a note (form guidance)', () {
      expect(QSourceData.cadenceAssistant.entries.last.style, QEntryStyle.note);
    });

    test('cotChecklist has 5 entries', () {
      expect(QSourceData.cotChecklist.entries.length, 5);
    });

    test('backblastTemplate has 9 entries', () {
      expect(QSourceData.backblastTemplate.entries.length, 9);
    });

    test('qsourceBestPractices has 9 entries', () {
      expect(QSourceData.qsourceBestPractices.entries.length, 9);
    });

    test('qsourceAgenda has 9 entries (numbered steps)', () {
      expect(QSourceData.qsourceAgenda.entries.length, 9);
      for (final e in QSourceData.qsourceAgenda.entries) {
        expect(e.style, QEntryStyle.numbered);
      }
    });

    test('qsourceFollowUp has 5 entries, all check style', () {
      expect(QSourceData.qsourceFollowUp.entries.length, 5);
      for (final e in QSourceData.qsourceFollowUp.entries) {
        expect(e.style, QEntryStyle.check);
      }
    });

    test('qsourceFormats has 4 execution types', () {
      expect(QSourceData.qsourceFormats.entries.length, 4);
    });
  });

  // ── QGuideSection / QGuideEntry construction ──────────────────────────────
  group('QGuideSection construction', () {
    test('can construct a section without subtitle', () {
      const section = QGuideSection(
        title: 'TEST SECTION',
        entries: [
          QGuideEntry(label: 'An entry', style: QEntryStyle.bullet),
        ],
      );
      expect(section.subtitle, isNull);
      expect(section.entries.length, 1);
    });

    test('QGuideEntry defaults to bullet style', () {
      const entry = QGuideEntry(label: 'Test');
      expect(entry.style, QEntryStyle.bullet);
    });

    test('QGuideEntry with detail stores it correctly', () {
      const entry = QGuideEntry(
        label: 'Title',
        detail: 'Supporting description.',
        style: QEntryStyle.check,
      );
      expect(entry.detail, 'Supporting description.');
      expect(entry.style, QEntryStyle.check);
    });
  });

  // ── QEntryStyle enum completeness ─────────────────────────────────────────
  group('QEntryStyle', () {
    test('all five styles are defined', () {
      const expected = {
        QEntryStyle.bullet,
        QEntryStyle.check,
        QEntryStyle.numbered,
        QEntryStyle.heading,
        QEntryStyle.note,
      };
      expect(QEntryStyle.values.toSet(), expected);
    });
  });
}
