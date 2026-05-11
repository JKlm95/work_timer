import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:work_timer/bloc/settings_cubit.dart';

/// Klucze muszą być zgodne z [SettingsCubit] (prywatne stałe w cubicie).
const _kLang = 'app_locale_pref';
const _kTheme = 'app_theme_mode';
const _kDebrief = 'app_show_debrief_after_stop';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SettingsCubit: default when prefs empty', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cubit = SettingsCubit(prefs);

    expect(cubit.state.localePreference, AppLocalePreference.system);
    expect(cubit.state.themeMode, ThemeMode.system);
    expect(cubit.state.showDebriefAfterStop, isTrue);

    await cubit.close();
  });

  test('SettingsCubit: setLocalePreference persists', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cubit = SettingsCubit(prefs);

    await cubit.setLocalePreference(AppLocalePreference.pl);
    expect(cubit.state.localePreference, AppLocalePreference.pl);
    expect(prefs.getString(_kLang), 'pl');

    await cubit.close();
  });

  test('SettingsCubit: setThemeMode persists', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cubit = SettingsCubit(prefs);

    await cubit.setThemeMode(ThemeMode.dark);
    expect(cubit.state.themeMode, ThemeMode.dark);
    expect(prefs.getString(_kTheme), 'dark');

    await cubit.close();
  });

  test('SettingsCubit: load from prefs', () async {
    SharedPreferences.setMockInitialValues({_kLang: 'en', _kTheme: 'light'});
    final prefs = await SharedPreferences.getInstance();
    final cubit = SettingsCubit(prefs);

    expect(cubit.state.localePreference, AppLocalePreference.en);
    expect(cubit.state.themeMode, ThemeMode.light);

    await cubit.close();
  });

  test('SettingsCubit: show debrief persists false', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cubit = SettingsCubit(prefs);

    await cubit.setShowDebriefAfterStop(false);
    expect(cubit.state.showDebriefAfterStop, isFalse);
    expect(prefs.getBool(_kDebrief), isFalse);

    await cubit.close();
  });
}
