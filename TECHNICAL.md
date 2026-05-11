# Work Timer — dokumentacja techniczna

Dokument dla **deweloperów i rekrutera technicznego**: architektura, integracja z Firebase, warstwa natywna Android i strategia danych.

---

## 1. Stack

| Warstwa | Wybór |
|--------|--------|
| Framework | Flutter (Dart 3.x) |
| Stan (globalny) | **flutter_bloc** — `AuthCubit`, `TimerCubit`, **`SettingsCubit`** (język, `ThemeMode`, **`showDebriefAfterStop`**; `SharedPreferences`) |
| Języki UI | **gen-l10n** — `lib/l10n/app_en.arb`, `app_pl.arb`, `l10n.yaml`; delegat **`AppLocalizations`** w `MaterialApp` |
| Motyw | **`AppColors.colorSchemeFor`**, **`buildWorkTimerTheme`** (`lib/theme/app_theme.dart`); jasny i ciemny zestaw powierzchni w **`app_colors.dart`**; typografia **`AppTypography`** |
| Backend | **Firebase Auth** (e-mail/hasło), **Cloud Firestore** |
| Lokalnie | **shared_preferences** (JSON, prefs Flutter + zapis z Kotlina), **home_widget** (Android widget prefs); **`file_picker`** (zapis CSV/PDF na dysku), **`path_provider`** (katalog tymczasowy przed `share_plus`) |
| Kalendarz UI | **`table_calendar`** + `intl` `initializeDateFormatting` w `main` (`en_US`, `pl_PL`) |
| Sieć / offline | **connectivity_plus** do warunkowania zapytań; kolejka pending |
| Android | **Kotlin** — `ForegroundService`, `AppWidgetProvider` (home_widget), **MethodChannel** `work_timer/service_control` |
| iOS | **Swift** — `AppDelegate` + **WidgetKit** + **App Groups** (`UserDefaults`), te same nazwy metod MethodChannel co na Androidzie; brak ForegroundService (timer = Flutter + cache) |

---

## 2. Struktura projektu (lib)

```
lib/
├── main.dart                 # Firebase.init, SettingsCubit (prefs), AuthCubit, MaterialApp (theme / darkTheme / themeMode, l10n)
├── bloc/                     # auth_cubit.dart, timer_cubit.dart, settings_cubit.dart
├── l10n/                     # app_*.arb, app_localizations*.dart (generowane), work_mode_strings.dart
├── theme/                    # app_colors.dart, app_theme.dart, app_typography.dart
├── screens/                  # auth_gate (+ splash), home_shell, timer_tab, history_tab, stats_tab, calendar_tab, workspaces_tab, settings_tab
├── models/                   # work_entry, workspace, work_mode, entry_type, billing_currency
├── utils/                    # m.in. workspace_color, project_field_utils, export_save.dart (CSV/PDF zapis mobilny SAF)
├── export/                   # work_entries_csv.dart (CSV / Excel), work_entries_pdf.dart (PDF A4 poziom, Noto Sans z assets)
├── services/
│   ├── auth_service.dart
│   ├── auth_native_sync.dart      # flaga zalogowania — Android widget; iOS reload widgetów
│   ├── ios_deep_link_nav.dart      # worktimer:// → zakładka (iOS)
│   ├── work_repository.dart        # orchestracja cache + merge miesiąca + kolejki pending
│   ├── work_remote_store.dart      # abstrakcja Firestore (testy: FakeWorkRemoteStore)
│   ├── online_checker.dart         # abstrakcja sieci (testy: FixedOnlineChecker)
│   ├── local_cache_store.dart      # prefs: wpisy, workspace, sesja; kolejka upsert workspace (offline)
│   ├── firebase_work_store.dart
│   ├── timer_service_bridge.dart   # MethodChannel Android + iOS (App Group / reload)
│   └── stats_service.dart
└── widgets/
    ├── splash_loading_view.dart
    ├── project_editor_sheet.dart    # formularz projektu (bottom sheet)
    └── stop_session_debrief_dialog.dart
```

---

## 3. Przepływ aplikacji po starcie

