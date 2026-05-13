import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:work_timer/models/entry_type.dart';
import 'package:work_timer/models/work_entry.dart';
import 'package:work_timer/models/work_mode.dart';
import 'package:work_timer/models/workspace.dart';
import 'package:work_timer/services/stats_service.dart';

void main() {
  group('WorkEntry.fromFirestore — panel web', () {
    test('ignoruje dodatkowe pola (editedAt, createdBy, createdVia)', () {
      final e = WorkEntry.fromFirestore('web1', {
        'workspaceId': 'ws1',
        'start': Timestamp.fromDate(DateTime(2026, 6, 1, 9)),
        'end': Timestamp.fromDate(DateTime(2026, 6, 1, 12)),
        'mode': 'office',
        'updatedAt': Timestamp.fromDate(DateTime(2026, 6, 1, 12)),
        'isDeleted': false,
        'createdVia': 'employer_panel',
        'createdBy': 'employerUid',
        'editedAt': Timestamp.fromDate(DateTime(2026, 6, 2)),
        'editedBy': 'someone',
      });
      expect(e.id, 'web1');
      expect(e.workspaceId, 'ws1');
      expect(e.duration.inHours, 3);
    });

    test('entryType null → work', () {
      final e = WorkEntry.fromFirestore('t1', {
        'workspaceId': 'w',
        'start': Timestamp.fromDate(DateTime(2026, 1, 1, 8)),
        'end': Timestamp.fromDate(DateTime(2026, 1, 1, 9)),
        'mode': 'remote',
        'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 1, 9)),
        'isDeleted': false,
      });
      expect(e.entryType, EntryType.work);
    });

    test('nieznany entryType string → work (fallback)', () {
      final e = WorkEntry.fromFirestore('t2', {
        'workspaceId': 'w',
        'start': Timestamp.fromDate(DateTime(2026, 1, 2, 8)),
        'end': Timestamp.fromDate(DateTime(2026, 1, 2, 9)),
        'mode': 'remote',
        'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 2, 9)),
        'isDeleted': false,
        'entryType': 'unknown_panel_value',
      });
      expect(e.entryType, EntryType.work);
    });

    test('entryType case-insensitive', () {
      final e = WorkEntry.fromFirestore('t3', {
        'workspaceId': 'w',
        'start': Timestamp.fromDate(DateTime(2026, 1, 3, 8)),
        'end': Timestamp.fromDate(DateTime(2026, 1, 3, 9)),
        'mode': 'remote',
        'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 3, 9)),
        'isDeleted': false,
        'entryType': 'VACATION',
      });
      expect(e.entryType, EntryType.vacation);
    });

    test('billingRatePercent null → 100', () {
      final e = WorkEntry.fromFirestore('b1', {
        'workspaceId': 'w',
        'start': Timestamp.fromDate(DateTime(2026, 2, 1, 8)),
        'end': Timestamp.fromDate(DateTime(2026, 2, 1, 10)),
        'mode': 'office',
        'updatedAt': Timestamp.fromDate(DateTime(2026, 2, 1, 10)),
        'isDeleted': false,
        'billingRatePercent': null,
      });
      expect(e.billingRatePercent, 100);
    });

    test('billingRatePercent 80', () {
      final e = WorkEntry.fromFirestore('b2', {
        'workspaceId': 'w',
        'start': Timestamp.fromDate(DateTime(2026, 2, 2, 8)),
        'end': Timestamp.fromDate(DateTime(2026, 2, 2, 10)),
        'mode': 'office',
        'updatedAt': Timestamp.fromDate(DateTime(2026, 2, 2, 10)),
        'isDeleted': false,
        'billingRatePercent': 80,
      });
      expect(e.billingRatePercent, 80);
    });

    test('nieznany billingRatePercent → 100', () {
      final e = WorkEntry.fromFirestore('b3', {
        'workspaceId': 'w',
        'start': Timestamp.fromDate(DateTime(2026, 2, 3, 8)),
        'end': Timestamp.fromDate(DateTime(2026, 2, 3, 10)),
        'mode': 'office',
        'updatedAt': Timestamp.fromDate(DateTime(2026, 2, 3, 10)),
        'isDeleted': false,
        'billingRatePercent': 77,
      });
      expect(e.billingRatePercent, 100);
    });

    test('start >= end — duration zero, nie liczy w agregatach', () {
      final e = WorkEntry.fromFirestore('bad', {
        'workspaceId': 'w',
        'start': Timestamp.fromDate(DateTime(2026, 3, 1, 10)),
        'end': Timestamp.fromDate(DateTime(2026, 3, 1, 9)),
        'mode': 'office',
        'updatedAt': Timestamp.fromDate(DateTime(2026, 3, 1, 10)),
        'isDeleted': false,
      });
      expect(e.duration, Duration.zero);
      expect(e.countsInTimeAggregates, isFalse);
    });
  });

  group('StatsService + soft delete', () {
    final from = DateTime(2026, 5, 1);
    final to = DateTime(2026, 5, 31);
    final svc = StatsService();

    test('buildSummary pomija isDeleted', () {
      final entries = [
        WorkEntry(
          id: 'live',
          workspaceId: 'a',
          start: DateTime(2026, 5, 2, 8),
          end: DateTime(2026, 5, 2, 10),
          mode: WorkMode.office,
          updatedAt: DateTime(2026, 5, 2, 10),
        ),
        WorkEntry(
          id: 'dead',
          workspaceId: 'a',
          start: DateTime(2026, 5, 3, 8),
          end: DateTime(2026, 5, 3, 12),
          mode: WorkMode.office,
          updatedAt: DateTime(2026, 5, 3, 12),
          isDeleted: true,
        ),
      ];
      final s = svc.buildSummary(
        entries: entries,
        from: from,
        to: to,
        workspaceIds: const {},
      );
      expect(s.total.inHours, 2);
    });

    test('buildSummary pomija start >= end', () {
      final entries = [
        WorkEntry(
          id: 'ok',
          workspaceId: 'a',
          start: DateTime(2026, 5, 4, 8),
          end: DateTime(2026, 5, 4, 10),
          mode: WorkMode.office,
          updatedAt: DateTime(2026, 5, 4, 10),
        ),
        WorkEntry(
          id: 'bad',
          workspaceId: 'a',
          start: DateTime(2026, 5, 5, 12),
          end: DateTime(2026, 5, 5, 8),
          mode: WorkMode.office,
          updatedAt: DateTime(2026, 5, 5, 12),
        ),
      ];
      final s = svc.buildSummary(
        entries: entries,
        from: from,
        to: to,
        workspaceIds: const {},
      );
      expect(s.total.inHours, 2);
    });

    test('buildBillingEstimate nie crashuje przy start >= end', () {
      final workspaces = {
        'a': Workspace(
          id: 'a',
          name: 'P',
          createdAt: from,
          updatedAt: from,
          hourlyRate: 100,
          currencyCode: 'PLN',
        ),
      };
      final entries = [
        WorkEntry(
          id: 'bad',
          workspaceId: 'a',
          start: DateTime(2026, 5, 6, 12),
          end: DateTime(2026, 5, 6, 8),
          mode: WorkMode.office,
          updatedAt: DateTime(2026, 5, 6, 12),
          isBillable: true,
          entryType: EntryType.work,
        ),
      ];
      final est = svc.buildBillingEstimate(
        entries: entries,
        from: from,
        to: DateTime(2026, 5, 31, 23, 59, 59, 999),
        workspaceIds: const {},
        workspaces: workspaces,
      );
      expect(est.earningsByCurrency.isEmpty, isTrue);
    });
  });
}
