import '../models/billing_currency.dart';
import '../models/work_entry.dart';
import '../models/workspace.dart';

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

/// Szacowany przychód tylko dla zakończonych wpisów, per waluta (bez przeliczników).
class BillingEstimate {
  BillingEstimate({
    required this.billableWorked,
    required this.nonBillableWorked,
    required this.earningsByCurrency,
  });

  /// Suma czasu z [WorkEntry.isBillable] == true.
  final Duration billableWorked;

  /// Suma czasu z [WorkEntry.isBillable] == false.
  final Duration nonBillableWorked;

  /// Kwoty szacunkowe (stawka × czas) tylko dla wpisów liczących się do rozliczenia.
  final Map<String, double> earningsByCurrency;
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

  /// [workspaces] — mapowanie id → projekt (stawka i waluta rozliczenia).
  BillingEstimate buildBillingEstimate({
    required List<WorkEntry> entries,
    required DateTime from,
    required DateTime to,
    required Set<String> workspaceIds,
    required Map<String, Workspace> workspaces,
  }) {
    final fromDay = DateTime(from.year, from.month, from.day);
    final toDay = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);

    final filtered = entries.where((e) {
      final inWorkspace =
          workspaceIds.isEmpty || workspaceIds.contains(e.workspaceId);
      if (!inWorkspace || e.isDeleted) return false;
      return !e.start.isBefore(fromDay) && !e.start.isAfter(toDay);
    });

    var billable = Duration.zero;
    var nonBillable = Duration.zero;
    final earnings = <String, double>{};

    for (final e in filtered) {
      if (!e.end.isAfter(e.start)) continue;
      final d = e.duration;
      if (e.isBillable) {
        billable += d;
      } else {
        nonBillable += d;
      }
      if (!e.countsTowardEarningsEstimate) continue;
      final w = workspaces[e.workspaceId];
      final rate = w?.hourlyRate;
      if (w == null || rate == null || rate <= 0) continue;
      final code =
          BillingCurrency.normalizeOrNull(w.currencyCode) ??
          BillingCurrency.defaultCode;
      final hours = d.inMicroseconds / Duration.microsecondsPerHour;
      earnings[code] = (earnings[code] ?? 0) + hours * rate;
    }

    return BillingEstimate(
      billableWorked: billable,
      nonBillableWorked: nonBillable,
      earningsByCurrency: earnings,
    );
  }
}
