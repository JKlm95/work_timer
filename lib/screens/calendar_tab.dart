import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../bloc/timer_cubit.dart';
import '../l10n/app_localizations.dart';
import '../models/work_entry.dart';
import '../models/workspace.dart';
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
                      children: events.take(3).map((e) {
                        final c = _accentForWorkspace(
                          e.workspaceId,
                          state.workspaces,
                          scheme.primary,
                        );
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
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
    List<WorkEntry> list,
    TimerState state,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lc = Localizations.localeOf(context).languageCode;
    final timeFmt = DateFormat.Hm(lc);

    if (list.isEmpty) {
      return [
        Text(
          l10n.statsNoData,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ];
    }
    list.sort((a, b) => b.start.compareTo(a.start));
    final names = {for (final w in state.workspaces) w.id: w.name};
    return list.map((e) {
      final name = names[e.workspaceId] ?? '';
      final accent = _accentForWorkspace(
        e.workspaceId,
        state.workspaces,
        scheme.primaryContainer,
      );
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: accent.withValues(alpha: 0.35),
            foregroundColor: scheme.onSurface,
            radius: 18,
            child: const SizedBox.shrink(),
          ),
          title: Text(formatDurationHm(e.duration)),
          subtitle: Text(
            '${timeFmt.format(e.start)} — ${timeFmt.format(e.end)} · '
            '${l10n.historyWorkspaceLabel(name)}',
          ),
        ),
      );
    }).toList();
  }
}