1. **`main.dart`** — `Firebase.initializeApp`, `SharedPreferences` → **`SettingsCubit`** (outer `BlocProvider`), singletony `AuthService`, `WorkRepository`; **`MaterialApp`** z `theme` / `darkTheme` z `buildWorkTimerTheme`, `themeMode` ze stanu ustawień, delegaty `AppLocalizations`.
2. **`AuthGate`** (stanful):
   - `BlocListener` na `AuthCubit`: przy rozstrzygnięciu sesji Firebase i przy zmianie użytkownika wywołuje **`_onAuthChanged`**.
   - Dla **zalogowanego** użytkownika: tworzy **`TimerCubit`**, **`await init()`** (timeout 15 s), minimalny czas wyświetlania splash (~520 ms), potem **`BlocProvider.value`** + `HomeShell`.
3. **`TimerCubit.init()`** — `reload()` prefs (Android po zapisie z Kotlina), `initForUser`, pierwszy `emit` z **workspaces**, **`await _hydrateTimerFromPersistedStores()`** (Android: lustro JVM + **`_alignRepositoryWithWorkspaceIfPossible`**; iOS/web: prefs/`home_widget` jak w tej metodzie — **zanim** pierwszy **`loadEntriesForRange`**), **`emit`** z wpisami z **`loadEntriesForRange`**, **`_applyAndroidWorkspaceSelectionIfIdle`**, **`refreshStatsEntries`**, **`_writeWidgetSnapshot`**.

---

## 4. Autentykacja i Firestore

- **Auth:** e-mail/hasło, reset hasła (`AuthService` / Firebase API).
- **Firestore** (wysokopoziomowo):
  - `users/{uid}/entries/{entryId}`
  - `users/{uid}/workspaces/{workspaceId}`
- **Reguły:** plik **`firestore.rules`** w repozytorium — **wdroż całość** (konsola lub `firebase deploy --only firestore:rules`). Reguły muszą obejmować **obie** podkolekcje (`entries` **i** `workspaces`). Same reguły tylko dla `entries` skutkują **`permission-denied`** przy zapisie/odczycie workspace’ów i po reinstalacji „znikały” workspace’y w chmurze.

---

## 5. Strategia danych lokalnych vs chmura

- **Pełna historia** w Firestore (powyższe ścieżki).
- **Lokalnie** (`LocalCacheStore`):
  - cache bieżącego miesiąca per workspace,
  - kolejka **pending** wpisów (`work_entries_pending_v2`) oraz przy offline/błędzie sieci kolejka **`upsertWorkspace`** (`workspaces_remote_pending_v1`),
  - list workspace’ów i aktywny workspace,
  - migracja legacy `work_entries_v1` → workspace `default` (jednorazowo).
- **Merge przy online:** dla zakresu „bieżący miesiąc” wynik Firestore jest scalany z lokalnym cache miesiąca (uniknięcie „znikania” świeżych wpisów przed sync).
- **Workspace w Firestore:** `FirebaseWorkStore.fetchWorkspaces` pobiera **całą** kolekcję (również zarchiwizowane dokumenty) i zwraca listę dla merge w repozytorium; **filtrowanie** „aktywnych” vs archiwum odbywa się w UI (`TimerTab`, `WorkspacesTab`). Dokumenty bez pola `isArchived` nadal działają; pojedynczy uszkodzony dokument nie przerywa importu.
- **Aktywny projekt przy archiwum:** po wczytaniu stanu lub zapisie projektu `WorkRepository` stara się ustawić aktywny kontekst na pierwszy **niezarchiwizowany** (best effort).
- **Timer session** — JSON w `SharedPreferences` pod kluczem zgodnym z zapisem Kotlin (`flutter.timer_session_v1`), spójny format z `LocalTimerSession`.

---

## 6. Android: widget, serwis, synchronizacja

**Przepływ danych (widget, jedna linia):**  
`Flutter` → `TimerServiceBridge` (**MethodChannel** `work_timer/service_control`) → **Kotlin** `WorkTimerForegroundService` → **SharedPreferences** (Flutter prefs + `home_widget`) → aktualizacja **AppWidgetProvider** / widoku na launcherze.

### 6.1 Foreground service

- `WorkTimerForegroundService` — akcje: `PLAY`, `PAUSE`, `STOP`, `SYNC`, `PREVIOUS_WORKSPACE`, `NEXT_WORKSPACE`.
- **Ticker** co ~1 s aktualizuje stan, notyfikację i widoki widgetu.
- **`persistAndRender`** — zapis do `HomeWidgetPreferences` + JSON sesji do `FlutterSharedPreferences` + **lustro stanu JVM** (`publishMirrorForFlutter`) dla szybkiego odczytu z Fluttera.

