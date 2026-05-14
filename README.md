# Work Timer — mobile time tracking app

[![Flutter CI](https://github.com/JKlm95/work_timer/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/JKlm95/work_timer/actions/workflows/flutter_ci.yml)

## Krótki opis

**Work Timer** to aplikacja mobilna (**Flutter**) do śledzenia czasu pracy w **wielu projektach** (modele `Workspace`). Oferuje **timer sesji**, **historię** wpisów, **statystyki** i **kalendarz**, synchronizację z **Firebase** (Auth + Firestore), **tryb offline** z cache i kolejką zapisów oraz **widgety** na **Androidzie** i **iOS**. Motyw jasny / ciemny / systemowy i lokalizacja **PL / EN**.

Aplikacja współpracuje z **panelem pracodawcy** ([work_timer_employer_panel](https://github.com/JKlm95/work_timer_employer_panel)) — osobną aplikacją webową na tym samym Firebase: udostępniane projekty, wpisy czasu, profil oraz **stan na żywo** timera (`live/status`).

Szczegóły techniczne: **[TECHNICAL.md](TECHNICAL.md)**. Kontrakt ścieżek danych z panelem: **[DATA_CONTRACT.md](DATA_CONTRACT.md)**. Checklistę testów ręcznych: **[QA_CHECKLIST.md](QA_CHECKLIST.md)**.

---

## Problem i sens (Why)

Śledzenie czasu pracy często rozjeżdża się między „timerem w głowie”, notatkami i późniejszym uzupełnianiem arkuszy. **Work Timer** zbiera pracę w jednym miejscu: szybki start / pauza / stop, spójna **historia** i **podsumowania per projekt**, a przy udostępnionych projektach — **spójność z panelem pracodawcy** (podgląd statusu, raporty, stawki), bez zastępowania systemów kadrowych czy prawnego payrollu.

---

## Kluczowe funkcje

- **Firebase Auth** — rejestracja, logowanie, reset hasła.
- **Legal consent flow** — akceptacja regulaminu i polityki prywatności przed wejściem do głównego UI (`users/{uid}/legal/consents`).
- **Zarządzanie projektami (workspace)** — nazwa, kolor, archiwum, **stawka godzinowa** i **waluta** (PLN / EUR / USD / GBP).
- **Służbowy e-mail per workspace** — przy udostępnieniu projektu pracodawcy: firma, slug, adres pracy pracownika; mobile utrzymuje **`employeeWorkEmailIndex`** do wyszukiwania pracownika po work email w panelu.
- **Timer** — start, pauza, wznowienie, stop; zapis sesji do `entries`; opcjonalny dialog podsumowania po stopie (ustawienia).
- **Typy wpisów (`entryType`)** — m.in. praca / urlop; wpływ na statystyki i raporty.
- **`billingRatePercent`** — procent rozliczenia przy szacunku kwot (wartości dozwolone w regułach + fallback w logice biznesowej).
- **Rozliczalność** — `isBillable`, stawki i waluty per projekt.
- **Historia** — filtry zakresu dat, trybu pracy i typu wpisu; edycja i wpisy ręczne; soft delete (`isDeleted`).
- **Kalendarz** — widok miesiąca z markerami projektów.
- **Statystyki** — agregaty, wykres tygodnia, szacunki rozliczeń per waluta.
- **Eksport CSV / PDF** — udostępnianie i zapis lokalny tam, gdzie platforma to wspiera.
- **Offline** — cache miesiąca, kolejka `syncPending`, sync po powrocie sieci.
- **Widget Android** — skrót na pulpicie, foreground service, sterowanie / podgląd czasu (szczegóły w TECHNICAL).
- **Widget iOS** — WidgetKit, App Group, deep link `worktimer://` (TECHNICAL).
- **Live status** — dokument `users/{uid}/live/status` dla panelu (online, stan timera, aktywny projekt, pola sesji do szacunku „w locie”).

---

## Przegląd architektury (wysoki poziom)

Aplikacja to **klient mobilny Flutter** rozmawiający z **Firebase Auth** i **Cloud Firestore**. Dane czasu i konfiguracja projektów są w chmurze; lokalnie działa **cache i kolejka** (`WorkRepository`, `LocalCacheStore`), żeby UI był responsywny i odporny na brak sieci. **Widgety** korzystają z **natywnego mostu** (MethodChannel, Android Kotlin + iOS Swift), współdzieląc stan z Flutterem zgodnie z opisem w TECHNICAL.

Z panelem pracodawcy łączy ją **wspólny projekt Firebase** i **kontrakt dokumentów** opisany w DATA_CONTRACT (w tym indeksy i ścieżki pod raporty oraz `trackedWorkspaces` po stronie pracodawcy).

---

## Współpraca z panelem pracodawcy

1. Pracownik w projekcie włącza **udostępnienie pracodawcy** i podaje **służbowy adres e-mail** oraz dane firmy (zgodnie z UI).
2. Mobile zapisuje pola sharingu w **`users/{uid}/workspaces/{workspaceId}`** i utrzymuje **`employeeWorkEmailIndex/{workEmailLower}`** (mapowanie work email → UID + lista `workspaceIds`), żeby panel mógł **znaleźć pracownika** po tym samym adresie co na workspace.
3. Po stronie **web** pracodawca dodaje śledzenie pracownika i — w modelu dostępu zgodnym z **`firestore.rules`** — **konkretne workspace’y** w dokumentach pod **`employers/{employerUid}/trackedWorkspaces/{employeeUid_workspaceId}`** (`accessId` = `employeeUid + '_' + workspaceId`). Dzięki temu odczyt **`entries`** i patch **stawki** na workspace jest **per projekt**, a nie „wszystko dla śledzonego UID”.
4. **Źródło prawdy czasu pracy** to nadal **`users/{uid}/entries`** zapisywane z mobile (timer, historia) oraz — w dozwolonych regułach — z panelu.
5. **Podgląd „teraz pracuje”** pochodzi z **`users/{uid}/live/status`**, aktualizowanego z aplikacji mobilnej (heartbeat, zmiany timera, lifecycle).

---

## Stack technologiczny

| Obszar | Technologie |
|--------|-------------|
| UI | Flutter / Dart |
| Stan | **flutter_bloc** — Cubity (`AuthCubit`, `TimerCubit`, `SettingsCubit`, …) |
| Backend | **Firebase Auth**, **Cloud Firestore** |
| Offline | `LocalCacheStore`, kolejki pending, `connectivity_plus` |
| Widget Android | Kotlin, **MethodChannel**, foreground service, **home_widget**, SharedPreferences |
| Widget iOS | Swift, **WidgetKit**, **App Groups**, MethodChannel |
| Jakość | testy `flutter test`, **GitHub Actions** (format, analyze, test, build APK debug) |

---

## Status projektu

Projekt ma charakter **MVP / jakości beta**: zaimplementowane są **główne przepływy** (konto, zgody, projekty, timer, historia, statystyki, kalendarz, eksport, offline, widgety, live status). To **nie** jest system kadrowy ani prawny payroll — raczej narzędzie produktywne i **demo techniczno-produktowe** z realnym backendem.

---

## Roadmap / możliwe kolejne kroki

- Hostowany **demo web** / osobne środowiska dev / prod.
- **Onboarding** silniejszy (pierwszy projekt, wyjaśnienie udostępniania).
- **Lepszy audyt** edycji wpisów (historia zmian po stronie klienta / panelu).
- **Szablony eksportu** (układ PDF/CSV pod organizację).
- **Flow zaproszeń / akceptacji** dostępu pracodawcy zamiast wyłącznie ręcznej konfiguracji w panelu.
- **Analytics / crash reporting** (np. Firebase Crashlytics).
- **Przygotowanie pod sklepy** (ikony, store listing, polityki).
- **Powiadomienia push** (np. przypomnienia o timerze).

---

## Uruchomienie

Wymagany **Flutter** i skonfigurowany **Firebase** (`lib/firebase_options.dart`, pliki platform; na iOS **`GoogleService-Info.plist`** w `ios/Runner` z konsoli). Pełny setup: **[TECHNICAL.md](TECHNICAL.md)** (sekcja o konfiguracji Firebase i regułach).

**Reguły Firestore:** wgraj **`firestore.rules`** z tego repozytorium (konsola lub `firebase deploy --only firestore:rules`). Reguły muszą obejmować **`entries`**, **`workspaces`**, **`live`**, indeksy oraz ścieżki **`employers/...`** zgodnie z panelem — inaczej pojawi się `permission-denied` lub puste listy po reinstalacji.

```bash
flutter pub get
flutter run
```

**iOS (Mac + Xcode):** po `flutter pub get` w `ios` uruchom `pod install`. W **Signing & Capabilities** włącz **App Groups** dla `group.com.worktimer.workTimer` (Runner + rozszerzenie widgetu). **URL scheme:** `worktimer` w `Info.plist` Runnera.

Po zmianach w **`.arb`**: `flutter pub get` lub `flutter gen-l10n`.

---

## CI

Workflow **[`.github/workflows/flutter_ci.yml`](.github/workflows/flutter_ci.yml)** — przy pushu i PR do **`main`**: `flutter pub get`, `dart format`, `flutter analyze --no-fatal-infos`, `flutter test`, `flutter build apk --debug`. W repozytorium GitHub włącz **Actions**, jeśli wyłączone.

---

## Licencja

Repozytorium nie zawiera pliku `LICENSE` — przy publikacji dodaj wybraną licencję lub ustaw ją w ustawieniach repozytorium na GitHubie.

---

## Screenshots

Screenshots will be added here.

<!-- ![Timer](docs/screenshots/timer.png) -->
<!-- ![History](docs/screenshots/history.png) -->
<!-- ![Stats](docs/screenshots/stats.png) -->
<!-- ![Workspace sharing](docs/screenshots/workspace-sharing.png) -->
