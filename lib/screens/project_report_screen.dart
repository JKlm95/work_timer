import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../bloc/timer_cubit.dart';
import '../export/work_entries_pdf.dart';
import '../export/work_entries_csv.dart';
import '../export/work_entry_export_table.dart';
import '../l10n/app_localizations.dart';
import '../l10n/work_mode_strings.dart';
import '../models/work_entry.dart';
import '../models/workspace.dart';
import '../services/stats_service.dart';
import '../utils/billing_entry_amount.dart';
import '../utils/calendar_utils.dart';
import '../utils/entry_type_localized.dart';
import '../utils/export_save.dart';
import '../utils/format_duration.dart';
import '../utils/workspace_color.dart';

enum _ReportRangePreset { today, thisWeek, thisMonth, previousMonth, custom }

class ProjectReportScreen extends StatefulWidget {
  const ProjectReportScreen({super.key, required this.workspaceId});

  final String workspaceId;

  @override
  State<ProjectReportScreen> createState() => _ProjectReportScreenState();
}

class _ProjectReportScreenState extends State<ProjectReportScreen> {
  static const _pdfFontAsset = 'assets/fonts/NotoSans-Regular.ttf';

  final StatsService _stats = StatsService();
  _ReportRangePreset _preset = _ReportRangePreset.thisMonth;
  DateTimeRange? _customRange;
  List<WorkEntry> _entries = [];
  bool _loading = true;

  Workspace? _workspace(TimerState state) {
    for (final w in state.workspaces) {
      if (w.id == widget.workspaceId) return w;
    }
    return null;
  }

