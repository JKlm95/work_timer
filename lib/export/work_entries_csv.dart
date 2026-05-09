import '../models/work_entry.dart';
import '../models/work_mode.dart';

/// Eksport wpisów do CSV (UTF-8, nagłówek w pierwszej linii). Pomija wpisy [WorkEntry.isDeleted].
String workEntriesToCsv(List<WorkEntry> entries) {
  final b = StringBuffer();
  b.writeln('id,workspaceId,start,end,mode');
  for (final e in entries) {
    if (e.isDeleted) continue;
    b.writeln(
      [
        _csvCell(e.id),
        _csvCell(e.workspaceId),
        _csvCell(e.start.toIso8601String()),
        _csvCell(e.end.toIso8601String()),
        _csvCell(e.mode.storageValue),
      ].join(','),
    );
  }
  return b.toString();
}

String _csvCell(String value) {
  if (value.contains('"') ||
      value.contains(',') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
