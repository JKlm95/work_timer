# Work Timer — dokumentacja techniczna

Dokument dla **deweloperów i rekrutera technicznego**: architektura, integracja z Firebase, warstwa natywna Android i strategia danych.

---

## 1. Stack

| Warstwa | Wybór |
|--------|--------|
| Framework | Flutter (Dart 3.x) |
| Stan (globalny) | **flutter_bloc** — `AuthCubit`, `TimerCubit`, **`SettingsCubit`** (język + `ThemeMode`; `SharedPreferences`) |
| Języki UI | **gen-l10n** — `lib/l10n/app_en.arb`, `app_pl.arb`, `l10n.yaml`; delegat **`AppLocalizations`** w `MaterialApp` |
| Motyw | **`AppColors.colorSchemeFor`**, **`buildWorkTimerTheme`** (`lib/theme/app_theme.dart`); jasny i ciemny zestaw powierzchni w **`app_colors.dart`**; typografia **`AppTypography`** |
| Backend | **Firebase Auth** (e-mail/hasło), **Cloud Firestore** |
| Lokalnie | **shared_preferences** (JSON, prefs Flutter + zapis z Kotlina), **home_widget** (Android widget prefs) |
| Sieć / offline | **connectivity_plus** do warunkowania zapytań; kolejka pending |
| Android | **Kotlin** — `ForegroundService`, `AppWidgetProvider` (home_widget), **MethodChannel** `work_timer/service_control` |

---

## 2. Struktura projektu (lib)

```
lib/
├── main.dart                 # Firebase.init, SettingsCubit (prefs), AuthCubit, MaterialApp (theme / darkTheme / themeMode, l10n)
├── bloc/                     # auth_cubit.dart, timer_cubit.dart, settings_cubit.dart
├── l10n/                     # app_*.arb, app_localizations*.dart (generowane), work_mode_strings.dart
├── theme/                    # app_colors.dart, app_theme.dart, app_typography.dart
├── screens/                  # auth_gate (+ splash), home_shell, timer_tab, history_tab, stats_tab, workspaces_tab, settings_tab
├── models/                   # work_entry, workspace, work_mode
├── services/
│   ├── auth_service.dart
│   ├── auth_native_sync.dart      # flaga zalogowania dla Android widget (SharedPreferences)
│   ├── work_repository.dart        # orchestracja cache + Firestore + sync
│   ├── local_cache_store.dart      # prefs: wpisy, workspace, sesja timera
│   ├── firebase_work_store.dart
│   ├── timer_service_bridge.dart   # MethodChannel → serwis Android
│   └── stats_service.dart
└── widgets/
    └── splash_loading_view.dart
```

---

## 3. Przepływ aplikacji po starcie

1. **`main.dart`** — `Firebase.initializeApp`, `SharedPreferences` → **`SettingsCubit`** (outer `BlocProvider`), singletony `AuthService`, `WorkRepository`; **`MaterialApp`** z `theme` / `darkTheme` z `buildWorkTimerTheme`, `themeMode` ze stanu ustawień, delegaty `AppLocalizations`.
2. **`AuthGate`** (stanful):
   - `BlocListener` na `AuthCubit`: przy rozstrzygnięciu sesji Firebase i przy zmianie użytkownika wywołuje **`_onAuthChanged`**.
   - Dla **zalogowanego** użytkownika: tworzy **`TimerCubit`**, **`await init()`** (timeout 15 s), minimalny czas wyświetlania splash (~520 ms), potem **`BlocProvider.value`** + `HomeShell`.
3. **`TimerCubit.init()`** — `initForUser`, załadowanie wpisów miesiąca, hydratacja stanu timera, statystyki, sync do widgetu (Android).

---

## 4. Autentykacja i Firestore

- **Auth:** e-mail/hasło, reset hasła (`AuthService` / Firebase API).
- **Firestore** (wysokopoziomowo):
  - `users/{uid}/entries/{entryId}`
  - `users/{uid}/workspaces/{workspaceId}`
