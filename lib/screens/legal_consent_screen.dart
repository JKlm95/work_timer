import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/legal_links.dart';
import '../config/legal_versions.dart';
import '../l10n/app_localizations.dart';
import '../services/legal_consent_repository.dart';
import '../theme/app_layout.dart';

/// Krok prawny przed wejściem do aplikacji (bez zmiany Firebase Auth).
class LegalConsentScreen extends StatefulWidget {
  const LegalConsentScreen({
    super.key,
    required this.uid,
    required this.repository,
    required this.onConsentSaved,
    required this.onSignOut,
  });

  final String uid;
  final LegalConsentDataSource repository;
  final VoidCallback onConsentSaved;
  final VoidCallback onSignOut;

  @override
  State<LegalConsentScreen> createState() => _LegalConsentScreenState();
}

class _LegalConsentScreenState extends State<LegalConsentScreen> {
  bool _agreed = false;
  bool _saving = false;
  String? _error;

  String _platformLabel() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || ok) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.legalCouldNotOpenLink)));
  }

  Future<void> _submit() async {
    if (!_agreed || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.saveAcceptance(
        uid: widget.uid,
        termsVersion: LegalVersions.terms,
        privacyVersion: LegalVersions.privacy,
        acceptedPlatform: _platformLabel(),
      );
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onConsentSaved();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _saving = false;
        _error = l10n.legalSaveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.legalScreenTitle),
        actions: [
          TextButton(
            onPressed: _saving ? null : widget.onSignOut,
            child: Text(l10n.signOut),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.legalIntro,
                        style: textTheme.bodyLarge?.copyWith(
                          height: 1.45,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ActionChip(
                            avatar: Icon(
                              Icons.description_outlined,
                              size: 18,
                              color: scheme.primary,
                            ),
                            label: Text(l10n.legalTermsLink),
                            onPressed: _saving
                                ? null
                                : () => _openUrl(LegalLinks.termsOfService),
                          ),
                          ActionChip(
                            avatar: Icon(
                              Icons.privacy_tip_outlined,
                              size: 18,
                              color: scheme.primary,
                            ),
                            label: Text(l10n.legalPrivacyLink),
                            onPressed: _saving
                                ? null
                                : () => _openUrl(LegalLinks.privacyPolicy),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      InkWell(
                        onTap: _saving
                            ? null
                            : () => setState(() => _agreed = !_agreed),
                        borderRadius: BorderRadius.circular(AppLayout.radiusSm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 28,
                                height: AppLayout.minTouchTarget,
                                child: Checkbox(
                                  value: _agreed,
                                  onChanged: _saving
                                      ? null
                                      : (v) => setState(
                                          () => _agreed = v ?? false,
                                        ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    l10n.legalCheckboxLabel,
                                    style: textTheme.bodyMedium?.copyWith(
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: (!_agreed || _saving) ? null : _submit,
                        child: _saving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.legalContinue),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
