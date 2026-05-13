import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/entry_type.dart';
import '../../models/work_entry.dart';
import '../../utils/entry_type_localized.dart';

/// Kompaktowe chipy metadanych wpisu (typ, rozliczenie, stawka %, usunięty).
class EntryMetaChips extends StatelessWidget {
  const EntryMetaChips({super.key, required this.entry, required this.l10n});

  final WorkEntry entry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget chip(String label, {IconData? icon, Color? foreground}) {
      return Chip(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
        backgroundColor: scheme.surfaceContainerHighest.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.42 : 0.28,
        ),
        avatar: icon != null
            ? Icon(icon, size: 14, color: foreground ?? scheme.primary)
            : null,
        label: Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: foreground,
          ),
        ),
      );
    }

    final chips = <Widget>[
      chip(
        entryTypeLocalized(entry.entryType, l10n),
        icon: Icons.category_outlined,
      ),
      chip(
        entry.isBillable ? l10n.exportBillableYes : l10n.exportBillableNo,
        icon: entry.isBillable ? Icons.paid_outlined : Icons.money_off_outlined,
      ),
    ];

    if (entry.entryType == EntryType.work &&
        entry.isBillable &&
        entry.billingRatePercent != 100) {
      chips.add(
        chip('${entry.billingRatePercent}%', icon: Icons.percent_outlined),
      );
    }

    if (entry.isDeleted) {
      chips.add(
        chip(
          l10n.historyBadgeDeleted,
          icon: Icons.delete_outline,
          foreground: scheme.error,
        ),
      );
    }

    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }
}
