# Work Timer — aplikacja do śledzenia czasu pracy

[![Flutter CI](https://github.com/JKlm95/work_timer/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/JKlm95/work_timer/actions/workflows/flutter_ci.yml)

**Work Timer** to aplikacja mobilna (Flutter) do rejestrowania czasu pracy w **wielu workspace’ach**, z **Firebase** (logowanie e-mail, Firestore), **timera sesji**, historią, statystykami i **widgetem na ekranie głównym Androida** (MethodChannel, foreground service, SharedPreferences) oraz ścieżką **iOS** (WidgetKit, App Groups, `UserDefaults` — bez ForegroundService; timer w oparciu o timestampy w Flutterze). Obsługa **offline** (cache, kolejka synchronizacji). Motyw jasny/ciemny i lokalizacja PL/EN.

Szczegóły architektury, setup Firebase i dane: **[TECHNICAL.md](TECHNICAL.md)**.

---

## Dla rekrutera

| | |
|---|---|
| **Zakres** | Projekt portfolio — pełna ścieżka: UI, warstwa danych, integracja natywna Android, testy, CI. |
| **Stack** | Flutter (Dart), Firebase Auth & Firestore, **flutter_bloc**, **home_widget** / **MethodChannel** (Android), **Swift** WidgetKit + App Group (iOS, patrz TECHNICAL). |
| **Dokumentacja techniczna** | **[TECHNICAL.md](TECHNICAL.md)** — przepływy danych, widget, reguły Firestore, testy. |

**Skrót przepływu widgetu (Android):**  
Flutter (`TimerServiceBridge`) → **MethodChannel** `work_timer/service_control` → **Kotlin** (`WorkTimerForegroundService`) → **SharedPreferences** → odświeżenie **`WorkTimerWidgetProvider`**.

---

## Problem i rozwiązanie

Śledzenie czasu pracy (np. home office vs biuro) często rozjeżdża się między „timerem w głowie” a późniejszym uzupełnianiem arkuszy. **Work Timer** zbiera to w jednym miejscu: szybki timer, skrót na pulpicie telefonu oraz historia i podsumowania per workspace.

---

## Możliwości

- **Konto** — rejestracja, logowanie, reset hasła (Firebase Auth).
- **Workspace’y** — tworzenie, zmiana nazwy, przełączanie kontekstu; wpisy powiązane z workspace.
- **Timer** — start / pauza / stop, tryb pracy (np. zdalna / biuro).
- **Historia** — zakres dat, filtry, ręczne wpisy, eksport **CSV** (`lib/export/work_entries_csv.dart`, `share_plus`).
- **Statystyki** — agregaty, wykres tygodnia (ISO, pon–nd), udział workspace’ów; zakres danych i kafelki vs wykres — **[TECHNICAL.md](TECHNICAL.md)** § 7c.
- **Widget (Android)** — czas i sterowanie z launchera; bez logowania — otwarcie aplikacji. Przy **idle** przełączanie workspace (‹/›), lista zsynchronizowana z Fluttera.
- **Widget (iOS)** — podgląd workspace, stan (Idle / Running / Paused) i czasu; dane z **App Group** (`TimerServiceBridge` → `AppDelegate`). Tap otwiera aplikację (`worktimer://workspaces`). Pełna konfiguracja targetu Widget Extension w Xcode: **[TECHNICAL.md](TECHNICAL.md)** § 6.6.
- **Offline** — kolejka wpisów i **ponawiany zapis workspace’ów** do Firestore po powrocie sieci (`syncPending`).
- **Motyw i język** — jasny / ciemny / system; polski / angielski / locale systemu (`SettingsCubit`, ARB w `lib/l10n/`).

---

## Screenshots

Brak wbudowanych grafik w repozytorium. Aby dodać zrzuty: utwórz folder **`docs/screenshots/`**, umieść pliki PNG/WebP i w tej sekcji wstaw linki Markdown, np. `![Timer](docs/screenshots/timer.png)`.

---

## Pitch (CV / opis projektu)

> Aplikacja **Work Timer** (Flutter) rejestruje czas pracy w wielu workspace’ach z synchronizacją **Firebase** i obsługą **offline**. Zawiera integrację **widgetu Android** z warstwą Dart (współdzielony stan, foreground service, kanał natywny), spójność przy powrocie do aplikacji oraz ekran startowy przed wejściem w główny interfejs. Szczegóły implementacji: **[TECHNICAL.md](TECHNICAL.md)**.

---

## Uruchomienie

Wymagany **Flutter** i skonfigurowany projekt **Firebase** (`lib/firebase_options.dart`, pliki platform — na iOS dodaj **`GoogleService-Info.plist`** do `ios/Runner` z konsoli Firebase, jeśli go brakuje). Pełny setup: **[TECHNICAL.md](TECHNICAL.md)** § 8.

**Firestore — reguły bezpieczeństwa:** w konsoli Firebase wdroż **`firestore.rules`** z tego repozytorium (albo `firebase deploy --only firestore:rules`). Muszą obejmować **`users/{uid}/entries`** **oraz** **`users/{uid}/workspaces`** — same reguły tylko dla wpisów blokują zapis/odczyt workspace’ów w produkcji (objaw: brak listy workspace’ów po reinstalacji). Szczegóły: **[TECHNICAL.md](TECHNICAL.md)** § 4 i § 8.

```bash
flutter pub get
flutter run
```

**iOS (Mac + Xcode):** po pierwszym `flutter pub get` w katalogu `ios` uruchom `pod install`. W **Signing & Capabilities** włącz **App Groups** dla `group.com.worktimer.workTimer` (Runner + rozszerzenie widgetu, gdy dodasz target). **URL scheme:** `worktimer` jest zadeklarowany w `Info.plist` Runnera.

Po zmianach w plikach **`.arb`**: `flutter pub get` lub `flutter gen-l10n`.

---

## CI

Workflow **[`.github/workflows/flutter_ci.yml`](.github/workflows/flutter_ci.yml)** — przy pushu i PR do **`main`**: `flutter pub get`, `dart format`, `flutter analyze --no-fatal-infos`, `flutter test`, `flutter build apk --debug`. W repozytorium GitHub włącz **Actions** (Settings → Actions), jeśli wyłączone.

---

## Licencja

Repozytorium nie zawiera pliku `LICENSE` — przy publikacji dodaj wybraną licencję lub ustaw ją w ustawieniach repozytorium na GitHubie.

---

*Ten plik jest czytelny dla **rekrutera i przeglądu portfolio**. Dokumentacja developerska: **[TECHNICAL.md](TECHNICAL.md)**.*
