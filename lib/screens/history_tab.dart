import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/timer_cubit.dart';
import '../models/work_entry.dart';
import '../models/work_mode.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  late DateTimeRange _range;
  WorkMode? _modeFilter;

  @override
  void initState() {
    super.initState();
    _range = _defaultMonthRange();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TimerCubit>().loadHistory(_range);
    });
  }

  DateTimeRange _defaultMonthRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final end = now.isBefore(lastDay) ? now : lastDay;
    return DateTimeRange(start: start, end: end);
  }

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _dayEnd(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  bool _entryInRange(WorkEntry e) {
    final from = _dayStart(_range.start);
    final to = _dayEnd(_range.end);
    return !e.start.isBefore(from) && !e.start.isAfter(to);
  }

  bool _entryMatchesMode(WorkEntry e) =>
      _modeFilter == null || e.mode == _modeFilter;

  Iterable<WorkEntry> _filtered(List<WorkEntry> entries) =>
      entries.where(_entryInRange).where(_entryMatchesMode);

  Duration _sum(Iterable<WorkEntry> items) =>
      items.fold(Duration.zero, (a, e) => a + e.duration);

  Duration _currentMonthTotal(List<WorkEntry> currentMonthEntries) {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = _dayEnd(DateTime(now.year, now.month + 1, 0));
    return _sum(
      currentMonthEntries.where((e) {
        return !e.start.isBefore(from) && !e.start.isAfter(to);
      }),
    );
  }

  static String _formatHm(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h <= 0) return '$m min';
    if (m == 0) return '$h h';
    return '$h h $m min';
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      initialDateRange: _range,
      locale: const Locale('pl'),
    );
    if (picked != null) {
      setState(() => _range = picked);
      if (!mounted) return;
      await context.read<TimerCubit>().loadHistory(_range);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd('pl');
    final timeFmt = DateFormat.Hm('pl');

    return BlocBuilder<TimerCubit, TimerState>(
      builder: (context, state) {
        final filtered = _filtered(state.entries).toList();
        final sumFiltered = _sum(filtered);
        final monthTotal = _currentMonthTotal(state.currentMonthEntries);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Podsumowanie',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bieżący miesiąc (wszystkie tryby): ${_formatHm(monthTotal)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'W filtrze: ${_formatHm(sumFiltered)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Filtry', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickRange,
              icon: const Icon(Icons.date_range),
              label: Text(
                '${dateFmt.format(_range.start)} — ${dateFmt.format(_range.end)}',
              ),
            ),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Tryb pracy',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<WorkMode?>(
                  isExpanded: true,
                  value: _modeFilter,
                  items: [
                    const DropdownMenuItem<WorkMode?>(
                      value: null,
                      child: Text('Wszystkie'),
                    ),
                    ...WorkMode.values.map(
                      (m) => DropdownMenuItem(value: m, child: Text(m.labelPl)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _modeFilter = v),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                setState(() {
                  _range = _defaultMonthRange();
                  _modeFilter = null;
                });
                await context.read<TimerCubit>().loadHistory(_range);
              },
              icon: const Icon(Icons.restore),
              label: const Text('Ustaw bieżący miesiąc'),
            ),
            const SizedBox(height: 16),
            if (state.historyLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            if (state.historyOfflineFallback)
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Tryb offline: pokazuję lokalne dane. Starsze zakresy wymagają internetu.',
                  ),
                ),
              ),
            if (state.historyOfflineFallback) const SizedBox(height: 12),
            Text(
              'Wpisy (${filtered.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Brak wpisów dla wybranych filtrów.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              )
            else
              ...filtered.map(
                (e) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      e.mode == WorkMode.remote
                          ? Icons.home_outlined
                          : Icons.apartment_outlined,
                    ),
                    title: Text(
                      '${dateFmt.format(e.start)}  ${timeFmt.format(e.start)} — '
                      '${timeFmt.format(e.end)}',
                    ),
                    subtitle: Text(e.mode.labelPl),
                    trailing: Text(
                      _formatHm(e.duration),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
