# Work Timer — dokumentacja techniczna

Dokument dla **deweloperów** utrzymujących aplikację mobilną: architektura `lib/`, integracja z **Firebase**, most do widgetów (**Android** / **iOS**), strategia danych lokalnych vs Firestore oraz zależności od **`firestore.rules`**. Kontrakt ścieżek z panelem pracodawcy: **[DATA_CONTRACT.md](DATA_CONTRACT.md)**.

---

## 1. Architektura katalogów i stos techniczny

### 1.1. Tabela stacku

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
| Zgody prawne | **`LegalConsentRepository`** + ekran **`LegalConsentScreen`**; linki **`url_launcher`**; wersje w `lib/config/legal_versions.dart`, URL w `lib/config/legal_links.dart` |
| Android | **Kotlin** — `ForegroundService`, `AppWidgetProvider` (home_widget), **MethodChannel** `work_timer/service_control` |
| iOS | **Swift** — `AppDelegate` + **WidgetKit** + **App Groups** (`UserDefaults`), te same nazwy metod MethodChannel co na Androidzie; brak ForegroundService (timer = Flutter + cache) |

### 1.2. Struktura `lib/`

```
lib/
├── main.dart                 # Firebase.init, SettingsCubit (prefs), AuthCubit, MaterialApp (theme / darkTheme / themeMode, l10n)
├── bloc/                     # auth_cubit.dart, timer_cubit.dart, settings_cubit.dart, user_profile_cubit.dart
├── l10n/                     # app_*.arb, app_localizations*.dart (generowane), work_mode_strings.dart
├── theme/                    # app_colors.dart, app_theme.dart, app_typography.dart, app_layout.dart (radius, touch targets)
├── screens/                  # auth_gate (+ splash + legal consent gate), legal_consent_screen, home_shell, timer_tab, …
├── models/                   # work_entry, workspace, work_mode, entry_type, billing_currency
├── utils/                    # m.in. workspace_color, project_field_utils, workspace_firestore_write, export_save.dart
├── export/                   # work_entries_csv.dart (CSV / Excel), work_entries_pdf.dart (PDF A4 poziom, Noto Sans z assets)
├── services/
│   ├── auth_service.dart
│   ├── employee_work_email_index_service.dart  # employeeWorkEmailIndex — lookup po służbowym e-mailu
│   ├── auth_native_sync.dart      # flaga zalogowania — Android widget; iOS reload widgetów
│   ├── ios_deep_link_nav.dart      # worktimer:// → zakładka (iOS)
│   ├── work_repository.dart        # orchestracja cache + merge miesiąca + kolejki pending
│   ├── work_remote_store.dart      # abstrakcja Firestore (testy: FakeWorkRemoteStore)
│   ├── online_checker.dart         # abstrakcja sieci (testy: FixedOnlineChecker)
│   ├── local_cache_store.dart      # prefs: wpisy, workspace, sesja; kolejka upsert workspace (offline)
│   ├── firebase_work_store.dart
│   ├── legal_consent_repository.dart  # users/{uid}/legal/consents — gate przed TimerCubit
│   ├── live_status_service.dart     # zapis users/{uid}/live/status (panel)
│   ├── live_status_sync_plan.dart   # czyste mapowanie TimerState → pola live (testowalne)
│   ├── live_status_app_binding.dart # lifecycle → isOnline w serwisie
│   ├── timer_service_bridge.dart   # MethodChannel Android + iOS (App Group / reload)
│   └── stats_service.dart
└── widgets/
    ├── splash_loading_view.dart
    ├── project_editor_sheet.dart    # formularz projektu (bottom sheet)
    ├── stop_session_debrief_dialog.dart
    └── ui/                          # wspólne komponenty UI
        ├── app_empty_state.dart
        ├── app_section_header.dart
        └── entry_meta_chips.dart
```

---

## 2. Warstwy aplikacji (od UI do Firestore)

