import '../models/work_entry.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Poniedziałek bieżącego tygodnia (lokalny), godz. 00:00.
DateTime weekStartMonday(DateTime now) {
  final d0 = dateOnly(now);
  return d0.subtract(Duration(days: d0.weekday - DateTime.monday));
}

List<WorkEntry> entriesStartingOnDay(List<WorkEntry> entries, DateTime day) {
  final d0 = dateOnly(day);
  final d1 = d0.add(const Duration(days: 1));
  return entries
      .where((e) => e.countsInTimeAggregates)
      .where((e) => !e.start.isBefore(d0) && e.start.isBefore(d1))
      .toList();
}

List<WorkEntry> entriesInCurrentWeek(List<WorkEntry> entries, DateTime now) {
  final from = weekStartMonday(now);
  final lastInstant = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  return entries
      .where((e) => e.countsInTimeAggregates)
      .where((e) => !e.start.isBefore(from) && !e.start.isAfter(lastInstant))
      .toList();
}

/// Suma czasu na dni pon–nd w bieżącym tygodniu (wg dnia [WorkEntry.start]).
List<Duration> weekDayDurations(List<WorkEntry> entries, DateTime now) {
  final monday = weekStartMonday(now);
  final buckets = List<Duration>.generate(7, (_) => Duration.zero);
  for (final e in entries) {
    if (!e.countsInTimeAggregates) continue;
    if (e.start.isBefore(monday)) continue;
    final nextMonday = monday.add(const Duration(days: 7));
    if (!e.start.isBefore(nextMonday)) continue;
    var idx = e.start.weekday - DateTime.monday;
    if (idx < 0 || idx > 6) continue;
    buckets[idx] += e.duration;
  }
  return buckets;
}
