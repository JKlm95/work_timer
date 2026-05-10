import '../models/work_entry.dart';

class StatsPoint {
  const StatsPoint({required this.label, required this.duration});

  final String label;
  final Duration duration;
}

class WorkspaceShare {
  const WorkspaceShare({required this.workspaceId, required this.duration});

  final String workspaceId;
  final Duration duration;
}

class StatsSummary {
  const StatsSummary({
    required this.total,
    required this.activeDays,
    required this.averagePerActiveDay,
    required this.daily,
    required this.workspaceShare,
  });

  final Duration total;
  final int activeDays;
  final Duration averagePerActiveDay;
  final List<StatsPoint> daily;
  final List<WorkspaceShare> workspaceShare;
}

class StatsService {
  StatsSummary buildSummary({
    required List<WorkEntry> entries,
    required DateTime from,
    required DateTime to,
    required Set<String> workspaceIds,
  }) {
    final filtered = entries.where((e) {
      final inWorkspace =
          workspaceIds.isEmpty || workspaceIds.contains(e.workspaceId);
      return inWorkspace &&
          !e.start.isBefore(DateTime(from.year, from.month, from.day)) &&
          !e.start.isAfter(
            DateTime(to.year, to.month, to.day, 23, 59, 59, 999),
          );
    }).toList();

    final total = filtered.fold<Duration>(
      Duration.zero,
      (sum, e) => sum + e.duration,
    );

    final byDay = <String, Duration>{};
    final byWorkspace = <String, Duration>{};
    for (final entry in filtered) {
      final day = '${entry.start.year}-${entry.start.month}-${entry.start.day}';
      byDay[day] = (byDay[day] ?? Duration.zero) + entry.duration;
      byWorkspace[entry.workspaceId] =
          (byWorkspace[entry.workspaceId] ?? Duration.zero) + entry.duration;
    }

    final daily =
        byDay.entries
            .map((e) => StatsPoint(label: e.key, duration: e.value))
            .toList()
          ..sort((a, b) => a.label.compareTo(b.label));
    final shares =
        byWorkspace.entries
            .map((e) => WorkspaceShare(workspaceId: e.key, duration: e.value))
            .toList()
          ..sort((a, b) => b.duration.compareTo(a.duration));

    final activeDays = daily.length;
    final average = activeDays == 0
        ? Duration.zero
        : Duration(seconds: total.inSeconds ~/ activeDays);

    return StatsSummary(
      total: total,
      activeDays: activeDays,
      averagePerActiveDay: average,
      daily: daily,
      workspaceShare: shares,
    );
  }
}
