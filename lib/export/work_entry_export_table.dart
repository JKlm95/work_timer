import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/work_entry.dart';
import '../models/work_mode.dart';
import '../utils/entry_type_localized.dart';
import '../utils/format_duration.dart';

/// Jedna tabela (nagłówek + wiersze) pod PDF/CSV z lokalizowanymi etykietami.
List<List<String>>? buildLocalizedExportTable({
  required AppLocalizations l10n,
  required String localeCode,
  required List<WorkEntry> entries,
  required Map<String, String> workspaceNames,
}) {
  final visible = entries.where((e) => !e.isDeleted).toList();
  if (visible.isEmpty) return null;

  final dFmt = DateFormat.yMMMd(localeCode);
  final tFmt = DateFormat.Hm(localeCode);
  String when(DateTime d) => '${dFmt.format(d)} ${tFmt.format(d)}';

  final header = [
    l10n.exportHdrId,
    l10n.exportHdrWorkspaceId,
    l10n.exportHdrProject,
    l10n.exportHdrStart,
    l10n.exportHdrEnd,
    l10n.exportHdrDurationHm,
    l10n.exportHdrMode,
    l10n.exportHdrEntryType,
    l10n.exportHdrBillable,
    l10n.exportHdrBillingPercent,
    l10n.exportHdrTask,
    l10n.exportHdrNote,
  ];

  final rows = visible
      .map(
        (e) => [
          e.id,
          e.workspaceId,
          workspaceNames[e.workspaceId] ?? '',
          when(e.start),
          when(e.end),
          formatDurationHm(e.duration),
          e.mode == WorkMode.remote ? l10n.workModeRemote : l10n.workModeOffice,
          entryTypeLocalized(e.entryType, l10n),
          e.isBillable ? l10n.exportBillableYes : l10n.exportBillableNo,
          '${e.billingRatePercent}',
          e.taskTitle ?? '',
          e.note ?? '',
        ],
      )
      .toList();

  return [header, ...rows];
}