### 6.2 MethodChannel

- Kanał: `work_timer/service_control` w **`MainActivity`**.
- Metody: `play`, `pause`, `stop`, `sync`, **`getNativeTimerSnapshot`**, **`syncWidgetWorkspaces`**, **`getWidgetWorkspaceSelection`** (mapa: activeWorkspaceId, workspaceName).
- Flutter: `TimerServiceBridge`.

### 6.3 Spójność Flutter ↔ native

- Przy **`handleSync`** w Kotlinie, po zastosowaniu `elapsedSeconds` w stanie **running**, resetowana jest kotwica czasu (`resumeAtMs`), aby uniknąć rozjazdu z tickiem po wcześniejszym sterowaniu z widgetu.
- Przy wznowieniu aktywności Flutter wywołuje **`syncFromNativeStoresOnResume`**: `reload()` SharedPreferences, hydratacja z **lustra JVM** (priorytet), wyrównanie **`WorkRepository.activeWorkspaceId`** przy ID z lustra (żeby cache miesiąca/kolejki czytać ten sam **`workspaceId`**, który przy **STOP** zapisuje Kotlin), **`loadEntries` dla bieżącego zakresu** gdy przełączenie z widgetu już zsynchronizowane, potem refresh statów — patrz **`TimerCubit.syncFromNativeStoresOnResume`**; fallback prefs / home_widget w ścieżce bez lustra.
- **Auth widget:** `auth_native_sync.dart` zapisuje `flutter.auth_signed_in_for_native_v1` (`1`/`0`); `AuthPrefs` w Kotlinie steruje intencjami widgetu (otwarcie aplikacji vs start serwisu).

### 6.4 Widget UI

- `WorkTimerWidgetProvider` — odczyt prefs; przy braku sesji pokazuje stan „zablokowany” i otwiera `MainActivity`.
- **`WorkTimerWidgetUi`** — wspólne budowanie `RemoteViews` dla providera i serwisu (nagłówek z ‹/›, status, timer, kontrolki).

### 6.5 Widget — przełączanie workspace (tylko przy idle)

- **Źródło listy:** Flutter zapisuje JSON workspace’ów (`id` + `name`) w **`HomeWidgetPreferences`** pod kluczem `widget_workspaces_json` oraz aktualny wybór (`activeWorkspaceId`, `workspaceName`) metodą MethodChannel **`syncWidgetWorkspaces`** (`TimerServiceBridge`), wywoływaną przed każdym `sync` timera w **`TimerCubit._writeWidgetSnapshot`**.
- **Przełączanie ‹/›:** intencje **`ACTION_PREVIOUS_WORKSPACE`** / **`ACTION_NEXT_WORKSPACE`** → `WorkTimerForegroundService`. Jeśli w prefs `runState` to `running` lub `paused`, indeks się nie zmienia — tylko odświeżenie widoku. Przy `idle` następuje cykliczna zmiana indeksu po lokalnej liście i zapis `activeWorkspaceId` / `workspaceName`.
- **Flutter:** przy starcie i przy **`syncFromNativeStoresOnResume`** metoda **`getWidgetWorkspaceSelection`** — jeśli timer jest **idle** i ID z Androida występuje w załadowanej liście repo, wywoływane jest **`setActiveWorkspace`** (bez zmiany kolejki Firebase z poziomu widgetu).

### 6.6 iOS (WidgetKit, App Groups, różnice względem Androida)

