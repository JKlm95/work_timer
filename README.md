# Work Timer — aplikacja do śledzenia czasu pracy

[![Flutter CI](https://github.com/JKlm95/work_timer/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/JKlm95/work_timer/actions/workflows/flutter_ci.yml)

**Work Timer** to aplikacja mobilna (**Flutter**) do rejestrowania czasu pracy w **wielu projektach** (`Workspace`), z **Firebase** (Auth, Firestore), **timera sesji**, historią, statystykami i **widgetem** (Android: foreground service + MethodChannel; iOS: WidgetKit + App Group). Obsługa **offline** (cache, kolejka synchronizacji). Motyw jasny/ciemny i lokalizacja **PL/EN**.

Aplikacja współpracuje z **panelem pracodawcy** (osobny projekt webowy): udostępnia m.in. wpisy czasu, projekty, profil oraz **stan na żywo** timera w Firestore. Kontrakt ścieżek danych: **[DATA_CONTRACT.md](DATA_CONTRACT.md)**.

Szczegóły architektury mobilki, widget, **live status**, setup Firebase: **[TECHNICAL.md](TECHNICAL.md)**. Checklistę testów ręcznych: **[QA_CHECKLIST.md](QA_CHECKLIST.md)**.

---

## Dla rekrutera

| | |
|---|---|
| **Zakres** | Projekt portfolio — pełna ścieżka: UI, warstwa danych, integracja natywna Android, testy, CI. |
| **Stack** | Flutter (Dart 3), **flutter_bloc**, Firebase **Auth** + **Firestore**, **connectivity_plus**, **home_widget** / **MethodChannel** (Android), Swift **WidgetKit** + App Group (iOS). |
| **Dokumentacja** | **[TECHNICAL.md](TECHNICAL.md)** — przepływy, widget, live status, reguły. **[DATA_CONTRACT.md](DATA_CONTRACT.md)** — ścieżki Firestore mobile ↔ panel. **[QA_CHECKLIST.md](QA_CHECKLIST.md)** — testy ręczne. |

**Skrót przepływu widgetu (Android):**  
Flutter (`TimerServiceBridge`) → **MethodChannel** `work_timer/service_control` → **Kotlin** (`WorkTimerForegroundService`) → **SharedPreferences** → odświeżenie **`WorkTimerWidgetProvider`**.

---

## Problem i rozwiązanie

Śledzenie czasu pracy (np. home office vs biuro) często rozjeżdża się między „timerem w głowie” a późniejszym uzupełnianiem arkuszy. **Work Timer** zbiera to w jednym miejscu: szybki timer, skrót na pulpicie telefonu oraz historia i podsumowania **per projekt**.

---

## Główne funkcje

- **Konto** — rejestracja, logowanie, reset hasła (Firebase Auth).
- **Profil** — imię i nazwisko w Ustawieniach; synchronizacja z profilem w Firestore i indeksem e-mail pod panel pracodawcy.
- **Projekty** (UI „Projects” / „Projekty”) — tworzenie i edycja: nazwa, kolor, **stawka godzinowa + waluta** (PLN/EUR/USD/GBP), pola pod **udostępnienie pracodawcy**, archiwum.
- **Timer** — start / pauza / stop, tryb pracy; zapis sesji do `entries`; **live/status** dla panelu (online, stan timera, aktywny projekt).
- **Historia, statystyki, kalendarz** — filtrowanie, raporty projektu, eksport **CSV/PDF**.
- **Widget** (Android / iOS) — skrót do stanu timera i projektu (szczegóły w TECHNICAL).
- **Offline** — kolejka zapisów; sync po powrocie sieci.

---

## Current architecture (skrót)

```
lib/main.dart
  └── Firebase.init → WorkRepository (LocalCacheStore + FirebaseWorkStore)
  └── AuthCubit, SettingsCubit, UserProfileRepository, LiveStatusService (singleton w drzewie)
lib/screens/auth_gate.dart
  └── TimerCubit (per user) + lifecycle → LiveStatusService.sync / heartbeat
lib/bloc/timer_cubit.dart
  └── Stan sesji, wpisy, workspaces; _notifyLive po zdarzeniach timera
lib/services/live_status_service.dart
  └── users/{uid}/live/status (merge)
```

- **Źródło prawdy czasu:** `users/{uid}/entries`.  
- **Podgląd „teraz pracuje”:** `users/{uid}/live/status`.  
- Więcej: **[TECHNICAL.md](TECHNICAL.md)**, **[DATA_CONTRACT.md](DATA_CONTRACT.md)**.

---

## Możliwości (szczegóły UI)
- **Timer** — start / pauza / stop, tryb pracy (np. zdalna / biuro); opcjonalny **podsumowujący dialog po stopie** (zadanie, notatka, rozliczalność; wyłączenie w ustawieniach).
- **Historia** — zakres dat, filtry trybu pracy **i typu wpisu** (np. praca / urlop), lista sesji **od najnowszej**, ręczne wpisy z polami jak przy timerze; eksport **CSV lub PDF** (menu) — udostępnianie (**`share_plus`**) oraz **zapis lokalny** przez **`saveExportWithPicker`** (Android/iOS: bajty w `file_picker` / SAF; desktop: ścieżka z dialogu).
- **Statystyki** — agregaty, wykres tygodnia (ISO, pon–nd), udział czasu wg projektów (z kolorem), **szacunek rozliczeń**: czas rozliczalny / nierozliczalny oraz sumy pieniężne **osobno per waluta** przy ustawionej stawce — **[TECHNICAL.md](TECHNICAL.md)** § 7c–7e.
- **Kalendarz** — widok miesiąca z markerami wg kolorów projektów (`table_calendar`).
- **Widget (Android)** — czas i sterowanie z launchera; bez logowania — otwarcie aplikacji. Przy **idle** przełączanie projektu (‹/›), lista zsynchronizowana z Fluttera.
- **Widget (iOS)** — podgląd projektu, stan (Idle / Running / Paused) i czasu; dane z **App Group**. Tap (`worktimer://…`) przełącza zakładki — zakres indeksów opisany w **[TECHNICAL.md](TECHNICAL.md)** § 6.6.
- **Motyw i język** — jasny / ciemny / system; polski / angielski / locale systemu (`SettingsCubit`, ARB w `lib/l10n/`); po starcie aplikacji ładowane są dane **`intl`** dla locale kalendarza (`en_US`, `pl_PL`).

---

## Screenshots

Brak wbudowanych grafik w repozytorium. Aby dodać zrzuty: utwórz folder **`docs/screenshots/`**, umieść pliki PNG/WebP i w tej sekcji wstaw linki Markdown, np. `![Timer](docs/screenshots/timer.png)`.

---

## Pitch (CV / opis projektu)

> Aplikacja **Work Timer** (Flutter) rejestruje czas pracy w wielu **projektach** (model `Workspace`) z synchronizacją **Firebase** i obsługą **offline**. Zawiera integrację **widgetu Android** z warstwą Dart (współdzielony stan, foreground service, kanał natywny), spójność przy powrocie do aplikacji oraz ekran startowy przed wejściem w główny interfejs. Szczegóły implementacji: **[TECHNICAL.md](TECHNICAL.md)**.

---

## Uruchomienie

Wymagany **Flutter** i skonfigurowany projekt **Firebase** (`lib/firebase_options.dart`, pliki platform — na iOS dodaj **`GoogleService-Info.plist`** do `ios/Runner` z konsoli Firebase, jeśli go brakuje). Pełny setup: **[TECHNICAL.md](TECHNICAL.md)** § 8.

**Firestore — reguły bezpieczeństwa:** w konsoli Firebase wdroż **`firestore.rules`** z tego repozytorium (albo `firebase deploy --only firestore:rules`). Muszą obejmować **`users/{uid}/entries`**, **`users/{uid}/workspaces`** oraz (dla panelu) **`users/{uid}/live`** i indeksy zgodnie z **[DATA_CONTRACT.md](DATA_CONTRACT.md)**. Same reguły tylko dla wpisów blokują zapis/odczyt workspace’ów w produkcji (objaw: brak listy workspace’ów po reinstalacji). Szczegóły: **[TECHNICAL.md](TECHNICAL.md)** § 4, § 4b i § 8.

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

*Ten plik jest czytelny dla **rekrutera i przeglądu portfolio**. Dokumentacja developerska: **[TECHNICAL.md](TECHNICAL.md)**; kontrakt danych z panelem: **[DATA_CONTRACT.md](DATA_CONTRACT.md)**.*