- **Prezentacja:** `screens/*`, `widgets/*` — Material 3, nawigacja w `HomeShell`, zakładki Timer / Historia / Statystyki / Kalendarz / Projekty / Ustawienia.
- **Stan ekranów:** Cubity w `bloc/` — `TimerCubit` agreguje sesję, wpisy w zakresie, workspace’y, statystyki; `AuthCubit` sesja Firebase; `SettingsCubit` preferencje UI.
- **Serwisy domenowe:** `WorkRepository` jednym wejściem do zapisu wpisów i projektów (cache + remote + kolejka); `LiveStatusService` utrzymuje dokument live; `EmployeeWorkEmailIndexService` + wywołania z repozytorium utrzymują indeks służbowych maili; `LegalConsentRepository` gate prawny; `UserProfileRepository` / indeks e-mail konta.
- **Warstwa zdalna:** `FirebaseWorkStore` implementuje `WorkRemoteStore` (Firestore); reguły bezpieczeństwa muszą być zgodne z **[§ 12](#12-reguły-firestore--założenia-dla-tej-aplikacji)**.
- **Warstwa lokalna:** `LocalCacheStore` — JSON w `SharedPreferences` (wpisy miesiąca, lista workspace’ów, sesja timera, kolejki).

### 2.1. Splash i bootstrap

- **`SplashLoadingView`** — pełnoekranowy gradient + animacja; przy `AuthCubit.loading` oraz do zakończenia `TimerCubit.init` po zalogowaniu. Teksty z **l10n**; gradient z **`AppColors`** (stały ekran marki).
- **Android `launch_background`** — kolor spójny z gradientem (`values/colors.xml`, `drawable/launch_background.xml`), ograniczenie białego flasha przed pierwszym frame’m Fluttera.

### 2.2. Motyw (jasny / ciemny)

- **`AppColors`** — paleta marki + powierzchnie jasne; stałe **`surface*Dark`**, **`borderInputIdleDark`**, **`brandNavIndicatorDark`**; **`colorSchemeFor(Brightness)`** łączy `ColorScheme.fromSeed(brandPrimary)` z warstwami w trybie ciemnym.
- **`buildWorkTimerTheme(brightness)`** — `colorScheme`, `textTheme` z **`AppTypography.textTheme`**, `CardTheme`, `InputDecorationTheme`, `FilledButton`, `NavigationBarTheme`, `dividerTheme`, `appBarTheme`.
- **Ustawienia:** `SettingsTab` + `SettingsCubit`: locale (system / pl / en), `ThemeMode`, **`showDebriefAfterStop`**.

### 2.3. Wielojęzyczność (ARB)

- **`lib/l10n/app_en.arb`** (szablon), **`app_pl.arb`**, **`l10n.yaml`**; w `pubspec.yaml`: `flutter: generate: true`.
- W kodzie: `AppLocalizations.of(context)!`. Po zmianie ARB: `flutter pub get` lub `flutter gen-l10n`.
- Tryby pracy — etykiety w **`work_mode_strings.dart`**; etykiety Play / Pause / Stop jako stałe angielskie w obu locale (świadomy wybór w kodzie).

### 2.4. Statystyki (`StatsTab`)

- **`refreshStatsEntries`** ładuje od wcześniejszej z dat: pierwszy dzień bieżącego miesiąca **albo** poniedziałek tygodnia ISO — żeby wykres tygodnia miał dane z sąsiedniego miesiąca w tym samym tygodniu kalendarzowym.
- Kafelki „Ten miesiąc” i średnie liczą tylko wpisy z **bieżącego miesiąca kalendarzowego**.
- Wykres słupkowy: `LayoutBuilder` + `SizedBox` (jawna wysokość słupka).
- **Rozliczenia:** `StatsService.buildBillingEstimate` — `isBillable`, typ pracy, stawka w `Workspace`, **grupowanie po walucie** (brak przeliczania między walutami).

### 2.5. Kalendarz (`CalendarTab`)

- Źródło: **`TimerCubit.statsEntries`** po **`refreshStatsEntries`** dla zakresu pierwszy–ostatni dzień wyświetlanego miesiąca.
- Markery: kolor z `Workspace.colorHex` → `workspaceAccentColor`.

### 2.6. Eksport CSV / PDF (`HistoryTab`, raport projektu)

- Sortowanie listy / eksportu: **malejąco po `start`**.
- **CSV:** `workEntriesToCsv` — BOM UTF-8, separator `;` (pl) / `,` (inne locale); kolumny m.in. `entryType`, `isBillable`, `taskTitle`, `note`.
- **PDF:** `buildWorkEntriesPdfDocument` — pakiet **`pdf`**, A4 poziom, czcionka **`assets/fonts/NotoSans-Regular.ttf`** (UTF-8 / PL).
- **Udostępnianie:** `getTemporaryDirectory` + **`share_plus`**.
- **Zapis lokalny:** **`saveExportWithPicker`** (`export_save.dart`) — Android/iOS: bajty przez `file_picker`; desktop: ścieżka z dialogu; web: komunikat zachęcający do share.

---

## 3. Przepływ aplikacji i Auth

1. **`main.dart`** — `Firebase.initializeApp`, `SharedPreferences` → **`SettingsCubit`**, singletony `AuthService`, `WorkRepository`; **`MaterialApp`** z motywem i delegatami l10n.
2. **`AuthGate`** (StatefulWidget):
   - `BlocListener` na `AuthCubit` — przy zmianie użytkownika **`_onAuthChanged`** (m.in. unmount `TimerCubit`).
   - Dla **zalogowanego**: najpierw **`LegalConsentRepository.checkGate`** na `users/{uid}/legal/consents`. Jeśli brak lub nieważne zgody → **`LegalConsentScreen`**. Po sukcesie → **`TimerCubit`**, **`await init()`** (timeout 15 s), minimalny czas splash (~520 ms), potem **`HomeShell`**.
   - Przy błędzie odczytu zgód offline — Retry / wyloguj (bez pętli nawigacji).
3. **Auth:** e-mail/hasło, reset hasła (`AuthService`). **`userEmailIndex/{emailLower}`** aktualizowany przy logowaniu i zapisie profilu (`UserEmailIndexService`).

---

## 4. Legal consent flow

- **Ścieżka:** `users/{uid}/legal/consents` (dokument id `consents`).
- **Gate:** bez poprawnego dokumentu użytkownik **nie** dostaje `TimerCubit` / `HomeShell`.
- **Zapis:** `LegalConsentRepository.saveAcceptance` — wersje z `lib/config/legal_versions.dart`; opcjonalnie `acceptedPlatform` z `defaultTargetPlatform` / web.
- **Walidacja klienta:** `LegalConsentRecord.tryParse` — brak wymaganych pól lub `false` na zgodach → ponowny ekran.
- **Reguły:** `hasValidLegalConsentsShape` w `firestore.rules` — tylko owner `{uid}`; `delete` zabronione. Szczegół pól: **[DATA_CONTRACT.md](DATA_CONTRACT.md)**.

---

## 5. Firestore — kolekcje i dokumenty (mobile + współdzielenie z panelem)

| Ścieżka | Rola |
|---------|------|
| `users/{uid}/entries/{entryId}` | Historia sesji i wpisów ręcznych — **źródło prawdy** czasu; mobile + (reguły) panel. |
| `users/{uid}/workspaces/{workspaceId}` | Projekty: nazwa, kolor, archiwum, stawka, udostępnienie, pola firmy / work email. |
| `users/{uid}/live/status` | **Podgląd realtime** timera / online dla panelu — **nie** zastępuje `entries`. |
| `users/{uid}/profile/main` | Profil globalny (imię, nazwisko, e-mail w UI). |
| `users/{uid}/legal/consents` | Zgody ToS / Privacy — gate po logowaniu. |
| `userEmailIndex/{emailLower}` | Lookup UID + metadane po e-mailu **konta** Firebase (panel). |
| `employeeWorkEmailIndex/{workEmailLower}` | Lookup UID + `workspaceIds` po **służbowym** e-mailu z udostępnionych workspace’ów — utrzymywany przez **mobile**. |
| `employers/{employerUid}/…` | Metadane panelu: śledzeni pracownicy, **trackedWorkspaces**, grupy — zapisuje **panel**, nie mobile. |

**Legacy:** w starych dokumentach `workspaces` mogą być `employeeFirstName` / `employeeLastName` — aplikacja **nie** zapisuje ich w nowym flow; imię/nazwisko w profilu globalnym / `userEmailIndex`.

---

## 6. Udostępnianie workspace dla panelu

- Mobile **nie** zbiera listy e-maili pracodawców. Pole **`linkedEmployerEmails`** może istnieć w starych danych — przy zapisie udostępnionego projektu merge (**`workspaceFirestoreMergeWrite`**) **usuwa** je z Firestore (`FieldValue.delete()`).
- **Udostępniony** workspace (`isSharedWithEmployer == true`): wymagane w UI m.in. **`companyName`**, **`employeeWorkEmail`** (trim, lower), opcjonalnie **`companySlug`**; **`employeeWorkEmailDomain`** wyliczane z części po `@`.
- **Prywatny** workspace: `isSharedWithEmployer: false` oraz merge usuwa pola sharingu i legacy.
- **`companySlug`:** stabilny (ręczny > z dokumentu > wyliczenie z nazwy) — `normalizeCompanySlug` / `resolveCompanySlugForSave`.
- Po zapisie listy workspace’ów wywoływane jest **`EmployeeWorkEmailIndexService.reconcile`** (z `WorkRepository`), żeby indeks **`employeeWorkEmailIndex`** odzwierciedlał wszystkie aktywne pary work email ↔ workspace.

Dostęp **pracodawcy** do danych pracownika w Firestore jest realizowany przez reguły z **`trackedWorkspaces`** (patrz § 12), a nie wyłącznie przez „śledzenie UID”.

---

## 7. Model wpisów `entries`

Wymagane pola i walidacja w regułach: **`workspaceId`**, **`start`**, **`end`**, **`mode`**, **`updatedAt`**, **`isDeleted`**; opcjonalnie m.in. **`taskTitle`**, **`note`**, **`isBillable`**, **`entryType`**, **`billingRatePercent`**, pola audytu (**`editedAt`**, **`editedBy`**, **`createdBy`**, **`createdVia`**).

- **Mobile:** timer i historia; soft delete = `isDeleted: true` (brak fizycznego `delete` dokumentu w regułach).
- **Panel:** przy spełnieniu `employerEntryCreateValid` / `employerEntryUpdateValid` może tworzyć/aktualizować wpisy z **`createdVia: 'employer_panel'`** i **`createdBy`** = UID pracodawcy — mobile **parsuje** wpisy do modelu `WorkEntry`; dodatkowe pola audytu są tolerowane; merge zapisu tam, gdzie używany jest `SetOptions(merge: true)`, nie muszą ginąć przy aktualizacji z mobile.
- **`billingRatePercent`:** dozwolone wartości w regułach (int/float dla wpisów); w logice statystyk nieznana wartość może być traktowana jak 100% — patrz **[DATA_CONTRACT.md](DATA_CONTRACT.md)**.
- **`entryType`:** brak lub nieznany string → fallback **`work`** (`entryTypeFromStorage`).
- **Nieważny przedział** (`start >= end`): czas trwania jak zero; wpis pomijany w agregatach (`countsInTimeAggregates`).

---

## 8. Offline: cache, kolejka, ochrona przed nadpisaniem edycji z webu

- **Pełna historia** docelowo w Firestore; **lokalnie** (`LocalCacheStore`): cache bieżącego miesiąca per workspace, kolejka **pending** wpisów (`work_entries_pending_v2`), kolejka **`upsertWorkspace`** przy offline (`workspaces_remote_pending_v1`), lista workspace’ów, aktywny workspace, migracja legacy `work_entries_v1` → workspace `default`.
- **Merge przy online:** dla „bieżący miesiąc” wynik Firestore jest scalany z cache (uniknięcie znikania świeżych wpisów przed sync).
- **`syncPending` (`WorkRepository`):** przed `upsert` wpisu z kolejki pobierany jest **`fetchEntry`**; jeśli **`remote.updatedAt` jest nowszy** niż `entry.updatedAt` w kolejce, mobile **pomija** ten upsert (wygrywa edycja z panelu / innej sesji). To jest główna ochrona przed **konfliktem offline vs web**.
- **Workspace:** `FirebaseWorkStore.fetchWorkspaces` pobiera całą kolekcję (w tym zarchiwizowane); filtrowanie aktywnych w UI. Uszkodzony pojedynczy dokument nie przerywa importu.
- **Aktywny projekt:** po zapisie / wczytaniu repozytorium stara się wskazać pierwszy **niezarchiwizowany** workspace (best effort).
- **Timer session:** JSON w prefs zgodny z Kotlinem (`flutter.timer_session_v1`), spójny z `LocalTimerSession`.

---

## 9. Live status — `users/{uid}/live/status`

**Cel:** jeden dokument (`live` / id `status`) z **bieżącym** stanem: online z perspektywy panelu, stan timera, aktywny projekt, pola do szacunku kwoty „w locie”. **`entries`** = historia i rozliczenia końcowe; **`live/status`** tylko podgląd dla UI panelu.

### Pola (skrót)

| Pole | Znaczenie |
|------|-----------|
| `uid` | Zgodne z ścieżką i `request.auth.uid` przy zapisie (reguły). |
| `isOnline` | m.in. `true` przy `running`/`paused`, lub `idle` w foreground; przy `idle` w tle zwykle `false`. |
| `timerState` | `idle` \| `running` \| `paused`. |
| `activeWorkspaceId` / `activeCompanySlug` / `activeWorkspaceName` | Kontekst wyświetlania. |
| `sessionStartedAt` | Kotwica bieżącego segmentu `running`; przy `paused`/`idle` usuwane. |
| `sessionPausedAt` | Ostatnia pauza; przy `running`/`idle` usuwane. |
| `accumulatedSecondsBeforePause` | Zakończone segmenty przed bieżącym `running`. |
| `billingRatePercent` | MVP często stałe `100`; reguły dopuszczają zestaw procentów. |
| `hourlyRate` / `currency` | Ze stawki aktywnego projektu lub usunięte, jeśli brak sensownej wartości (nie `0` jako fałszywa stawka). |
| `lastSeenAt`, `updatedAt` | `serverTimestamp` / heartbeat. |

### Kiedy mobile aktualizuje

Logowanie (`markSignedIn`), wylogowanie (`markSignedOut` **await** przed `signOut`), play/pause/stop (`syncFromTimerState`), init / zmiana projektu, `AppLifecycleState.resumed` (`syncFromNativeStoresOnResume` → `syncFromTimerState`), `paused`/`detached`, **heartbeat ~45 s** (merge `lastSeenAt` + `updatedAt`).

Implementacja: **`LiveStatusService`**, **`LiveStatusAppBinding`**, integracja w **`AuthGate`**.

**Konsumpcja w panelu:** odczyt dokumentu + liczenie czasu dla `running` z `sessionStartedAt` + `accumulatedSecondsBeforePause` (szczegół semantyki w kodzie panelu; kontrakt pól: ten dokument + **[DATA_CONTRACT.md](DATA_CONTRACT.md)**).

---

## 10. Android: widget, serwis, synchronizacja

**Przepływ:** `Flutter` → **`TimerServiceBridge`** (MethodChannel `work_timer/service_control`) → **`WorkTimerForegroundService`** → **SharedPreferences** (Flutter prefs + `home_widget`) → odświeżenie widgetu.

### Foreground service

- Akcje: `PLAY`, `PAUSE`, `STOP`, `SYNC`, `PREVIOUS_WORKSPACE`, `NEXT_WORKSPACE`.
- Ticker ~1 s: stan, notyfikacja, widoki widgetu.
- **`persistAndRender`:** prefs + JSON sesji do Flutter SharedPreferences + **lustro JVM** (`publishMirrorForFlutter`).

### MethodChannel (`MainActivity`)

- Metody: `play`, `pause`, `stop`, `sync`, **`getNativeTimerSnapshot`**, **`syncWidgetWorkspaces`**, **`getWidgetWorkspaceSelection`**.

### Spójność Flutter ↔ native

- Po **`handleSync`** w Kotlinie przy `running` reset kotwicy czasu (`resumeAtMs`) po uwzględnieniu `elapsedSeconds`, żeby uniknąć rozjazdu z tickiem po sterowaniu z widgetu.
- **`syncFromNativeStoresOnResume`:** `reload()` prefs, hydratacja z lustra JVM, wyrównanie **`activeWorkspaceId`**, `loadEntries` przy zmianie z widgetu, odświeżenie statów — **`TimerCubit.syncFromNativeStoresOnResume`**.
- **Auth:** `auth_native_sync.dart` → `flutter.auth_signed_in_for_native_v1`; Kotlin `AuthPrefs` steruje intencjami widgetu.

### Widget UI i przełączanie workspace (idle)

- Lista workspace’ów: JSON w prefs (`widget_workspaces_json`), synchronizacja **`syncWidgetWorkspaces`** z **`TimerCubit._writeWidgetSnapshot`**.
- Przy `running`/`paused` przyciski ‹/› nie zmieniają indeksu.
- Flutter przy starcie / resume: **`getWidgetWorkspaceSelection`** + **`setActiveWorkspace`** gdy timer `idle` i ID jest na liście repo.

---

## 11. iOS: WidgetKit, App Groups, deep link

- **Brak ForegroundService** — timer w Flutter + `LocalCacheStore`; timestampy `sessionStart` / `resumeAt` / `accumulated`.
- **MethodChannel** w `AppDelegate.swift`: jak Android + `reloadWidgets`; throttle pełnego `sync` ~**15 s** w `running`, natychmiast przy zdarzeniach dyskretnych.
- **App Group:** `group.com.worktimer.workTimer`; klucze `wt_*` w `UserDefaults(suiteName:)`.
- **Rozszerzenie:** kod w **`ios/WorkTimerWidgetExtension/`** — w Xcode trzeba dodać target, capabilites, embed appex (Team).
- **Deep link** `worktimer://` — `Info.plist`, **`IosDeepLinkNav`**, kanał `work_timer/deeplink`. Indeks zakładki **0…5** (Timer … Ustawienia); legacy `…/workspaces` → zakładka Projekty (**4**).
- **Widget:** podgląd workspace, status, czas z App Group; tap na nazwie → `worktimer://workspaces`.

---

## 12. Reguły Firestore — założenia dla tej aplikacji

Plik **`firestore.rules`** w repozytorium musi być wdrożony **w całości** (`firebase deploy --only firestore:rules` lub konsola). Poniżej skrót semantyki istotnej dla mobile i panelu:

- **Funkcje pomocnicze:** m.in. `employerTracksUser(employeeUid)` (dokument pod `employers/{employerUid}/trackedEmployeeUids/{employeeUid}`), **`employerHasTrackedWorkspace(employeeUid, workspaceId)`** (dokument pod **`employers/{employerUid}/trackedWorkspaces/{employeeUid_workspaceId}`**), `trackedWorkspaceId` = konkatenacja `employeeUid + '_' + workspaceId`.
- **`users/{uid}/entries`:** odczyt dla pracodawcy tylko gdy **`employerHasTrackedWorkspace(uid, resource.data.workspaceId)`**; create/update z panelu wymaga tego samego + pól audytu (`createdVia: employer_panel'` itd. wg funkcji w rules).
- **`users/{uid}/workspaces`:** odczyt — owner **lub** `employerHasTrackedWorkspace` **lub** (`employerTracksUser` **i** `isSharedWithEmployer == true`); aktualizacja billingu (**hourlyRate**, **currency**, **currencyCode**, **updatedAt** tylko) dla pracodawcy z **`hasValidWorkspaceBillingPatch`** przy `employerHasTrackedWorkspace`.
- **`users/{uid}/live/status`:** zapis wyłącznie **owner**; odczyt owner lub `employerTracksUser` (podgląd statusu dla śledzonego pracownika).
- **Indeksy** `userEmailIndex`, `employeeWorkEmailIndex` — kształty walidowane funkcjami `hasValid*Shape`; zapis `employeeWorkEmailIndex` tylko gdy `data.uid == request.auth.uid`.
- **Employer:** `trackedEmployees`, `trackedEmployeeUids`, **`trackedWorkspaces`**, `groups` — read/write dla `isOwner(employerUid)`; shape `trackedWorkspaces` wymaga m.in. zgodnego `accessId`, `employerTracksUser(employeeUid)` oraz **`workspaceIsSharedForEmployer`** (dokument workspace ma `isSharedWithEmployer == true`).
- **Catch-all:** `match /{document=**}` → deny — brak przypadkowych leaków.

**Wdrożenie deweloperskie (Firebase):**

1. Projekt Firebase: **Authentication** (e-mail/hasło), **Firestore**.
2. **FlutterFire CLI:**  
   `dart pub global activate flutterfire_cli`  
   `dart pub global run flutterfire_cli:flutterfire configure --yes --project=YOUR_PROJECT_ID -o lib/firebase_options.dart --overwrite-firebase-options`  
   Na Windows przy problemach z PATH użyj pełnej formy `dart pub global run flutterfire_cli:flutterfire …`.
3. Commituj `firebase_options.dart` i pliki platform (np. `google-services.json`, `GoogleService-Info.plist`) zgodnie z polityką repo — **nie** commituj fikcyjnego plist na iOS.
4. **iOS:** bez `GoogleService-Info.plist` w Runnerze `Firebase.initializeApp` na urządzeniu może się nie powieść.

---

## 13. Testy (manualne, automatyczne, CI)

- **Manualne:** **[QA_CHECKLIST.md](QA_CHECKLIST.md)** — m.in. auth, zgody, projekty + sharing + indeks work email, timer, offline, widget Android, integracja z panelem (`entries`, `live`).
- **Automatyczne:** `flutter test` — m.in. migracja wpisów, **`StatsService`**, **`WorkRepository`** / `syncPending` z fałszywym remote, **`TimerCubit`**, kompatybilność wpisów z panelem (`test/work_entry_employer_panel_compat_test.dart`), **`live_status_sync_plan`**, CSV, Auth, **`SettingsCubit`**.
- **PDF:** brak dedykowanego testu jednostkowego — weryfikacja ręczna z UI eksportu.
- **GitHub Actions:** `.github/workflows/flutter_ci.yml` — przy push/PR do `main`: `dart format --set-exit-if-changed`, `flutter analyze --no-fatal-infos`, `flutter test`, `flutter build apk --debug`. Build iOS na Ubuntu **nie** jest w workflow (wymaga macOS + certyfikatów).

---

## 14. Znane ograniczenia

- **Android vs iOS:** pełny foreground service tylko na Androidzie; iOS opiera się o Flutter + timestampy + App Group.
- **macOS / desktop:** brak natywnego widgetu mobilnego; zachowanie `TimerServiceBridge` / `home_widget` zgodnie z warunkami platformy w `TimerCubit`.
- **Sekundy:** możliwy rozjazd ±1 s między tickiem Kotlina a Flutterem (zaokrąglenia).
- **Po `stop`:** `refreshStatsEntries` często **`unawaited`**, żeby nie blokować UI — wpis lokalnie od razu, statystyki doganiają async.
- **Firestore:** dokumenty mogą mieć dodatkowe opcjonalne pola — reguły definiują dozwolony zestaw kluczy przy pełnym replace; merge w kliencie tam, gdzie jest użyty.

---

## 15. Możliwe dalsze prace (techniczne)

- Job CI na **macOS** + `flutter build ios` po przygotowaniu sekretów i plist.
- Testy jednostkowe / golden dla **PDF**.
- Rozszerzenie **App Intents** na iOS dla sterowania timerem z widgetu (z zapisem do App Group + reload timeline).
- Twardsze **metryki** konfliktów `syncPending` (logowanie telemetryczne zamiast `debugPrint`).
- **Re-consent** przy zmianie `termsVersion` / `privacyVersion` z osobnym UX.
- Rozdzielenie przestrzeni nazw **`employeeWorkEmailIndex`** przy kolizji dwóch UID na tym samym work email (wymagałoby zmiany kontraktu id dokumentu lub prefiksu).

---

*Ostatnia aktualizacja: przebudowa dokumentu (15 sekcji), reguły `trackedWorkspaces`, README jako opis produktu; szczegóły kontraktu danych w DATA_CONTRACT.*
