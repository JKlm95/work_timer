import 'package:flutter_test/flutter_test.dart';
import 'package:work_timer/models/work_entry.dart';
import 'package:work_timer/models/workspace.dart';

void main() {
  test('WorkEntry.fromJson sets default workspace when missing', () {
    final entry = WorkEntry.fromJson({
      'id': 'legacy',
      'start': '2026-05-01T10:00:00.000',
      'end': '2026-05-01T11:00:00.000',
      'mode': 'office',
      'updatedAt': '2026-05-01T11:00:00.000',
      'isDeleted': false,
    });

    expect(entry.workspaceId, Workspace.defaultId);
  });
}
