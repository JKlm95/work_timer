import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../bloc/timer_cubit.dart';
import '../l10n/app_localizations.dart';
import '../models/entry_type.dart';
import '../models/work_entry.dart';
import '../models/workspace.dart';
import '../services/stats_service.dart';
import '../utils/calendar_utils.dart' show dateOnly;
import '../utils/entry_type_localized.dart';
import '../utils/format_duration.dart';
import '../utils/workspace_color.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;
  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadMonth(_focused);
    });
  }

  Future<void> _loadMonth(DateTime month) async {
    final cubit = context.read<TimerCubit>();
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);
    await cubit.refreshStatsEntries(
      range: DateTimeRange(start: start, end: end),
    );
  }

  DateTime _dayKey(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  Map<DateTime, List<WorkEntry>> _byDay(List<WorkEntry> entries) {
    final map = <DateTime, List<WorkEntry>>{};
    for (final e in entries) {
      if (e.isDeleted) continue;
      final key = _dayKey(e.start);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  Color _accentForWorkspace(
    String workspaceId,
    List<Workspace> workspaces,
    Color fallback,
  ) {
    for (final w in workspaces) {
      if (w.id == workspaceId) {
        return workspaceAccentColor(w.colorHex, fallback);
      }
    }
    return fallback;
  }

  Color _markerColor({
    required WorkEntry e,
    required List<Workspace> workspaces,
    required Color fallback,
    required ColorScheme scheme,
  }) {
    switch (e.entryType) {
      case EntryType.work:
        return _accentForWorkspace(e.workspaceId, workspaces, fallback);
      case EntryType.vacation:
        return scheme.tertiary;
      case EntryType.sickLeave:
        return scheme.error;
      case EntryType.businessTrip:
        return scheme.secondary;
      case EntryType.other:
        return scheme.outline;
    }
  }

  String _tableCalendarLocale(Locale device) {
    if (device.languageCode == 'pl') return 'pl_PL';
    return 'en_US';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final deviceLocale = Localizations.localeOf(context);

    return BlocBuilder<TimerCubit, TimerState>(
      builder: (context, state) {
        final byDay = _byDay(state.statsEntries);
        final lc = deviceLocale.languageCode;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              l10n.calendarTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TableCalendar<WorkEntry>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(DateTime.now().year + 2, 12, 31),
              focusedDay: _focused,
              calendarFormat: _format,
              locale: _tableCalendarLocale(deviceLocale),
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) =>
                  _selected != null && _dayKey(day) == _dayKey(_selected!),
              eventLoader: (day) => byDay[_dayKey(day)] ?? [],
              onDaySelected: (sel, foc) {
                setState(() {
                  _selected = sel;
                  _focused = foc;
                });
              },
              onPageChanged: (foc) {
                setState(() => _focused = foc);
                unawaited(_loadMonth(foc));
              },
              calendarStyle: CalendarStyle(
                markersMaxCount: 4,
                markerDecoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders<WorkEntry>(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: events.take(4).map((e) {
                        final isWork = e.entryType == EntryType.work;
                        final c = _markerColor(
                          e: e,
                          workspaces: state.workspaces,
                          fallback: scheme.primary,
                          scheme: scheme,
                        );
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isWork ? c : Colors.transparent,
                            shape: BoxShape.circle,
                            border: isWork
                                ? null
                                : Border.all(color: c, width: 1.5),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
              ),
              onFormatChanged: (f) => setState(() => _format = f),
            ),
            if (_selected != null) ...[
              const SizedBox(height: 20),
              Text(
                DateFormat.yMMMd(lc).format(_selected!),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ..._buildSelectedDayList(
                context,
                _selected!,
                byDay[_dayKey(_selected!)] ?? [],
                state,
                l10n,
              ),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _buildSelectedDayList(
    BuildContext context,
    DateTime selectedDay,
    List<WorkEntry> list,
    TimerState state,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lc = Localizations.localeOf(context).languageCode;
    final timeFmt = DateFormat.Hm(lc);
    final statsService = StatsService();
    final wsMap = {for (final w in state.workspaces) w.id: w};

    if (list.isEmpty) {
      return [
        Text(
          l10n.calendarDayNoEntries,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ];
    }
    list.sort((a, b) => b.start.compareTo(a.start));
    final names = {for (final w in state.workspaces) w.id: w.name};
    final dayStart = dateOnly(selectedDay);
    final dayEnd = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
      23,
      59,
      59,
      999,
    );
    final est = statsService.buildBillingEstimate(
      entries: list,
      from: dayStart,
      to: dayEnd,
      workspaceIds: {},
      workspaces: wsMap,
    );
    final totalDur = list.fold<Duration>(
      Duration.zero,
      (a, e) => a + e.duration,
    );
    final moneyFmt = NumberFormat('#,##0.00', lc);

    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.calendarDaySummaryTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.reportTotalTime}: ${formatDurationHm(totalDur)}',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '${l10n.statsBillableHours}: ${formatDurationHm(est.billableWorked)}',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '${l10n.statsNonBillableHours}: ${formatDurationHm(est.nonBillableWorked)}',
                style: theme.textTheme.bodyMedium,
              ),
              if (est.earningsByCurrency.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.calendarDayEstimatedHint,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ...est.earningsByCurrency.entries.map(
                  (kv) => Text(
                    '${moneyFmt.format(kv.value)} ${kv.key}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      ...list.map((e) {
        final name = names[e.workspaceId] ?? '';
        final accent = _markerColor(
          e: e,
          workspaces: state.workspaces,
          fallback: scheme.primary,
          scheme: scheme,
        );
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: accent.withValues(alpha: 0.38),
                  foregroundColor: scheme.onSurface,
                  radius: 18,
                  child: const SizedBox.shrink(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${timeFmt.format(e.start)} — ${timeFmt.format(e.end)} · ${formatDurationHm(e.duration)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entryTypeLocalized(e.entryType, l10n)} · ${e.isBillable ? l10n.exportBillableYes : l10n.exportBillableNo}',
                        style: theme.textTheme.bodySmall,
                      ),
                      if ((e.taskTitle ?? '').trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            e.taskTitle!.trim(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if ((e.note ?? '').trim().isNotEmpty)
                        Text(
                          e.note!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ];
  }
}
