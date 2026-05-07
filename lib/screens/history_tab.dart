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
    return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
  }

  bool _entryInRange(WorkEntry e) {
    final from = DateTime(_range.start.year, _range.start.month, _range.start.day);
    final to = DateTime(
      _range.end.year,
      _range.end.month,
      _range.end.day,
      23,
      59,
      59,
      999,
    );
    return !e.start.isBefore(from) && !e.start.isAfter(to);
  }

  bool _entryMatchesMode(WorkEntry e) =>
      _modeFilter == null || e.mode == _modeFilter;

  Iterable<WorkEntry> _filtered(List<WorkEntry> entries) =>
      entries.where(_entryInRange).where(_entryMatchesMode);

  Duration _sum(Iterable<WorkEntry> items) =>
      items.fold(Duration.zero, (a, e) => a + e.duration);

  static String _formatHm(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h <= 0) return '$m min';
    return '$h h ${m.toString().padLeft(2, '0')} min';
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      initialDateRange: _range,
      locale: const Locale('pl'),
    );
    if (picked == null) return;
    setState(() => _range = picked);
    if (!mounted) return;
    await context.read<TimerCubit>().loadHistory(_range);
  }

  Future<void> _addEntryDialog() async {
    final now = DateTime.now();
    await _upsertEntryDialog(
      startInitial: DateTime(now.year, now.month, now.day, 9),
      endInitial: DateTime(now.year, now.month, now.day, 17),
    );
  }

  Future<void> _editEntryDialog(WorkEntry entry) async {
    await _upsertEntryDialog(
      existing: entry,
      startInitial: entry.start,
      endInitial: entry.end,
    );
  }

  Future<void> _upsertEntryDialog({
    WorkEntry? existing,
    required DateTime startInitial,
    required DateTime endInitial,
  }) async {
    var date = DateTime(startInitial.year, startInitial.month, startInitial.day);
    var start = TimeOfDay.fromDateTime(startInitial);
    var end = TimeOfDay.fromDateTime(endInitial);
    var mode = existing?.mode ?? WorkMode.office;

    await showDialog<void>(
      context: context,
      builder: (context) {
        String? error;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(existing == null ? 'Dodaj wpis' : 'Edytuj wpis'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDate: date,
                        locale: const Locale('pl'),
                      );
                      if (selected != null) setDialogState(() => date = selected);
                    },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(DateFormat.yMMMd('pl').format(date)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final selected = await showTimePicker(
                              context: context,
                              initialTime: start,
                            );
                            if (selected != null) {
                              setDialogState(() => start = selected);
                            }
                          },
                          child: Text('Start: ${start.format(context)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final selected = await showTimePicker(
                              context: context,
                              initialTime: end,
                            );
                            if (selected != null) {
                              setDialogState(() => end = selected);
                            }
                          },
                          child: Text('Koniec: ${end.format(context)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<WorkMode>(
                    initialValue: mode,
                    decoration: const InputDecoration(
                      labelText: 'Tryb pracy',
                      border: OutlineInputBorder(),
                    ),
                    items: WorkMode.values
                        .map(
                          (m) => DropdownMenuItem(value: m, child: Text(m.labelPl)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => mode = value);
                    },
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: () async {
                  final cubit = this.context.read<TimerCubit>();
                  final startDate = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    start.hour,
                    start.minute,
                  );
                  final endDate = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    end.hour,
                    end.minute,
                  );
                  if (!endDate.isAfter(startDate)) {
                    setDialogState(
                      () => error = 'Godzina konca musi byc po starcie.',
                    );
                    return;
                  }
                  if (existing == null) {
                    await cubit.addManualEntry(
                      start: startDate,
                      end: endDate,
                      mode: mode,
                    );
                  } else {
                    await cubit.updateEntry(
                      original: existing,
                      start: startDate,
                      end: endDate,
                      mode: mode,
                    );
                  }
                  if (!this.context.mounted) return;
                  Navigator.of(context).pop();
                  await cubit.loadHistory(_range);
                },
                child: Text(existing == null ? 'Dodaj' : 'Zapisz'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd('pl');
    final timeFmt = DateFormat.Hm('pl');

    return Stack(
      children: [
        BlocBuilder<TimerCubit, TimerState>(
          builder: (context, state) {
            final filtered = _filtered(state.entries).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
              children: [
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
                          (m) =>
                              DropdownMenuItem(value: m, child: Text(m.labelPl)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _modeFilter = v),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Workspace: ${state.activeWorkspace.name}'),
                        Text('W filtrze: ${_formatHm(_sum(filtered))}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Brak wpisow dla wybranych filtrow.')),
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
                          '${dateFmt.format(e.start)} ${timeFmt.format(e.start)} — ${timeFmt.format(e.end)}',
                        ),
                        subtitle: Text(e.mode.labelPl),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await _editEntryDialog(e);
                            } else {
                              await context.read<TimerCubit>().deleteEntry(e);
                              if (!context.mounted) return;
                              if (mounted) {
                                await context.read<TimerCubit>().loadHistory(_range);
                              }
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edytuj')),
                            PopupMenuItem(value: 'delete', child: Text('Usun')),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(_formatHm(e.duration)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _addEntryDialog,
            icon: const Icon(Icons.add),
            label: const Text('Dodaj wpis'),
          ),
        ),
      ],
    );
  }
}
