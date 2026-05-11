import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLocalePreference { system, pl, en }

class SettingsState {
  const SettingsState({
    this.localePreference = AppLocalePreference.system,
    this.themeMode = ThemeMode.system,
    this.showDebriefAfterStop = true,
  });

  final AppLocalePreference localePreference;
  final ThemeMode themeMode;

  /// Dialog po zatrzymaniu timera (zadanie / notatka / billable).
  final bool showDebriefAfterStop;

  SettingsState copyWith({
    AppLocalePreference? localePreference,
    ThemeMode? themeMode,
    bool? showDebriefAfterStop,
  }) {
    return SettingsState(
      localePreference: localePreference ?? this.localePreference,
      themeMode: themeMode ?? this.themeMode,
      showDebriefAfterStop: showDebriefAfterStop ?? this.showDebriefAfterStop,
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
  static const _kDebrief = 'app_show_debrief_after_stop';

  void _load() {
    final lang = _prefs.getString(_kLang);
    final theme = _prefs.getString(_kTheme);
    final debrief = _prefs.getBool(_kDebrief);

    emit(
      SettingsState(
        localePreference: _parseLocale(lang),
        themeMode: _parseTheme(theme),
        showDebriefAfterStop: debrief ?? true,
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

  Future<void> setShowDebriefAfterStop(bool value) async {
    await _prefs.setBool(_kDebrief, value);
    emit(state.copyWith(showDebriefAfterStop: value));
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