- **Brak ForegroundService** — timer żyje w **Flutter + `LocalCacheStore`**; stan oparty o **`sessionStart` / `resumeAt` / `accumulated`** (timestampy), a nie o tick w tle na iOS.
- **MethodChannel** `work_timer/service_control` w **`AppDelegate.swift`**: `sync`, `syncWidgetWorkspaces`, `play`/`pause`/`stop` (no-op + odświeżenie timeline), `getNativeTimerSnapshot` (lustro z App Group), `getWidgetWorkspaceSelection`, `reloadWidgets`.
- **App Group** (to samo ID w Runner i w rozszerzeniu): `group.com.worktimer.workTimer`; zapis przez **`UserDefaults(suiteName:)`** — klucze `wt_*` (m.in. `wt_runState`, `wt_selectedWorkspaceId`, `wt_startTimestampMs`, `wt_elapsedSeconds`, `wt_pausedAccumulatedSeconds`, `wt_resumeAtMs`, `wt_workspacesJson`, `wt_lastUpdatedAtMs`).
- **WidgetKit:** kod źródłowy w **`ios/WorkTimerWidgetExtension/`** (`WorkTimerWidget.swift`, `Info.plist`, `WorkTimerWidgetExtension.entitlements`). W Xcode trzeba **dodać target Widget Extension**, wskazać te pliki, ustawić **App Groups** jak w Runner, osadzić appex (Embed Foundation Extensions). Repozytorium dostarcza kod — pełna konfiguracja targetu jest po stronie Xcode (Team / podpisy).
- **Deep link** `worktimer://` — w **`Info.plist`** Runnera; **`IosDeepLinkNav`** + kanał `work_timer/deeplink` (`onOpenUrl`). Indeks zakładki z deep linku jest **obcinany do zakresu 0…5** (kolejność w `HomeShell`: Timer, Historia, Statystyki, Kalendarz, Projekty, Ustawienia); historyczny adres `…/workspaces` mapuje się na zakładkę **Projekty** (indeks **4**).
- **Throttle:** `TimerCubit` wysyła pełny `sync` do iOS co **~15 s** podczas `running`, żeby nie obciążać bridge co sekundę; przy zdarzeniach dyskretnych (`play`/`pause`/`stop`/zmiana workspace) synchronizacja jest natychmiastowa.
- **Widget iOS:** podgląd — workspace, status (Idle / Running / Paused), czas (dla `running` liczony z `resumeAt` + `pausedAccumulatedSeconds` w Swift). Tap na nazwie workspace → `worktimer://workspaces`. Sterowanie timera z widgetu **App Intents** nie jest wymagane na tym etapie (można dodać później z zapisem do App Group + `WidgetCenter.reloadAllTimelines()`).

---

## 7. Splash / bootstrap

- **`SplashLoadingView`** — pełnoekranowy gradient + animacja; wyświetlany przy `AuthCubit.loading` oraz przy zalogowanym użytkowniku do momentu zakończenia `TimerCubit.init`. Teksty tytułu i „ładowanie…” z **l10n**; gradient i warstwy nadal z **`AppColors`** (stały „ekran marki”, nie przełącza się z motywem systemowym — celowo).
- **Android `launch_background`** — kolor spójny z gradientem, ograniczenie białego flasha przed pierwszym frame’m Fluttera (`values/colors.xml`, `drawable/launch_background.xml`).

---

## 7a. Motyw (jasny / ciemny)

- **`AppColors`** — paleta marki + powierzchnie jasne; osobne stałe **`surface*Dark`**, **`borderInputIdleDark`**, **`brandNavIndicatorDark`**; metoda **`colorSchemeFor(Brightness)`** łączy `ColorScheme.fromSeed(brandPrimary)` z tymi warstwami w trybie ciemnym.
- **`buildWorkTimerTheme(brightness)`** (`app_theme.dart`) — `colorScheme`, `textTheme` z **`AppTypography.textTheme`**, `CardTheme`, `InputDecorationTheme`, `FilledButton`, `NavigationBarTheme`, `dividerTheme`, `appBarTheme`.
- **Ustawienia użytkownika** — `SettingsTab` + `SettingsCubit`: `AppLocalePreference` (system / pl / en), `ThemeMode` (light / dark / system), **`showDebriefAfterStop`** (dialog podsumowania po zatrzymaniu timera); persystencja w `SharedPreferences`.

---

## 7b. Wielojęzyczność (ARB)

- Pliki **`lib/l10n/app_en.arb`** (szablon) i **`app_pl.arb`**; konfiguracja **`l10n.yaml`**; w **`pubspec.yaml`**: `flutter: generate: true`.
- W kodzie: `AppLocalizations.of(context)!` (import `lib/l10n/app_localizations.dart`). Po zmianie ARB: `flutter pub get` lub `flutter gen-l10n` — wygenerowane pliki `app_localizations*.dart` w `lib/l10n/`.
- Tryby pracy (`WorkMode`) — etykiety przez rozszerzenie **`work_mode_strings.dart`**; etykiety **Play / Pause / Stop** tłumaczone jako stałe angielskie w obu locale.

---

## 7c. Statystyki (`StatsTab`)

