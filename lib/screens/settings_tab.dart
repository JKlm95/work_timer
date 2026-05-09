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
              child: Column(
                children: [
                  RadioListTile<AppLocalePreference>(
                    title: Text(l10n.settingsLanguageSystem),
                    value: AppLocalePreference.system,
                    groupValue: settings.localePreference,
                    onChanged: (v) {
                      if (v != null) {
                        context.read<SettingsCubit>().setLocalePreference(v);
                      }
                    },
                  ),
                  RadioListTile<AppLocalePreference>(
                    title: Text(l10n.settingsLanguagePl),
                    value: AppLocalePreference.pl,
                    groupValue: settings.localePreference,
                    onChanged: (v) {
                      if (v != null) {
                        context.read<SettingsCubit>().setLocalePreference(v);
                      }
                    },
                  ),
                  RadioListTile<AppLocalePreference>(
                    title: Text(l10n.settingsLanguageEn),
                    value: AppLocalePreference.en,
                    groupValue: settings.localePreference,
                    onChanged: (v) {
                      if (v != null) {
                        context.read<SettingsCubit>().setLocalePreference(v);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.settingsTheme,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text(l10n.settingsThemeLight),
                    value: ThemeMode.light,
                    groupValue: settings.themeMode,
                    onChanged: (v) {
                      if (v != null) {
                        context.read<SettingsCubit>().setThemeMode(v);
                      }
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text(l10n.settingsThemeDark),
                    value: ThemeMode.dark,
                    groupValue: settings.themeMode,
                    onChanged: (v) {
                      if (v != null) {
                        context.read<SettingsCubit>().setThemeMode(v);
                      }
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text(l10n.settingsThemeSystem),
                    value: ThemeMode.system,
                    groupValue: settings.themeMode,
                    onChanged: (v) {
                      if (v != null) {
                        context.read<SettingsCubit>().setThemeMode(v);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
