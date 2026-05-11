import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../l10n/app_localizations.dart';

import '../bloc/settings_cubit.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.settingsTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.settingsLanguage,
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
            const SizedBox(height: 16),
            Text(
              l10n.settingsTheme,
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
            const SizedBox(height: 24),
            Text(
              l10n.settingsDebriefSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
            const SizedBox(height: 24),
            Text(
              l10n.settingsWidgetTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
  }
}