- **`refreshStatsEntries`** (domyślnie) ładuje wpisy od **wcześniejszej** z dat: pierwszy dzień bieżącego miesiąca **albo** poniedziałek tygodnia ISO (`weekStartMonday`). Dzięki temu przy początku miesiąca wykres „Podsumowanie tygodnia” ma dane także z dni leżących w poprzednim miesiąku, ale w tym samym tygodniu kalendarzowym.
- Kafelki **„Ten miesiąc”**, liczba sesji i średnia liczą tylko wpisy z **bieżącego miesiąca kalendarzowego** (niezależnie od rozszerzonego zakresu pobrania).
- **Wykres słupkowy:** kubełki z `weekDayDurations` / suma z `entriesInCurrentWeek`; rysowanie przez **`LayoutBuilder` + `SizedBox`** (jawna wysokość słupka) — unika niewidocznych słupków przy starszym wzorcu `FractionallySizedBox` + `DecoratedBox` bez dziecka.
- **Rozliczenia (szacunek):** `StatsService.buildBillingEstimate` — sumy czasu z `WorkEntry.isBillable` vs brak flagi; kwoty tylko dla wpisów typu **praca** + billable + dodatnia stawka w `Workspace`, **grupowanie po kodzie waluty** (brak przeliczania między walutami). UI: kafelki + lista linii per waluta.

---

## 7d. Kalendarz (`CalendarTab`)

- Źródło danych: **`TimerCubit.statsEntries`** po **`refreshStatsEntries`** z zakresem **od pierwszego do ostatniego dnia wyświetlanego miesiąca** (przy zmianie strony kalendarza).
- Markery dni: kropki w kolorze projektu (`Workspace.colorHex` → `workspaceAccentColor`).
- Szczegóły wpisów pod wybranym dniem: czas trwania, przedział godzin, etykieta projektu (l10n).

---

## 7e. Eksport CSV / PDF (`HistoryTab`, `ProjectReportScreen`)

- **Sortowanie w UI eksportu / listy Historii:** po filtrach zakres i trybu — kolejność **malejąca po polu `start`** (najpierw najnowsza sesja), spójna dla widoku listy oraz CSV/PDF.
- **CSV:** **`workEntriesToCsv`** (`lib/export/work_entries_csv.dart`) — BOM UTF-8, separator `;` dla locale `pl`, `,` w pozostałych; kolumny m.in. `entryType`, `isBillable`, `taskTitle`, `note`.
- **PDF:** **`buildWorkEntriesPdfDocument`** (`lib/export/work_entries_pdf.dart`) — pakiet **`pdf`**, format A4 poziom, tabela z nagłówkami; **osadzona czcionka** **`assets/fonts/NotoSans-Regular.ttf`** (Google Noto Sans OFL) dla poprawnego **UTF-8 / polskich znaków**.
- **Udostępnianie (`share`):** zapis tymczasowy w **`getTemporaryDirectory`**, **`SharePlus`** (CSV: `text/csv`, PDF: `application/pdf`).
- **Zapis lokalny:** **`saveExportWithPicker`** w **`lib/utils/export_save.dart`** — na **Androidzie / iOS** przekazywane są **bajty** do **`FilePicker.platform.saveFile`** (wymóg `file_picker`; zapis przez SAF / document picker na URI), na **desktop** dialog ścieżki potem **`dart:io` `File.writeAs…`**; na **web** komunikat zachęcający do udostępniania.
- **UI:** menu (**`PopupMenuButton`**) w Historii; raport projektu — analogicznie.

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

4. **iOS — `GoogleService-Info.plist`:** jeśli w **`ios/Runner/`** nie ma tego pliku, dodaj aplikację iOS w **Firebase Console**, pobierz plist i umieść go w Runnerze, potem `flutterfire configure` (lub ręcznie). Bez tego `Firebase.initializeApp` na urządzeniu iOS może się nie powieść — **nie commituj** fikcyjnego pliku.

5. **Reguły Firestore:** wgraj **pełny** plik `firestore.rules` z repozytorium — musi zawierać reguły dla **`users/{uid}/workspaces/{...}`** oraz **`users/{uid}/entries/{...}`** (patrz § 4). Sam „allow” tylko na `entries` w konsoli blokuje workspace’y w produkcji.

---

## 9. Testy manualne (skrót checklisty)