- **Reguły:** `firestore.rules` w repozytorium — wdrożenie przez konsolę lub CLI (`firebase deploy --only firestore:rules` po powiązaniu projektu).

---

## 5. Strategia danych lokalnych vs chmura

- **Pełna historia** w Firestore (powyższe ścieżki).
- **Lokalnie** (`LocalCacheStore`):
  - cache bieżącego miesiąca per workspace,
  - kolejka **pending** dla operacji offline,
  - list workspace’ów i aktywny workspace,
  - migracja legacy `work_entries_v1` → workspace `default` (jednorazowo).
- **Timer session** — JSON w `SharedPreferences` pod kluczem zgodnym z zapisem Kotlin (`flutter.timer_session_v1`), spójny format z `LocalTimerSession`.

---

## 6. Android: widget, serwis, synchronizacja

### 6.1 Foreground service

- `WorkTimerForegroundService` — akcje: `PLAY`, `PAUSE`, `STOP`, `SYNC`.
- **Ticker** co ~1 s aktualizuje stan, notyfikację i widoki widgetu.
- **`persistAndRender`** — zapis do `HomeWidgetPreferences` + JSON sesji do `FlutterSharedPreferences` + **lustro stanu JVM** (`publishMirrorForFlutter`) dla szybkiego odczytu z Fluttera.

### 6.2 MethodChannel

- Kanał: `work_timer/service_control` w **`MainActivity`**.
- Metody: `play`, `pause`, `stop`, `sync`, **`getNativeTimerSnapshot`** (mapa: runState, elapsedSeconds, workspace, sessionMode).
- Flutter: `TimerServiceBridge`.

### 6.3 Spójność Flutter ↔ native

- Przy **`handleSync`** w Kotlinie, po zastosowaniu `elapsedSeconds` w stanie **running**, resetowana jest kotwica czasu (`resumeAtMs`), aby uniknąć rozjazdu z tickiem po wcześniejszym sterowaniu z widgetu.
- Przy wznowieniu aktywności Flutter wywołuje **`syncFromNativeStoresOnResume`**: `reload()` SharedPreferences, hydratacja z **lustra JVM** (priorytet), potem fallback prefs / home_widget.
- **Auth widget:** `auth_native_sync.dart` zapisuje `flutter.auth_signed_in_for_native_v1` (`1`/`0`); `AuthPrefs` w Kotlinie steruje intencjami widgetu (otwarcie aplikacji vs start serwisu).

### 6.4 Widget UI

- `WorkTimerWidgetProvider` — odczyt prefs; przy braku sesji pokazuje stan „zablokowany” i otwiera `MainActivity`.

---

## 7. Splash / bootstrap

- **`SplashLoadingView`** — pełnoekranowy gradient + animacja; wyświetlany przy `AuthCubit.loading` oraz przy zalogowanym użytkowniku do momentu zakończenia `TimerCubit.init`. Teksty tytułu i „ładowanie…” z **l10n**; gradient i warstwy nadal z **`AppColors`** (stały „ekran marki”, nie przełącza się z motywem systemowym — celowo).
- **Android `launch_background`** — kolor spójny z gradientem, ograniczenie białego flasha przed pierwszym frame’m Fluttera (`values/colors.xml`, `drawable/launch_background.xml`).

---

## 7a. Motyw (jasny / ciemny)

- **`AppColors`** — paleta marki + powierzchnie jasne; osobne stałe **`surface*Dark`**, **`borderInputIdleDark`**, **`brandNavIndicatorDark`**; metoda **`colorSchemeFor(Brightness)`** łączy `ColorScheme.fromSeed(brandPrimary)` z tymi warstwami w trybie ciemnym.
- **`buildWorkTimerTheme(brightness)`** (`app_theme.dart`) — `colorScheme`, `textTheme` z **`AppTypography.textTheme`**, `CardTheme`, `InputDecorationTheme`, `FilledButton`, `NavigationBarTheme`, `dividerTheme`, `appBarTheme`.
- **Ustawienia użytkownika** — `SettingsTab` + `SettingsCubit`: `AppLocalePreference` (system / pl / en) oraz `ThemeMode` (light / dark / system), persystencja w `SharedPreferences`.

