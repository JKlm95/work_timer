import 'package:flutter_test/flutter_test.dart';

import 'package:work_timer/export/work_entries_csv.dart';
import 'package:work_timer/models/work_entry.dart';
import 'package:work_timer/models/work_mode.dart';
import 'package:work_timer/models/workspace.dart';

void main() {
  test('workEntriesToCsv nagłówek i wiersze', () {
    final entries = [
      WorkEntry(
        id: 'x1',
        workspaceId: Workspace.defaultId,
        start: DateTime(2026, 5, 1, 9),
        end: DateTime(2026, 5, 1, 17),
        mode: WorkMode.office,
        updatedAt: DateTime(2026, 5, 1, 17),
      ),
    ];
    final csv = workEntriesToCsv(entries);
    expect(csv.startsWith('id,workspaceId,start,end,mode\n'), isTrue);
    expect(csv.contains('x1'), isTrue);
    expect(csv.contains(Workspace.defaultId), isTrue);
    expect(csv.contains('office'), isTrue);
  });

  test('workEntriesToCsv pomija isDeleted', () {
    final entries = [
      WorkEntry(
        id: 'gone',
        workspaceId: Workspace.defaultId,
        start: DateTime(2026, 5, 2, 9),
        end: DateTime(2026, 5, 2, 10),
        mode: WorkMode.office,
        updatedAt: DateTime(2026, 5, 2, 10),
        isDeleted: true,
      ),
      WorkEntry(
        id: 'keep',
        workspaceId: Workspace.defaultId,
        start: DateTime(2026, 5, 3, 9),
        end: DateTime(2026, 5, 3, 10),
        mode: WorkMode.remote,
        updatedAt: DateTime(2026, 5, 3, 10),
      ),
    ];
    final csv = workEntriesToCsv(entries);
    expect(csv.contains('gone'), isFalse);
    expect(csv.contains('keep'), isTrue);
  });

  test('workEntriesToCsv escapuje przecinek w polu', () {
    final entries = [
      WorkEntry(
        id: 'id,with,comma',
        workspaceId: Workspace.defaultId,
        start: DateTime(2026, 5, 4, 9),
        end: DateTime(2026, 5, 4, 10),
        mode: WorkMode.office,
        updatedAt: DateTime(2026, 5, 4, 10),
      ),
    ];
    final csv = workEntriesToCsv(entries);
    expect(csv.contains('"id,with,comma"'), isTrue);
  });
}