  DateTimeRange _resolvedRange(DateTime now) {
    switch (_preset) {
      case _ReportRangePreset.today:
        return DateTimeRange(
          start: dateOnly(now),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );
      case _ReportRangePreset.thisWeek:
        return DateTimeRange(
          start: weekStartMonday(now),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );
      case _ReportRangePreset.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );
      case _ReportRangePreset.previousMonth:
        final firstThis = DateTime(now.year, now.month, 1);
        final lastPrev = firstThis.subtract(const Duration(days: 1));
        return DateTimeRange(
          start: DateTime(lastPrev.year, lastPrev.month, 1),
          end: DateTime(
            lastPrev.year,
            lastPrev.month,
            lastPrev.day,
            23,
            59,
            59,
            999,
          ),
        );
      case _ReportRangePreset.custom:
        final c = _customRange;
        if (c == null) {
          return DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
          );
        }
        return DateTimeRange(
          start: dateOnly(c.start),
          end: DateTime(c.end.year, c.end.month, c.end.day, 23, 59, 59, 999),
        );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final now = DateTime.now();
    final range = _resolvedRange(now);
    setState(() => _loading = true);
    final cubit = context.read<TimerCubit>();
    final list = await cubit.loadReportEntries(
      workspaceId: widget.workspaceId,
      range: range,
    );
    if (!mounted) return;
    setState(() {
      _entries = list..sort((a, b) => b.start.compareTo(a.start));
      _loading = false;
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initial = _customRange ?? DateTimeRange(start: now, end: now);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: initial,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _preset = _ReportRangePreset.custom;
      _customRange = picked;
    });
    await _reload();
  }

  List<List<String>>? _exportTable(AppLocalizations l10n, TimerState state) {
    final names = {for (final x in state.workspaces) x.id: x.name};
    return buildLocalizedExportTable(
      l10n: l10n,
      localeCode: Localizations.localeOf(context).languageCode,
      entries: _entries,
      workspaceNames: names,
    );
  }

  Future<Uint8List> _pdfBytes(AppLocalizations l10n, TimerState state) async {
    final table = _exportTable(l10n, state)!;
    final lc = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final range = _resolvedRange(now);
    final dFmt = DateFormat.yMMMd(lc);
    final projectName = _workspace(state)?.name ?? '';
    final meta = l10n.reportPdfMeta(
      projectName,
      dFmt.format(range.start),
      dFmt.format(range.end),
      DateFormat('yyyy-MM-dd HH:mm', lc).format(DateTime.now()),
    );
    return buildWorkEntriesPdfDocument(
      rowsWithHeader: table,
      title: l10n.reportPdfTitle(projectName),
      subtitle: meta,
      assetFontPath: _pdfFontAsset,
    );
  }

  Future<void> _shareCsv(AppLocalizations l10n, TimerState state) async {
    final table = _exportTable(l10n, state);
    if (table == null || table.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.reportExportEmpty)));
      return;
    }
    final visible = _entries.where((e) => !e.isDeleted).toList();
    final names = {for (final x in state.workspaces) x.id: x.name};
    final sep = Localizations.localeOf(context).languageCode == 'pl'
        ? ';'
        : ',';
    final csv = workEntriesToCsv(
      visible,
      workspaceNames: names,
      fieldDelimiter: sep,
      utf8Bom: true,
    );
    try {
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
      final projectSlug = (_workspace(state)?.name ?? 'project')
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      final file = File('${dir.path}/work_timer_${projectSlug}_$stamp.csv');
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.historyExportError)));
    }
  }

  Future<void> _sharePdf(AppLocalizations l10n, TimerState state) async {
    if (_exportTable(l10n, state) == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.reportExportEmpty)));
      return;
    }
    try {
      final bytes = await _pdfBytes(l10n, state);
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
      final name = 'work_timer_report_$stamp.pdf';
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

  Future<void> _saveCsv(AppLocalizations l10n, TimerState state) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.historyExportSaveWebHint)));
      return;
    }
    final table = _exportTable(l10n, state);
    if (table == null || table.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.reportExportEmpty)));
      return;
    }
    final visible = _entries.where((e) => !e.isDeleted).toList();
    final names = {for (final x in state.workspaces) x.id: x.name};
    final sep = Localizations.localeOf(context).languageCode == 'pl'
        ? ';'
        : ',';
    final csv = workEntriesToCsv(
      visible,
      workspaceNames: names,
      fieldDelimiter: sep,
      utf8Bom: true,
    );
    try {
      final stamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
      final suggested = 'work_timer_report_$stamp.csv';
      final bytes = Uint8List.fromList(utf8.encode(csv));
      final path = await saveExportWithPicker(
        dialogTitle: l10n.historyExportSaveCsvDialogTitle,
        fileName: suggested,
        bytes: bytes,
        allowedExtensions: const ['csv'],
        extensionWithoutDot: 'csv',
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

  Future<void> _savePdf(AppLocalizations l10n, TimerState state) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.historyExportSaveWebHint)));
      return;
    }
    if (_exportTable(l10n, state) == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.reportExportEmpty)));
      return;
    }
    try {
      final bytes = await _pdfBytes(l10n, state);
      final stamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
      final suggested = 'work_timer_report_$stamp.pdf';
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

  String _presetLabel(AppLocalizations l10n, _ReportRangePreset p) {
    return switch (p) {
      _ReportRangePreset.today => l10n.reportRangeToday,
      _ReportRangePreset.thisWeek => l10n.reportRangeThisWeek,
      _ReportRangePreset.thisMonth => l10n.reportRangeThisMonth,
      _ReportRangePreset.previousMonth => l10n.reportRangePreviousMonth,
      _ReportRangePreset.custom => l10n.reportRangeCustom,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lc = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final range = _resolvedRange(now);
    final timeFmt = DateFormat.Hm(lc);
    final dateFmt = DateFormat.yMMMd(lc);

    return BlocBuilder<TimerCubit, TimerState>(
      builder: (context, state) {
        final w = _workspace(state);
        if (w == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.reportTitle)),
            body: Center(child: Text(l10n.statsNoData)),
          );
        }

        final wsMap = {for (final x in state.workspaces) x.id: x};
        final est = _stats.buildBillingEstimate(
          entries: _entries,
          from: range.start,
          to: range.end,
          workspaceIds: {widget.workspaceId},
          workspaces: wsMap,
        );
        final summary = _stats.buildSummary(
          entries: _entries,
          from: range.start,
          to: range.end,
          workspaceIds: {widget.workspaceId},
        );
        final moneyFmt = NumberFormat('#,##0.00', lc);
        final accent = workspaceAccentColor(w.colorHex, scheme.primary);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.reportTitle),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.upload_file_outlined),
                onSelected: (v) async {
                  switch (v) {
                    case 'csvs':
                      await _shareCsv(l10n, state);
                      break;
                    case 'csvv':
                      await _saveCsv(l10n, state);
                      break;
                    case 'pdfs':
                      await _sharePdf(l10n, state);
                      break;
                    case 'pdfv':
                      await _savePdf(l10n, state);
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'csvs',
                    child: Text(l10n.historyExportShareCsv),
                  ),
                  PopupMenuItem(
                    value: 'csvv',
                    child: Text(l10n.historyExportSaveCsv),
                  ),
                  PopupMenuItem(
                    value: 'pdfs',
                    child: Text(l10n.historyExportSharePdf),
                  ),
                  PopupMenuItem(
                    value: 'pdfv',
                    child: Text(l10n.historyExportSavePdf),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: accent.withValues(alpha: 0.35),
                    child: Icon(Icons.folder_outlined, color: scheme.onSurface),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if ((w.companyName ?? '').trim().isNotEmpty)
                          Text(
                            w.companyName!.trim(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          '${dateFmt.format(range.start)} — ${dateFmt.format(range.end)}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.reportDateRangeSection,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in _ReportRangePreset.values)
                    if (p != _ReportRangePreset.custom)
                      ChoiceChip(
                        label: Text(_presetLabel(l10n, p)),
                        selected: _preset == p,
                        onSelected: (_) async {
                          setState(() => _preset = p);
                          await _reload();
                        },
                      ),
                  ChoiceChip(
                    label: Text(_presetLabel(l10n, _ReportRangePreset.custom)),
                    selected: _preset == _ReportRangePreset.custom,
                    onSelected: (_) => _pickCustomRange(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_entries.where((e) => !e.isDeleted).isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 48,
                          color: scheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.reportEmptyTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.reportEmptyBody,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Text(
                  l10n.reportSummarySection,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MiniMetric(
                        title: l10n.reportTotalTime,
                        value: formatDurationHm(summary.total),
                        icon: Icons.schedule_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniMetric(
                        title: l10n.statsBillableHours,
                        value: formatDurationHm(est.billableWorked),
                        icon: Icons.paid_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MiniMetric(
                        title: l10n.statsNonBillableHours,
                        value: formatDurationHm(est.nonBillableWorked),
                        icon: Icons.money_off_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniMetric(
                        title: l10n.reportEstimatedEarnings,
                        value: est.earningsByCurrency.isEmpty
                            ? '—'
                            : est.earningsByCurrency.entries
                                  .map(
                                    (e) =>
                                        '${moneyFmt.format(e.value)} ${e.key}',
                                  )
                                  .join('\n'),
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.reportEntriesSection,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ..._entries.where((e) => !e.isDeleted).map((e) {
                  final amount = billableAmountForEntry(e, w);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateFmt.format(e.start),
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
                          const SizedBox(height: 6),
                          Text(
                            '${entryTypeLocalized(e.entryType, l10n)} · ${e.mode.localized(l10n)} · ${e.isBillable ? l10n.exportBillableYes : l10n.exportBillableNo}',
                            style: theme.textTheme.bodySmall,
                          ),
                          if ((e.taskTitle ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              e.taskTitle!.trim(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if ((e.note ?? '').trim().isNotEmpty)
                            Text(
                              e.note!.trim(),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          if (amount != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              formatMoneyLine(
                                w,
                                amount,
                                moneyFmt.format(amount),
                              ),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
