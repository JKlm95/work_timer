import 'package:flutter_test/flutter_test.dart';

import 'package:work_timer/export/work_entries_csv.dart';
import 'package:work_timer/models/work_entry.dart';
import 'package:work_timer/models/work_mode.dart';
import 'package:work_timer/models/workspace.dart';

void main() {
  test('workEntriesToCsv nagłówek i wiersze (separator przecinek)', () {
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
    final csv = workEntriesToCsv(
      entries,
      workspaceNames: {Workspace.defaultId: 'Dom'},
    );
    expect(
      csv.startsWith(
        'id,workspaceId,workspaceName,start,end,durationSeconds,mode\n',
      ),
      isTrue,
    );
    expect(csv.contains('x1'), isTrue);
    expect(csv.contains(Workspace.defaultId), isTrue);
    expect(csv.contains('Dom'), isTrue);
    expect(csv.contains('28800'), isTrue); // 8h seconds
    expect(csv.contains('office'), isTrue);
  });

  test('workEntriesToCsv UTF-8 BOM', () {
    final entries = [
      WorkEntry(
        id: 'a',
        workspaceId: Workspace.defaultId,
        start: DateTime(2026, 5, 2, 9),
        end: DateTime(2026, 5, 2, 10),
        mode: WorkMode.office,
        updatedAt: DateTime(2026, 5, 2, 10),
      ),
    ];
    final csv = workEntriesToCsv(entries, utf8Bom: true);
    expect(csv.codeUnitAt(0), 0xFEFF);
  });

  test('workEntriesToCsv separator średnik + escapowanie', () {
    final entries = [
      WorkEntry(
        id: 'a;b',
        workspaceId: Workspace.defaultId,
        start: DateTime(2026, 5, 4, 9),
        end: DateTime(2026, 5, 4, 10),
        mode: WorkMode.office,
        updatedAt: DateTime(2026, 5, 4, 10),
      ),
    ];
    final csv = workEntriesToCsv(entries, fieldDelimiter: ';');
    expect(csv.contains('"a;b"'), isTrue);
    expect(csv.split('\n').first.contains(';'), isTrue);
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
}