---

## 7b. Wielojęzyczność (ARB)

- Pliki **`lib/l10n/app_en.arb`** (szablon) i **`app_pl.arb`**; konfiguracja **`l10n.yaml`**; w **`pubspec.yaml`**: `flutter: generate: true`.
- W kodzie: `AppLocalizations.of(context)!` (import `lib/l10n/app_localizations.dart`). Po zmianie ARB: `flutter pub get` lub `flutter gen-l10n` — wygenerowane pliki `app_localizations*.dart` w `lib/l10n/`.
- Tryby pracy (`WorkMode`) — etykiety przez rozszerzenie **`work_mode_strings.dart`**; etykiety **Play / Pause / Stop** tłumaczone jako stałe angielskie w obu locale.

---

## 8. Konfiguracja Firebase (setup deweloperski)

1. Utwórz projekt Firebase i włącz:
   - **Authentication →** E-mail/hasło  
   - **Firestore**
   - Opcjonalnie: szablony e-maili (reset hasła)

2. **FlutterFire CLI:**
   ```bash
   dart pub global activate flutterfire_cli
   dart pub global run flutterfire_cli:flutterfire configure --yes --project=YOUR_PROJECT_ID -o lib/firebase_options.dart --overwrite-firebase-options
   ```
   Na Windows, jeśli `flutterfire` nie jest w PATH, użyj pełnej formy `dart pub global run flutterfire_cli:flutterfire ...`.

3. W repozytorium zwykle commituje się `lib/firebase_options.dart` oraz pliki wygenerowane dla platform (`google-services.json`, `GoogleService-Info.plist`, itd.) i ewentualnie `firebase.json`.

4. **Reguły Firestore:** wgraj `firestore.rules` ( konsola lub `firebase deploy --only firestore:rules` po skonfigurowaniu projektu).

---

## 9. Testy manualne (skrót checklisty)

- Rejestracja, logowanie, reset hasła.
- Workspace: tworzenie, zmiana nazwy, przełączanie; rozdzielenie wpisów.
- Timer online → wpisy w Firestore z poprawnym `workspaceId`.
- Historia: dodaj / edytuj / usuń.
- Statystyki: tydzień/miesiąc, filtry workspace.
- Offline: operacje lokalne → powrót sieci → **syncPending**.
- Reinstalacja → logowanie → dane z chmury.
- **Widget Android:** aktualizacja po zmianach; bez logowania — otwarcie aplikacji zamiast startu timera; po zalogowaniu — pełna obsługa.

---

## 10. Testy automatyczne

W repozytorium znajdują się testy jednostkowe (m.in. migracja wpisów, stats, mapowanie błędów Auth, `SettingsCubit`) — uruchomienie: `flutter test`.

---

## 10a. GitHub Actions (CI)

**Po co:** przy każdym **push** lub **pull requeście** do gałęzi `main` GitHub uruchamia workflow (plik **`.github/workflows/flutter_ci.yml`**) na maszynie w chmurze: `flutter pub get` → **`dart analyze lib test`** → **`flutter test`**. Dzięki temu od razu widać, czy projekt się analizuje i czy testy przechodzą — bez ręcznego odpalania u siebie przed mergem.

Włącz **Actions** w ustawieniach repozytorium (domyślnie w publicznych repach jest OK). Pierwsze uruchomienie po dodaniu workflowa: zakładka **Actions** w GitHubie.

---

## 11. Znane założenia / ograniczenia

- Widget opisany powyżej jest **zaimplementowany pod Android**; iOS/macOS mogą używać innych ścieżek (`TimerServiceBridge` no-op poza Androidem gdzie wskazano).
- Czasy wyświetlane w sekundach mogą różnić się o pojedyncze sekundy w logach Kotlina vs intenty Fluttera (zaokrąglenie sekund w sync).

---

*Ostatnia aktualizacja dokumentu: motywy jasny/ciemny (`AppColors` + `app_theme`), l10n PL/EN (ARB + `SettingsCubit`), zakładka Ustawienia.*
