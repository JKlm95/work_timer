import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../export/work_entries_csv.dart';
import '../l10n/app_localizations.dart';

import '../bloc/timer_cubit.dart';
import '../l10n/work_mode_strings.dart';
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

  Future<void> _shareFilteredCsv() async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<TimerCubit>();
    final filtered = _filtered(cubit.state.entries).toList();
    if (filtered.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.historyExportEmpty)),
      );
      return;
    }
    final names = {for (final w in cubit.state.workspaces) w.id: w.name};
    final sep = Localizations.localeOf(context).languageCode == 'pl' ? ';' : ',';
    try {
      final csv = workEntriesToCsv(
        filtered,
        workspaceNames: names,
        fieldDelimiter: sep,
        utf8Bom: true,
      );
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
      final file = File('${dir.path}/work_timer_$stamp.csv');
      await file.writeAsString(csv, encoding: utf8);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          subject: l10n.historyExportShareSubject,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.historyExportError)),
      );
    }
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      initialDateRange: _range,
      locale: Localizations.localeOf(context),
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
    final outerContext = context;
    final l10n = AppLocalizations.of(outerContext)!;
    var date = DateTime(startInitial.year, startInitial.month, startInitial.day);
    var start = TimeOfDay.fromDateTime(startInitial);
    var end = TimeOfDay.fromDateTime(endInitial);
    var mode = existing?.mode ?? WorkMode.office;

    await showDialog<void>(
      context: outerContext,
      builder: (context) {
        String? error;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(
              existing == null ? l10n.historyAddEntry : l10n.historyEditEntry,
            ),
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
                        locale: Localizations.localeOf(context),
                      );
                      if (selected != null) setDialogState(() => date = selected);
                    },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      DateFormat.yMMMd(
                        Localizations.localeOf(context).languageCode,
                      ).format(date),
                    ),
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
                          child: Text(
                            l10n.historyStart(start.format(context)),
                          ),
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
                          child: Text(l10n.historyEnd(end.format(context))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<WorkMode>(
                    initialValue: mode,
                    decoration: InputDecoration(
                      labelText: l10n.historyWorkMode,
                      border: const OutlineInputBorder(),
                    ),
                    items: WorkMode.values
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.localized(l10n)),
                          ),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () async {
                  final cubit = outerContext.read<TimerCubit>();
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
                      () => error = l10n.historyValEndAfterStart,
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
                  if (!outerContext.mounted) return;
                  Navigator.of(context).pop();
                  await cubit.loadHistory(_range);
                },
                child: Text(
                  existing == null ? l10n.commonAdd : l10n.commonSave,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lc = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMd(lc);
    final timeFmt = DateFormat.Hm(lc);

    return Stack(
      children: [
        BlocBuilder<TimerCubit, TimerState>(
          builder: (context, state) {
            final filtered = _filtered(state.entries).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.historyFilters,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: _shareFilteredCsv,
                      tooltip: l10n.historyExportCsvTooltip,
                      icon: const Icon(Icons.table_chart_outlined),
                    ),
                  ],
                ),
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
                  decoration: InputDecoration(
                    labelText: l10n.historyWorkMode,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<WorkMode?>(
                      isExpanded: true,
                      value: _modeFilter,
                      items: [
                        DropdownMenuItem<WorkMode?>(
                          value: null,
                          child: Text(l10n.historyAllModes),
                        ),
                        ...WorkMode.values.map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.localized(l10n)),
                          ),
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
                        Text(
                          l10n.historyWorkspaceLabel(state.activeWorkspace.name),
                        ),
                        Text(
                          l10n.historyFilteredSum(_formatHm(_sum(filtered))),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(l10n.historyEmptyFiltered)),
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
                        subtitle: Text(e.mode.localized(l10n)),
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
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(l10n.historyMenuEdit),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l10n.historyMenuDelete),
                            ),
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
            label: Text(l10n.historyAddEntry),
          ),
        ),
      ],
    );
  }
}
