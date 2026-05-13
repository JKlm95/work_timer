import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/billing_currency.dart';
import '../models/workspace.dart';
import '../utils/project_field_utils.dart';

Future<Workspace?> showProjectEditorSheet(
  BuildContext context, {
  Workspace? initial,
}) {
  return showModalBottomSheet<Workspace>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ProjectEditorBody(initial: initial),
  );
}

const _presetColorHex = <String>[
  '4CAF50',
  '2196F3',
  'FF9800',
  'E91E63',
  '9C27B0',
  '00BCD4',
  '795548',
  '607D8B',
];

class _ProjectEditorBody extends StatefulWidget {
  const _ProjectEditorBody({this.initial});

  final Workspace? initial;

  @override
  State<_ProjectEditorBody> createState() => _ProjectEditorBodyState();
}

class _ProjectEditorBodyState extends State<_ProjectEditorBody> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _slugCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _employerEmailsCtrl;
  late final TextEditingController _customColorCtrl;

  late Workspace _base;
  late String _colorHexNoHash;
  late String _currencyCode;
  late bool _shareEmployer;
  late bool _isArchived;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _base =
        widget.initial ??
        Workspace(
          id: now.microsecondsSinceEpoch.toString(),
          name: '',
          createdAt: now,
          updatedAt: now,
          currencyCode: BillingCurrency.defaultCode,
        );
    _nameCtrl = TextEditingController(text: _base.name);
    _rateCtrl = TextEditingController(
      text: _base.hourlyRate != null ? _formatRate(_base.hourlyRate!) : '',
    );
    _companyCtrl = TextEditingController(text: _base.companyName ?? '');
    _slugCtrl = TextEditingController(text: _base.companySlug ?? '');
    _emailCtrl = TextEditingController(text: _base.employeeWorkEmail ?? '');
    _employerEmailsCtrl = TextEditingController(
      text: _base.linkedEmployerEmails.join(', '),
    );
    final ch = _base.colorHex;
    _customColorCtrl = TextEditingController(
      text: ch != null && ch.startsWith('#') ? ch.substring(1) : (ch ?? ''),
    );
    _colorHexNoHash = () {
      if (ch == null || ch.isEmpty) return _presetColorHex.first;
      var s = ch.trim();
      if (s.startsWith('#')) s = s.substring(1);
      return s.toUpperCase();
    }();
    _currencyCode =
        BillingCurrency.normalizeOrNull(_base.currencyCode) ??
        BillingCurrency.defaultCode;
    _shareEmployer = _base.isSharedWithEmployer;
    _isArchived = _base.isArchived;
  }

  String _formatRate(double x) {
    if (x == x.roundToDouble()) return x.round().toString();
    return x.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rateCtrl.dispose();
    _companyCtrl.dispose();
    _slugCtrl.dispose();
    _emailCtrl.dispose();
    _employerEmailsCtrl.dispose();
    _customColorCtrl.dispose();
    super.dispose();
  }

  List<String> _parseEmployerEmails(String raw) {
    final parts = raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    return normalizeLinkedEmployerEmails(parts);
  }

  Workspace _buildSaved() {
    final name = _nameCtrl.text.trim();
    final rateText = _rateCtrl.text.trim().replaceAll(',', '.');
    final rate = rateText.isEmpty ? null : double.tryParse(rateText);
    final workEmailNorm = _emailCtrl.text.trim().toLowerCase();
    final domain = extractEmailDomain(
      workEmailNorm.isEmpty ? null : workEmailNorm,
    );

    String? slugOut;
    if (_shareEmployer) {
      slugOut = resolveCompanySlugForSave(
        slugField: _slugCtrl.text,
        companyNameField: _companyCtrl.text,
        persistedSlug: _base.companySlug,
      );
    }

    final colorNormalized = _parseHexRgb(_colorHexNoHash);

    return Workspace(
      id: _base.id,
      name: name,
      createdAt: _base.createdAt,
      updatedAt: DateTime.now(),
      isArchived: _isArchived,
      companyName: _shareEmployer && _companyCtrl.text.trim().isNotEmpty
          ? _companyCtrl.text.trim()
          : null,
      companySlug: slugOut,
      employeeWorkEmail: _shareEmployer && workEmailNorm.isNotEmpty
          ? workEmailNorm
          : null,
      employeeWorkEmailDomain: _shareEmployer ? domain : null,
      colorHex: colorNormalized != null
          ? '#${colorNormalized.toUpperCase()}'
          : null,
      hourlyRate: rate,
      currencyCode: _currencyCode,
      isSharedWithEmployer: _shareEmployer,
      linkedEmployerEmails: _shareEmployer
          ? _parseEmployerEmails(_employerEmailsCtrl.text)
          : const [],
    );
  }

  String? _parseHexRgb(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    var s = raw.trim().toUpperCase();
    if (s.startsWith('#')) s = s.substring(1);
    if (RegExp(r'^[0-9A-F]{6}$').hasMatch(s)) return s;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.initial == null
                        ? l10n.projectsNewTitle
                        : l10n.projectsEditTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.projectsNameLabel,
                errorText: _nameError,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.projectsColorSection,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetColorHex.map((hex) {
                final selected = _colorHexNoHash.toUpperCase() == hex;
                final c = Color(0xFF000000 | int.parse(hex, radix: 16));
                return InkWell(
                  onTap: () => setState(() => _colorHexNoHash = hex),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: selected ? 3 : 1,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customColorCtrl,
              decoration: InputDecoration(
                labelText: l10n.projectsColorHexOptional,
                hintText: 'RRGGBB',
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) {
                final n = _parseHexRgb(v);
                if (n != null) {
                  setState(() => _colorHexNoHash = n);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _rateCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.projectsHourlyRate,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _currencyCode,
                    decoration: InputDecoration(
                      labelText: l10n.projectsCurrency,
                      border: const OutlineInputBorder(),
                    ),
                    items: BillingCurrency.supportedCodes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _currencyCode = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.projectsHourlyRatePanelHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.projectsShareEmployer),
              value: _shareEmployer,
              onChanged: (v) => setState(() => _shareEmployer = v),
            ),
            Text(
              l10n.projectsShareEmployerSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (_shareEmployer) ...[
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _companyCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.projectsCompanyName,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _slugCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.projectsCompanySlugHint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.projectsShareEmployerProfileNamesHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.projectsEmployeeWorkEmail,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _employerEmailsCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.projectsEmployerEmailsHint,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.projectsArchived),
              subtitle: Text(l10n.projectsArchivedSubtitle),
              value: _isArchived,
              onChanged: (v) => setState(() => _isArchived = v),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _nameError = _nameCtrl.text.trim().isEmpty
                      ? l10n.projectsValidationName
                      : null;
                });
                if (_nameError != null) return;
                Navigator.of(context).pop(_buildSaved());
              },
              icon: const Icon(Icons.save_outlined),
              label: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}
