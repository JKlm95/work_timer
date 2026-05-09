import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLocalePreference {
  system,
  pl,
  en,
}

class SettingsState {
  const SettingsState({
    this.localePreference = AppLocalePreference.system,
    this.themeMode = ThemeMode.system,
  });

  final AppLocalePreference localePreference;
  final ThemeMode themeMode;

  SettingsState copyWith({
    AppLocalePreference? localePreference,
    ThemeMode? themeMode,
  }) {
    return SettingsState(
      localePreference: localePreference ?? this.localePreference,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._prefs) : super(const SettingsState()) {
    _load();
  }

  final SharedPreferences _prefs;

  static const _kLang = 'app_locale_pref';
  static const _kTheme = 'app_theme_mode';

  void _load() {
    final lang = _prefs.getString(_kLang);
    final theme = _prefs.getString(_kTheme);

    emit(
      SettingsState(
        localePreference: _parseLocale(lang),
        themeMode: _parseTheme(theme),
      ),
    );
  }

  static AppLocalePreference _parseLocale(String? v) {
    switch (v) {
      case 'pl':
        return AppLocalePreference.pl;
      case 'en':
        return AppLocalePreference.en;
      default:
        return AppLocalePreference.system;
    }
  }

  static ThemeMode _parseTheme(String? v) {
    for (final m in ThemeMode.values) {
      if (m.name == v) return m;
    }
    return ThemeMode.system;
  }

  Future<void> setLocalePreference(AppLocalePreference value) async {
    await _prefs.setString(_kLang, value.name);
    emit(state.copyWith(localePreference: value));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_kTheme, mode.name);
    emit(state.copyWith(themeMode: mode));
  }
}

/// Gdy [AppLocalePreference.system], zwraca `null` — wtedy [MaterialApp] używa
/// [localeResolutionCallback].
Locale? resolveMaterialLocale(AppLocalePreference preference) {
  switch (preference) {
    case AppLocalePreference.system:
      return null;
    case AppLocalePreference.pl:
      return const Locale('pl');
    case AppLocalePreference.en:
      return const Locale('en');
  }
}
