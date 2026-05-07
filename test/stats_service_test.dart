import 'package:flutter_test/flutter_test.dart';
import 'package:work_timer/models/work_entry.dart';
import 'package:work_timer/models/work_mode.dart';
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
}
