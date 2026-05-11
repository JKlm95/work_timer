import 'package:flutter_test/flutter_test.dart';
import 'package:work_timer/models/work_entry.dart';
import 'package:work_timer/models/work_mode.dart';
import 'package:work_timer/models/workspace.dart';
import 'package:work_timer/models/entry_type.dart';
import 'package:work_timer/services/stats_service.dart';

void main() {
  test('StatsService sums and groups entries', () {
    final service = StatsService();
    final from = DateTime(2026, 5, 1);
    final to = DateTime(2026, 5, 31);
    final entries = [
      WorkEntry(
        id: '1',
        workspaceId: 'a',
        start: DateTime(2026, 5, 2, 8),
        end: DateTime(2026, 5, 2, 10),
        mode: WorkMode.office,
        updatedAt: DateTime(2026, 5, 2, 10),
      ),
      WorkEntry(
        id: '2',
        workspaceId: 'b',
        start: DateTime(2026, 5, 3, 8),
        end: DateTime(2026, 5, 3, 11),
        mode: WorkMode.remote,
        updatedAt: DateTime(2026, 5, 3, 11),
      ),
    ];

    final summary = service.buildSummary(
      entries: entries,
      from: from,
      to: to,
      workspaceIds: const {},
    );

    expect(summary.total.inHours, 5);
    expect(summary.activeDays, 2);
    expect(summary.workspaceShare.length, 2);
  });

  test('StatsService filtruje po workspaceIds', () {
    final service = StatsService();
    final from = DateTime(2026, 5, 1);
    final to = DateTime(2026, 5, 31);
    final entries = [
      WorkEntry(
        id: '1',
        workspaceId: 'only-a',
        start: DateTime(2026, 5, 2, 8),
        end: DateTime(2026, 5, 2, 10),
        mode: WorkMode.office,
        updatedAt: DateTime(2026, 5, 2, 10),
      ),
      WorkEntry(
        id: '2',
        workspaceId: 'b',
        start: DateTime(2026, 5, 3, 8),
        end: DateTime(2026, 5, 3, 12),
        mode: WorkMode.remote,
        updatedAt: DateTime(2026, 5, 3, 12),
      ),
    ];

    final summary = service.buildSummary(
      entries: entries,
      from: from,
      to: to,
      workspaceIds: {'only-a'},
    );

    expect(summary.total.inHours, 2);
    expect(summary.workspaceShare.length, 1);
    expect(summary.workspaceShare.single.workspaceId, 'only-a');
  });

  test('StatsService pusty zakres wpisów → zero', () {
    final service = StatsService();
    final from = DateTime(2026, 6, 1);
    final to = DateTime(2026, 6, 30);
    final summary = service.buildSummary(
      entries: const [],
      from: from,
      to: to,
      workspaceIds: const {},
    );
    expect(summary.total, Duration.zero);
    expect(summary.activeDays, 0);
    expect(summary.averagePerActiveDay, Duration.zero);
  });

  test('buildBillingEstimate rozdziela rozliczalne i PLN', () {
    final service = StatsService();
    final from = DateTime(2026, 5, 1);
    final to = DateTime(2026, 5, 31, 23, 59, 59, 999);
    final workspaces = {
      'a': Workspace(
        id: 'a',
        name: 'Klient',
        createdAt: from,
        updatedAt: from,
        hourlyRate: 50,
        currencyCode: 'PLN',
      ),
    };
    final entries = [
      WorkEntry(
        id: '1',
        workspaceId: 'a',
        start: DateTime(2026, 5, 2, 8),
        end: DateTime(2026, 5, 2, 10),
        mode: WorkMode.office,
        updatedAt: DateTime(2026, 5, 2, 10),
        isBillable: true,
        entryType: EntryType.work,
      ),
      WorkEntry(
        id: '2',
        workspaceId: 'a',
        start: DateTime(2026, 5, 3, 8),
        end: DateTime(2026, 5, 3, 10),
        mode: WorkMode.office,
        updatedAt: DateTime(2026, 5, 3, 10),
        isBillable: false,
        entryType: EntryType.work,
      ),
    ];

    final bill = service.buildBillingEstimate(
      entries: entries,
      from: from,
      to: to,
      workspaceIds: const {},
      workspaces: workspaces,
    );

    expect(bill.billableWorked.inHours, 2);
    expect(bill.nonBillableWorked.inHours, 2);
    expect(bill.earningsByCurrency['PLN'], closeTo(100, 0.001));
  });
}