- Rejestracja, logowanie, reset hasła.
- Projekty: tworzenie / edycja / archiwum; przełączanie; rozdzielenie wpisów; timer nie startuje na zarchiwizowanym projekcie.
- Timer online → wpisy w Firestore z poprawnym `workspaceId`.
- Historia: dodaj / edytuj / usuń; typ wpisu, eksport CSV i PDF (udostępnianie + zapis lokalny tam, gdzie wspiera platforma).
- Statystyki: tydzień/miesiąc, filtry projektów, blok rozliczeń.
- Kalendarz: zmiana miesiąca, wybór dnia.
- Offline: operacje lokalne → powrót sieci → **syncPending**.
- Reinstalacja → logowanie → dane z chmury.
- **Widget Android:** aktualizacja po zmianach; bez logowania — otwarcie aplikacji zamiast startu timera; po zalogowaniu — pełna obsługa.

---

## 10. Testy automatyczne

W repozytorium znajdują się testy jednostkowe (m.in. migracja wpisów, **StatsService** w tym **`buildBillingEstimate`**, **WorkRepository** / kolejka `syncPending` z fałszywym `WorkRemoteStore` + `OnlineChecker`, **TimerCubit** play/pause/stop na mockowanym repozytorium, eksport **CSV** `workEntriesToCsv` (nagłówek z nowymi kolumnami), mapowanie błędów Auth, **`SettingsCubit`** w tym **debrief**) — uruchomienie: `flutter test`. **PDF** (`buildWorkEntriesPdfDocument`, pakiet **`pdf`**) nie ma osobnego testu jednostkowego; weryfikacja ręczna z menu eksportu w **Historii**.

---

## 10a. GitHub Actions (CI)

**Po co:** przy każdym **push** lub **pull requeście** do gałęzi `main` GitHub uruchamia workflow (plik **`.github/workflows/flutter_ci.yml`**) na maszynie w chmurze: `flutter pub get` → **`dart format --set-exit-if-changed .`** → **`flutter analyze --no-fatal-infos`** → **`flutter test`** → **`flutter build apk --debug`** (z przygotowaniem JDK 17 i Android SDK na runnerze). Dzięki temu widać, czy format, analiza, testy i build przechodzą bez uruchamiania lokalnie przed mergem.

**Build iOS** na **Ubuntu** w CI nie jest uruchamiany (wymaga **macOS** i Xcode). Opcjonalny job `macos-latest` + `flutter build ios` można dodać dopiero przy kompletnej konfiguracji certyfikatów i `GoogleService-Info.plist`.

Włącz **Actions** w ustawieniach repozytorium (domyślnie w publicznych repach jest OK). Pierwsze uruchomienie po dodaniu workflowa: zakładka **Actions** w GitHubie.

---

## 11. Znane założenia / ograniczenia

- **Android:** widget + ForegroundService jak w § 6. **iOS:** timestampy + **WidgetKit** + App Group (§ 6.6) — zachowanie w tle **nie** jest jak pełny serwis pierwszoplanowy na Androidzie.
- **macOS / desktop:** `TimerServiceBridge` nie wywołuje natywnego widgetu iOS/Android; opcjonalnie **`home_widget`** w ścieżce „innej niż Android/iOS” w **`TimerCubit`** (zgodnie z kodem).
- Czasy wyświetlane w sekundach mogą różnić się o pojedyncze sekundy w logach Kotlina vs intenty Fluttera (zaokrąglenie sekund w sync).
- **Timer:** po **`stop`** w **`TimerCubit`** odświeżenie **`statsEntries`** jest **wysyłane w tle** (`unawaited(refreshStatsEntries …))`, żeby UI nie blokowało na syncu Firestore; wpis nadal dopisywany lokalnie od razu.
- **Modele Firestore:** wpisy i projekty mogą zawierać **dodatkowe opcjonalne pola** (task, notatka, typ wpisu, billable, stawka, waluta itd.) — reguły w **`firestore.rules`** weryfikują minimalny zestaw wymaganych kluczy; merge zapisu używa **`SetOptions(merge: true)`** tam, gdzie implementacja na to pozwala.

---

*Ostatnia aktualizacja dokumentu: sortowanie Historii malejąco po `start`, `export_save` / SAF dla zapisu plików, `TimerCubit.init`/resume — hydratacja i wyrównanie aktywnego workspace z lustrem/widgetem przed pierwszym odczytem cache (§ 3, § 6.3, § 7e, § 11).*
