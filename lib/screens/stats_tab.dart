import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/timer_cubit.dart';
import '../l10n/app_localizations.dart';
import '../models/work_entry.dart';
import '../models/workspace.dart';
import '../services/stats_service.dart';
import '../utils/calendar_utils.dart';
import '../utils/format_duration.dart';

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
            _selectedWorkspaceIds.isEmpty ||
            _selectedWorkspaceIds.contains(e.workspaceId),
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
        final todayList = entriesStartingOnDay(filtered, now);
        final weekList = entriesInCurrentWeek(filtered, now);
        final today = _sum(todayList);
        final week = _sum(weekList);
        final month = _sum(filtered);
        final count = filtered.length;
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
                          child: Row(
                            children: [
                              Icon(
                                Icons.folder_outlined,
                                size: 20,
                                color: scheme.primary,
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
                        );
                      }).toList(),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final sec = buckets[i].inSeconds.toDouble();
        final ratio = maxSec <= 0 ? 0.0 : sec / maxSec;
        final day = monday.add(Duration(days: i));
        final label = dayFmt.format(day);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: ratio <= 0 ? 0.0 : ratio.clamp(0.08, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
  }
}
