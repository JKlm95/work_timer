import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../export/work_entries_csv.dart';
import '../export/work_entries_pdf.dart';
import '../export/work_entry_export_table.dart';
import '../l10n/app_localizations.dart';

import '../bloc/timer_cubit.dart';
import '../l10n/work_mode_strings.dart';
import '../models/billing_rate_percent.dart';
import '../models/entry_type.dart';
import '../models/work_entry.dart';
import '../models/workspace.dart';
import '../models/work_mode.dart';
import '../utils/billing_entry_amount.dart';
import '../utils/entry_type_localized.dart';
import '../utils/export_save.dart';
import '../utils/format_duration.dart';
import '../utils/workspace_color.dart';
import '../widgets/ui/app_empty_state.dart';
import '../widgets/ui/entry_meta_chips.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  static const _pdfFontAsset = 'assets/fonts/NotoSans-Regular.ttf';

  late DateTimeRange _range;
  WorkMode? _modeFilter;
  EntryType? _entryTypeFilter;

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
    final from = DateTime(
      _range.start.year,
      _range.start.month,
      _range.start.day,
    );
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

  bool _entryMatchesEntryType(WorkEntry e) =>
      _entryTypeFilter == null || e.entryType == _entryTypeFilter;

  static String _workspaceName(TimerState state, WorkEntry e) {
    return state.workspaces
        .firstWhere(
          (w) => w.id == e.workspaceId,
          orElse: () => state.activeWorkspace,
        )
        .name;
  }

  Iterable<WorkEntry> _filtered(List<WorkEntry> entries) => entries
      .where((e) => e.countsInTimeAggregates)
      .where(_entryInRange)
      .where(_entryMatchesMode)
      .where(_entryMatchesEntryType);

  /// Jak [_filtered], posortowane po `start` malejąco (najpierw najnowsze).
  List<WorkEntry> _filteredNewestFirst(List<WorkEntry> entries) {
    final list = _filtered(entries).toList()
      ..sort((a, b) => b.start.compareTo(a.start));
    return list;
  }

  Duration _sum(Iterable<WorkEntry> items) =>
      items.fold(Duration.zero, (a, e) => a + e.duration);

  /// Zwraca treść CSV i proponowaną nazwę pliku, albo `null` gdy nie ma wpisów.
  ({String csv, String fileName})? _buildCsvExport() {
    final cubit = context.read<TimerCubit>();
    final filtered = _filteredNewestFirst(cubit.state.entries);
    if (filtered.isEmpty) return null;
    final names = {for (final w in cubit.state.workspaces) w.id: w.name};
    final sep = Localizations.localeOf(context).languageCode == 'pl'
        ? ';'
        : ',';
    final csv = workEntriesToCsv(
      filtered,
      workspaceNames: names,
      fieldDelimiter: sep,
      utf8Bom: true,
    );
    final stamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
    return (csv: csv, fileName: 'work_timer_$stamp.csv');
  }

  Future<void> _shareFilteredCsv() async {
    final l10n = AppLocalizations.of(context)!;
    final payload = _buildCsvExport();
    if (payload == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.historyExportEmpty)));
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${payload.fileName}');
      await file.writeAsString(payload.csv, encoding: utf8);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          subject: l10n.historyExportShareSubject,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.historyExportError)));
    }
  }

  Future<void> _saveFilteredCsvLocally() async {
    final l10n = AppLocalizations.of(context)!;
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.historyExportSaveWebHint)));
      return;
    }
    final payload = _buildCsvExport();
    if (payload == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.historyExportEmpty)));
      return;
    }
    try {
      final bytes = Uint8List.fromList(utf8.encode(payload.csv));
      final path = await saveExportWithPicker(
        dialogTitle: l10n.historyExportSaveCsvDialogTitle,
        fileName: payload.fileName,
        bytes: bytes,
        allowedExtensions: const ['csv'],
        extensionWithoutDot: 'csv',
      );
      if (path == null || !mounted) return;
      final shortName = exportSavedDisplayName(path, payload.fileName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.historyExportSaved(shortName))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.historyExportError)));
    }
  }

  List<List<String>>? _buildExportTable(AppLocalizations l10n) {
    final cubit = context.read<TimerCubit>();
    final filtered = _filteredNewestFirst(cubit.state.entries);
    final names = {for (final w in cubit.state.workspaces) w.id: w.name};
    return buildLocalizedExportTable(
      l10n: l10n,
      localeCode: Localizations.localeOf(context).languageCode,
      entries: filtered,
      workspaceNames: names,
    );
  }

  Future<Uint8List> _buildPdfBytes(AppLocalizations l10n) async {
    final table = _buildExportTable(l10n)!;
    final lc = Localizations.localeOf(context).languageCode;
    final dFmt = DateFormat.yMMMd(lc);
    final meta = l10n.exportPdfMeta(
      dFmt.format(_range.start),
      dFmt.format(_range.end),
      DateFormat('yyyy-MM-dd HH:mm', lc).format(DateTime.now()),
    );
    return buildWorkEntriesPdfDocument(
      rowsWithHeader: table,
      title: l10n.exportPdfTitle,
      subtitle: meta,
      assetFontPath: _pdfFontAsset,
    );
  }

  Future<void> _shareFilteredPdf() async {
    final l10n = AppLocalizations.of(context)!;
    if (_buildExportTable(l10n) == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.historyExportEmpty)));
      return;
    }
    try {
      final bytes = await _buildPdfBytes(l10n);
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
      final name = 'work_timer_$stamp.pdf';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: l10n.historyExportShareSubject,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.historyExportError)));
    }
  }

  Future<void> _saveFilteredPdfLocally() async {
    final l10n = AppLocalizations.of(context)!;
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.historyExportSaveWebHint)));
      return;
    }
    if (_buildExportTable(l10n) == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.historyExportEmpty)));
      return;
    }
    try {
      final bytes = await _buildPdfBytes(l10n);
      final stamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
      final suggested = 'work_timer_$stamp.pdf';
      final path = await saveExportWithPicker(
        dialogTitle: l10n.historyExportSavePdfDialogTitle,
        fileName: suggested,
        bytes: bytes,
        allowedExtensions: const ['pdf'],
        extensionWithoutDot: 'pdf',
      );
      if (path == null || !mounted) return;
      final shortName = exportSavedDisplayName(path, suggested);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.historyExportSaved(shortName))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.historyExportError)));
    }
  }

  List<Widget> _groupedHistoryEntries({
    required List<WorkEntry> filtered,
    required TimerState state,
    required DateFormat dateFmt,
    required DateFormat timeFmt,
    required ColorScheme scheme,
    required TextTheme textTheme,
    required AppLocalizations l10n,
  }) {
    final widgets = <Widget>[];
    DateTime? prevDay;
    for (final e in filtered) {
      final day = DateTime(e.start.year, e.start.month, e.start.day);
      if (prevDay == null || day != prevDay) {
        prevDay = day;
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: widgets.isEmpty ? 0 : 8, bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: scheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    dateFmt.format(e.start),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: scheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      Workspace w = state.activeWorkspace;
      for (final x in state.workspaces) {
        if (x.id == e.workspaceId) {
          w = x;
          break;
        }
      }
      final projectAccent = workspaceAccentColor(w.colorHex, scheme.primary);
      widgets.add(
        _HistorySessionCard(
          entry: e,
          workspace: w,
          timeFmt: timeFmt,
          workspaceLabel: _workspaceName(state, e),
          projectAccent: projectAccent,
          onEdit: () => _editEntryDialog(e),
          onDelete: () async {
            await context.read<TimerCubit>().deleteEntry(e);
            if (!context.mounted) return;
            if (mounted) {
              await context.read<TimerCubit>().loadHistory(_range);
            }
          },
          l10n: l10n,
        ),
      );
    }
    return widgets;
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
    final cubit0 = outerContext.read<TimerCubit>();
    final wsId0 = existing?.workspaceId ?? cubit0.state.activeWorkspaceId;
    Workspace? ws0;
    for (final w in cubit0.state.workspaces) {
      if (w.id == wsId0) {
        ws0 = w;
        break;
      }
    }
    final projectHasHourlyRate = (ws0?.hourlyRate ?? 0) > 0;
    final taskCtrl = TextEditingController(text: existing?.taskTitle ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    try {
      var date = DateTime(
        startInitial.year,
        startInitial.month,
        startInitial.day,
      );
      var start = TimeOfDay.fromDateTime(startInitial);
      var end = TimeOfDay.fromDateTime(endInitial);
      var mode = existing?.mode ?? WorkMode.office;
      var entryType = existing?.entryType ?? EntryType.work;
      var billable = existing?.isBillable ?? true;
      var billingRatePercent = existing?.billingRatePercent ?? 100;

      await showDialog<void>(
        context: outerContext,
        builder: (context) {
          String? error;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final showBillingPercent =
                  projectHasHourlyRate &&
                  entryType == EntryType.work &&
                  billable;
              return AlertDialog(
                title: Text(
                  existing == null
                      ? l10n.historyAddEntry
                      : l10n.historyEditEntry,
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
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            initialDate: date,
                            locale: Localizations.localeOf(context),
                          );
                          if (selected != null) {
                            setDialogState(() => date = selected);
                          }
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
                      const SizedBox(height: 8),
                      DropdownButtonFormField<EntryType>(
                        initialValue: entryType,
                        decoration: InputDecoration(
                          labelText: l10n.historyEntryTypeLabel,
                          border: const OutlineInputBorder(),
                        ),
                        items: EntryType.values
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(entryTypeLocalized(t, l10n)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            entryType = value;
                            if (value != EntryType.work) {
                              billable = false;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: taskCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.historyTaskLabel,
                          border: const OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.historyNoteLabel,
                          border: const OutlineInputBorder(),
                        ),
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: billable,
                        onChanged: (v) =>
                            setDialogState(() => billable = v ?? false),
                        title: Text(l10n.historyBillableLabel),
                      ),
                      if (showBillingPercent) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          key: ValueKey(billingRatePercent),
                          initialValue: billingRatePercent,
                          decoration: InputDecoration(
                            labelText: l10n.historyBillingRateLabel,
                            border: const OutlineInputBorder(),
                          ),
                          items: kBillingRatePercentOptions
                              .map(
                                (p) => DropdownMenuItem<int>(
                                  value: p,
                                  child: Text('$p%'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() => billingRatePercent = value);
                          },
                        ),
                      ],
                      if (error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          error!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
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
                      final resolvedBillingPercent =
                          projectHasHourlyRate &&
                              entryType == EntryType.work &&
                              billable
                          ? billingRatePercent
                          : 100;
                      if (existing == null) {
                        await cubit.addManualEntry(
                          start: startDate,
                          end: endDate,
                          mode: mode,
                          taskTitleRaw: taskCtrl.text,
                          noteRaw: noteCtrl.text,
                          isBillable: billable,
                          entryType: entryType,
                          billingRatePercent: resolvedBillingPercent,
                        );
                      } else {
                        await cubit.updateEntry(
                          original: existing,
                          start: startDate,
                          end: endDate,
                          mode: mode,
                          taskTitleRaw: taskCtrl.text,
                          noteRaw: noteCtrl.text,
                          isBillable: billable,
                          entryType: entryType,
                          billingRatePercent: resolvedBillingPercent,
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
              );
            },
          );
        },
      );
    } finally {
      taskCtrl.dispose();
      noteCtrl.dispose();
    }
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
            final filtered = _filteredNewestFirst(state.entries);
            final scheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;

            final hasNoLoadedData =
                !state.historyLoading && state.entries.isEmpty;
            final filtersExcludeAll =
                !state.historyLoading &&
                state.entries.isNotEmpty &&
                filtered.isEmpty;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.navHistory,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: l10n.historyExportMenuTooltip,
                      icon: const Icon(Icons.upload_file_outlined),
                      onSelected: (value) async {
                        if (value == 'csvShare') {
                          await _shareFilteredCsv();
                        } else if (value == 'csvSave') {
                          await _saveFilteredCsvLocally();
                        } else if (value == 'pdfShare') {
                          await _shareFilteredPdf();
                        } else if (value == 'pdfSave') {
                          await _saveFilteredPdfLocally();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'csvShare',
                          child: Text(l10n.historyExportShareCsv),
                        ),
                        PopupMenuItem(
                          value: 'csvSave',
                          child: Text(l10n.historyExportSaveCsv),
                        ),
                        PopupMenuItem(
                          value: 'pdfShare',
                          child: Text(l10n.historyExportSharePdf),
                        ),
                        PopupMenuItem(
                          value: 'pdfSave',
                          child: Text(l10n.historyExportSavePdf),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  l10n.historyFilters,
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (state.historyLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: scheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        color: scheme.primary,
                      ),
                    ),
                  ),
                if (state.historyOfflineFallback)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cloud_off_outlined,
                              color: scheme.onSecondaryContainer,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.syncOfflineBanner,
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.historyEntryTypeLabel,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<EntryType?>(
                      isExpanded: true,
                      value: _entryTypeFilter,
                      items: [
                        DropdownMenuItem<EntryType?>(
                          value: null,
                          child: Text(l10n.historyAllEntryTypes),
                        ),
                        ...EntryType.values.map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(entryTypeLocalized(t, l10n)),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _entryTypeFilter = v),
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
                          l10n.historyWorkspaceLabel(
                            state.activeWorkspace.name,
                          ),
                        ),
                        Text(
                          l10n.historyFilteredSum(
                            formatDurationHm(_sum(filtered)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (hasNoLoadedData)
                  AppEmptyState(
                    icon: Icons.history_toggle_off_outlined,
                    title: l10n.historyEmptyNoDataInRange,
                    body: l10n.dashboardNoSessionsBody,
                  )
                else if (filtersExcludeAll)
                  AppEmptyState(
                    icon: Icons.filter_alt_off_outlined,
                    title: l10n.historyEmptyAdjustFilters,
                  )
                else
                  ..._groupedHistoryEntries(
                    filtered: filtered,
                    state: state,
                    dateFmt: dateFmt,
                    timeFmt: timeFmt,
                    scheme: scheme,
                    textTheme: textTheme,
                    l10n: l10n,
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

class _HistorySessionCard extends StatelessWidget {
  const _HistorySessionCard({
    required this.entry,
    required this.workspace,
    required this.timeFmt,
    required this.workspaceLabel,
    required this.projectAccent,
    required this.onEdit,
    required this.onDelete,
    required this.l10n,
  });

  final WorkEntry entry;
  final Workspace workspace;
  final DateFormat timeFmt;
  final String workspaceLabel;
  final Color projectAccent;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final lc = Localizations.localeOf(context).languageCode;
    final moneyFmt = NumberFormat('#,##0.00', lc);
    final amount = billableAmountForEntry(entry, workspace);
    final amountLine = amount != null
        ? formatMoneyLine(workspace, amount, moneyFmt.format(amount))
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: projectAccent.withValues(alpha: 0.38),
                foregroundColor: scheme.onSurface,
                child: Icon(
                  entry.mode == WorkMode.remote
                      ? Icons.home_outlined
                      : Icons.apartment_outlined,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${timeFmt.format(entry.start)} — ${timeFmt.format(entry.end)}',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDurationHm(entry.duration),
                      style: textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (amountLine != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        amountLine,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    EntryMetaChips(entry: entry, l10n: l10n),
                    if ((entry.taskTitle ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        entry.taskTitle!.trim(),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if ((entry.note ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.note!.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      l10n.historyWorkspaceLabel(workspaceLabel),
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: l10n.historyMenuEdit,
                onSelected: (value) async {
                  if (value == 'edit') {
                    onEdit();
                  } else {
                    await onDelete();
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
                icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
