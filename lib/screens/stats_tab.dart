import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/timer_cubit.dart';
import '../l10n/app_localizations.dart';
import '../models/work_entry.dart';
import '../models/workspace.dart';
import 'project_report_screen.dart';
import '../services/stats_service.dart';
import '../utils/calendar_utils.dart';
import '../utils/format_duration.dart';
import '../utils/workspace_color.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  final StatsService _statsService = StatsService();
  final Set<String> _selectedWorkspaceIds = {};

  Iterable<WorkEntry> _filteredForSelection(List<WorkEntry> entries) =>
      entries.where(
        (e) =>
            e.countsInTimeAggregates &&
            (_selectedWorkspaceIds.isEmpty ||
                _selectedWorkspaceIds.contains(e.workspaceId)),
      );

  Duration _sum(Iterable<WorkEntry> items) =>
      items.fold(Duration.zero, (a, e) => a + e.duration);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final now = DateTime.now();
    final lc = Localizations.localeOf(context).languageCode;

    return BlocBuilder<TimerCubit, TimerState>(
      builder: (context, state) {
        final filtered = _filteredForSelection(state.statsEntries).toList();
        final monthEntries = filtered
            .where(
              (e) => e.start.year == now.year && e.start.month == now.month,
            )
            .toList();
        final todayList = entriesStartingOnDay(filtered, now);
        final weekList = entriesInCurrentWeek(filtered, now);
        final today = _sum(todayList);
        final week = _sum(weekList);
        final month = _sum(monthEntries);
        final count = monthEntries.length;
        final avg = count == 0
            ? Duration.zero
            : Duration(seconds: month.inSeconds ~/ count);
        final weekBuckets = weekDayDurations(filtered, now);
        final monday = weekStartMonday(now);

        if (state.statsEntries.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.navStats,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.insights_outlined,
                        size: 56,
                        color: scheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.statsEmptyTitle,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.statsEmptyBody,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              l10n.navStats,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.statsBasicTitle,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _WorkspaceFilter(
              workspaces: state.workspaces,
              selectedIds: _selectedWorkspaceIds,
              allLabel: l10n.statsAllWorkspaces,
              onChanged: (ids) => setState(() {
                _selectedWorkspaceIds
                  ..clear()
                  ..addAll(ids);
              }),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    title: l10n.statsCardToday,
                    value: formatDurationHm(today),
                    icon: Icons.wb_sunny_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    title: l10n.statsCardThisWeek,
                    value: formatDurationHm(week),
                    icon: Icons.calendar_view_week_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    title: l10n.statsCardThisMonth,
                    value: formatDurationHm(month),
                    icon: Icons.calendar_month_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    title: l10n.statsAvgSession,
                    value: formatDurationHm(avg),
                    icon: Icons.timeline_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _MetricTile(
                title: l10n.statsSessionCount,
                value: '$count',
                icon: Icons.format_list_numbered_rounded,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.statsWeeklyOverview,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 200,
                  child: _WeekBarChart(
                    buckets: weekBuckets,
                    monday: monday,
                    localeCode: lc,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.statsWorkspaceShare,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Builder(
                  builder: (context) {
                    final range = DateTimeRange(
                      start: DateTime(now.year, now.month, 1),
                      end: now,
                    );
                    final summary = _statsService.buildSummary(
                      entries: state.statsEntries,
                      from: range.start,
                      to: range.end,
                      workspaceIds: _selectedWorkspaceIds,
                    );
                    if (summary.workspaceShare.isEmpty) {
                      return Text(
                        l10n.statsNoData,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: summary.workspaceShare.map((share) {
                        final workspaceName = state.workspaces
                            .firstWhere(
                              (w) => w.id == share.workspaceId,
                              orElse: () => state.activeWorkspace,
                            )
                            .name;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 9,
                                    backgroundColor: workspaceAccentColor(
                                      state.workspaces
                                          .firstWhere(
                                            (w) => w.id == share.workspaceId,
                                            orElse: () => state.activeWorkspace,
                                          )
                                          .colorHex,
                                      scheme.primary,
                                    ).withValues(alpha: 0.45),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      workspaceName,
                                      style: textTheme.bodyLarge,
                                    ),
                                  ),
                                  Text(
                                    formatDurationHm(share.duration),
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => BlocProvider.value(
                                          value: context.read<TimerCubit>(),
                                          child: ProjectReportScreen(
                                            workspaceId: share.workspaceId,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.assignment_outlined,
                                    size: 18,
                                  ),
                                  label: Text(l10n.statsOpenProjectReport),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.statsBillingTitle,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Builder(
                  builder: (context) {
                    final range = DateTimeRange(
                      start: DateTime(now.year, now.month, 1),
                      end: now,
                    );
                    final wsMap = {for (final w in state.workspaces) w.id: w};
                    final est = _statsService.buildBillingEstimate(
                      entries: state.statsEntries,
                      from: range.start,
                      to: range.end,
                      workspaceIds: _selectedWorkspaceIds,
                      workspaces: wsMap,
                    );
                    final fmt = NumberFormat('#,##0.00', lc);
                    final currencyLines =
                        est.earningsByCurrency.entries.toList()
                          ..sort((a, b) => a.key.compareTo(b.key));
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MetricTile(
                                title: l10n.statsBillableHours,
                                value: formatDurationHm(est.billableWorked),
                                icon: Icons.paid_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricTile(
                                title: l10n.statsNonBillableHours,
                                value: formatDurationHm(est.nonBillableWorked),
                                icon: Icons.money_off_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.statsEstimatedEarnings,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (currencyLines.isEmpty)
                          Text(
                            l10n.statsEstimatedEarningsEmpty,
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          )
                        else
                          ...currencyLines.map(
                            (e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                l10n.statsEstimatedEarningsLine(
                                  e.key,
                                  fmt.format(e.value),
                                ),
                                style: textTheme.bodyLarge,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WorkspaceFilter extends StatelessWidget {
  const _WorkspaceFilter({
    required this.workspaces,
    required this.selectedIds,
    required this.allLabel,
    required this.onChanged,
  });

  final List<Workspace> workspaces;
  final Set<String> selectedIds;
  final String allLabel;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: Text(allLabel),
          selected: selectedIds.isEmpty,
          onSelected: (_) => onChanged({}),
        ),
        ...workspaces.map(
          (workspace) => FilterChip(
            avatar: CircleAvatar(
              radius: 10,
              backgroundColor: workspaceAccentColor(
                workspace.colorHex,
                scheme.primary,
              ).withValues(alpha: 0.45),
              child: const SizedBox.shrink(),
            ),
            label: Text(workspace.name),
            selected: selectedIds.contains(workspace.id),
            onSelected: (value) {
              final next = {...selectedIds};
              if (value) {
                next.add(workspace.id);
              } else {
                next.remove(workspace.id);
              }
              onChanged(next);
            },
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary, size: 22),
            const SizedBox(height: 12),
            Text(
              title,
              style: textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekBarChart extends StatelessWidget {
  const _WeekBarChart({
    required this.buckets,
    required this.monday,
    required this.localeCode,
  });

  final List<Duration> buckets;
  final DateTime monday;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final maxSec = buckets
        .map((d) => d.inSeconds)
        .fold<int>(0, (a, b) => math.max(a, b))
        .toDouble();

    if (maxSec <= 0) {
      return Center(
        child: Text(
          l10n.statsNoData,
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }

    final dayFmt = DateFormat.E(localeCode);
    const labelReserve = 28.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barAreaHeight = math.max(
          0.0,
          constraints.maxHeight - labelReserve,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final sec = buckets[i].inSeconds.toDouble();
            final ratio = maxSec <= 0 ? 0.0 : sec / maxSec;
            final day = monday.add(Duration(days: i));
            final label = dayFmt.format(day);
            final h = ratio <= 0
                ? 0.0
                : (barAreaHeight * ratio.clamp(0.08, 1.0));

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: barAreaHeight,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          width: double.infinity,
                          height: h,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
