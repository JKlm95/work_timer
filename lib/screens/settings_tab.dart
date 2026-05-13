import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/settings_cubit.dart';
import '../bloc/user_profile_cubit.dart';
import '../l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../widgets/ui/app_section_header.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = context.read<UserProfileCubit>().state;
      if (!s.loading) {
        _firstNameCtrl.text = s.firstName;
        _lastNameCtrl.text = s.lastName;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<UserProfileCubit, UserProfileState>(
      listenWhen: (a, b) => a.loading && !b.loading,
      listener: (context, s) {
        _firstNameCtrl.text = s.firstName;
        _lastNameCtrl.text = s.lastName;
      },
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          return BlocBuilder<UserProfileCubit, UserProfileState>(
            builder: (context, profile) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    l10n.settingsTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppSectionHeader(
                    title: l10n.settingsProfileSection,
                    subtitle: l10n.settingsProfileEmployerPanelHint,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (profile.errorMessage != null &&
                              profile.errorMessage!.isNotEmpty) ...[
                            Text(
                              profile.errorMessage!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextField(
                            controller: _firstNameCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.settingsProfileFirstName,
                              border: const OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.words,
                            enabled: !profile.loading && !profile.saving,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _lastNameCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.settingsProfileLastName,
                              border: const OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.words,
                            enabled: !profile.loading && !profile.saving,
                          ),
                          const SizedBox(height: 12),
                          InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.settingsProfileEmail,
                              border: const OutlineInputBorder(),
                            ),
                            child: Text(
                              profile.loading
                                  ? '…'
                                  : (profile.email.isEmpty
                                        ? '—'
                                        : profile.email),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: profile.loading || profile.saving
                                ? null
                                : () async {
                                    final fn = _firstNameCtrl.text;
                                    final ln = _lastNameCtrl.text;
                                    if (!UserProfile.hasAnyName(fn, ln)) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.settingsProfileNameRequired,
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    final cubit = context
                                        .read<UserProfileCubit>();
                                    final r = await cubit.save(
                                      firstName: fn,
                                      lastName: ln,
                                    );
                                    if (!context.mounted) return;
                                    if (r == ProfileSaveResult.success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.settingsProfileSaved,
                                          ),
                                        ),
                                      );
                                    } else if (r ==
                                        ProfileSaveResult.indexSyncFailed) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.settingsProfileIndexSyncFailed,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            child: profile.saving
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.settingsProfileSave),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 24,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.settingsOfflineSyncHint,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppSectionHeader(title: l10n.settingsLanguage),
                  const SizedBox(height: 8),
                  Card(
                    child: RadioGroup<AppLocalePreference>(
                      groupValue: settings.localePreference,
                      onChanged: (v) {
                        if (v != null) {
                          context.read<SettingsCubit>().setLocalePreference(v);
                        }
                      },
                      child: Column(
                        children: [
                          RadioListTile<AppLocalePreference>(
                            title: Text(l10n.settingsLanguageSystem),
                            value: AppLocalePreference.system,
                          ),
                          RadioListTile<AppLocalePreference>(
                            title: Text(l10n.settingsLanguagePl),
                            value: AppLocalePreference.pl,
                          ),
                          RadioListTile<AppLocalePreference>(
                            title: Text(l10n.settingsLanguageEn),
                            value: AppLocalePreference.en,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppSectionHeader(title: l10n.settingsTheme),
                  const SizedBox(height: 8),
                  Card(
                    child: RadioGroup<ThemeMode>(
                      groupValue: settings.themeMode,
                      onChanged: (v) {
                        if (v != null) {
                          context.read<SettingsCubit>().setThemeMode(v);
                        }
                      },
                      child: Column(
                        children: [
                          RadioListTile<ThemeMode>(
                            title: Text(l10n.settingsThemeLight),
                            value: ThemeMode.light,
                          ),
                          RadioListTile<ThemeMode>(
                            title: Text(l10n.settingsThemeDark),
                            value: ThemeMode.dark,
                          ),
                          RadioListTile<ThemeMode>(
                            title: Text(l10n.settingsThemeSystem),
                            value: ThemeMode.system,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  AppSectionHeader(title: l10n.settingsDebriefSection),
                  const SizedBox(height: 8),
                  Card(
                    child: SwitchListTile(
                      title: Text(l10n.settingsDebriefToggle),
                      value: settings.showDebriefAfterStop,
                      onChanged: (value) => context
                          .read<SettingsCubit>()
                          .setShowDebriefAfterStop(value),
                    ),
                  ),
                  const SizedBox(height: 22),
                  AppSectionHeader(title: l10n.settingsWidgetTitle),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.widgets_outlined,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              l10n.settingsWidgetDescription,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
