import '../models/work_entry.dart';
import '../models/work_mode.dart';

/// CSV pod Excel: opcjonalny **UTF-8 BOM**, separator `,` lub `;` (PL).
///
/// Pomija [WorkEntry.isDeleted].
String workEntriesToCsv(
  List<WorkEntry> entries, {
  Map<String, String> workspaceNames = const {},
  String fieldDelimiter = ',',
  bool utf8Bom = false,
}) {
  final sep = fieldDelimiter;
  final b = StringBuffer();
  if (utf8Bom) {
    b.write('\uFEFF');
  }
  const headers = [
    'id',
    'workspaceId',
    'workspaceName',
    'start',
    'end',
    'durationSeconds',
    'mode',
    'entryType',
    'isBillable',
    'billingRatePercent',
    'taskTitle',
    'note',
  ];
  b.writeln(headers.join(sep));
  for (final e in entries) {
    if (e.isDeleted) continue;
    final name = workspaceNames[e.workspaceId] ?? '';
    final row = [
      _csvCell(e.id, sep),
      _csvCell(e.workspaceId, sep),
      _csvCell(name, sep),
      _csvCell(e.start.toIso8601String(), sep),
      _csvCell(e.end.toIso8601String(), sep),
      _csvCell('${e.duration.inSeconds}', sep),
      _csvCell(e.mode.storageValue, sep),
      _csvCell(e.entryType.name, sep),
      _csvCell('${e.isBillable}', sep),
      _csvCell('${e.billingRatePercent}', sep),
      _csvCell(e.taskTitle ?? '', sep),
      _csvCell(e.note ?? '', sep),
    ];
    b.writeln(row.join(sep));
  }
  return b.toString();
}

String _csvCell(String value, String delimiter) {
  if (value.contains('"') ||
      value.contains(delimiter) ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
