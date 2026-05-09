import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../l10n/app_localizations.dart';

import '../bloc/timer_cubit.dart';
import '../models/workspace.dart';
import '../services/stats_service.dart';
import '../theme/app_colors.dart';

enum StatsRange { week, month }

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  final StatsService _statsService = StatsService();
  StatsRange _range = StatsRange.week;
  final Set<String> _selectedWorkspaceIds = {};

  DateTimeRange _resolveRange() {
    final now = DateTime.now();
    if (_range == StatsRange.week) {
      final from = now.subtract(Duration(days: now.weekday - 1));
      return DateTimeRange(start: from, end: now);
    }
    final from = DateTime(now.year, now.month, 1);
    return DateTimeRange(start: from, end: now);
  }

  static String _formatHm(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h <= 0) return '$m min';
    return '$h h ${m.toString().padLeft(2, '0')} min';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<TimerCubit, TimerState>(
      builder: (context, state) {
        final range = _resolveRange();
        final summary = _statsService.buildSummary(
          entries: state.statsEntries,
          from: range.start,
          to: range.end,
          workspaceIds: _selectedWorkspaceIds,
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<StatsRange>(
              segments: [
                ButtonSegment(
                  value: StatsRange.week,
                  label: Text(l10n.statsWeek),
                ),
                ButtonSegment(
                  value: StatsRange.month,
                  label: Text(l10n.statsMonth),
                ),
              ],
              selected: {_range},
              onSelectionChanged: (value) {
                setState(() => _range = value.first);
              },
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.statsBasicTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.statsTotal(_formatHm(summary.total))),
                    Text(l10n.statsActiveDays(summary.activeDays)),
                    Text(
                      l10n.statsAvgPerDay(
                        _formatHm(summary.averagePerActiveDay),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.statsDailyChart,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: _DailyBarChart(points: summary.daily),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.statsWorkspaceShare,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (summary.workspaceShare.isEmpty)
                      Text(l10n.statsNoData)
                    else
                      ...summary.workspaceShare.map((share) {
                        final workspaceName = state.workspaces
                            .firstWhere(
                              (w) => w.id == share.workspaceId,
                              orElse: () => state.activeWorkspace,
                            )
                            .name;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(workspaceName),
                              Text(_formatHm(share.duration)),
                            ],
                          ),
                        );
                      }),
                  ],
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

class _DailyBarChart extends StatelessWidget {
  const _DailyBarChart({required this.points});

  final List<StatsPoint> points;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (points.isEmpty) {
      return Center(child: Text(l10n.statsNoData));
    }

    final maxSec = points
        .map((p) => p.duration.inSeconds)
        .fold<int>(0, (a, b) => math.max(a, b))
        .toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: points.map((point) {
        final ratio = maxSec <= 0 ? 0.0 : point.duration.inSeconds / maxSec;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: ratio,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  point.label.split('-').last,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
