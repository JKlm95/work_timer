# Work Timer — aplikacja do śledzenia czasu pracy

> **Sugerowany opis repozytorium (GitHub → About → Description):**  
> *Offline-first time tracking app built with Flutter, BLoC, Firebase and native Android foreground service.*

Flutterowa aplikacja mobilna z **Firebase** (logowanie e-mail, synchronizacja w chmurze), **wieloma workspace’ami**, timerem sesji, historią wpisów, statystykami oraz **widgetem na ekranie głównym (Android)**. Projekt demonstracyjny — pokazuje pracę end-to-end: UI, warstwę danych, integrację natywną i obsługę offline.

---

## Dla rekrutera w skrócie

| | |
|---|---|
| **Rola w projekcie** | *Tu wpisz: autor / zakres (np. samodzielnie, czas trwania)* |
| **Stack** | Flutter (Dart), Firebase Auth & Firestore, Bloc, widget + serwis Android |
| **Szczegóły techniczne** | Pełny opis architektury, kanałów natywnych i strategii danych → **[TECHNICAL.md](TECHNICAL.md)** |

**Ścieżka danych widgetu (Android, skrót):**  
Flutter (`TimerServiceBridge`) → **MethodChannel** `work_timer/service_control` → **Kotlin** (`WorkTimerForegroundService`) → **SharedPreferences** (prefs Flutter + home_widget) → **odświeżenie widżetu** (`AppWidgetProvider`).

**GitHub → Topics** *(wklej ręcznie, bez spacji w nazwie topicu):*  
`flutter` · `firebase` · `bloc` · `offline-first` · `android-widget` · `foreground-service` · *(opcjonalnie)* `method-channel` · `kotlin`

---

## Problem i rozwiązanie

Śledzenie czasu pracy (np. home office vs biuro) często rozjeżdża się między „timerem w głowie” a późniejszym uzupełnianiem arkuszy. **Work Timer** zbiera to w jednym miejscu: szybki timer, widoczny skrót na pulpicie telefonu oraz historia i podsumowania per workspace.

---

## Główne możliwości

- **Konto użytkownika** — logowanie, rejestracja, wylogowanie, reset hasła (Firebase Auth).
- **Workspace’y** — tworzenie, zmiana nazwy, przełączanie aktywnego kontekstu; wpisy przypisane do workspace’u.
- **Timer sesji** — start / pauza / stop, tryb pracy (np. zdalna / stacjonarna).
- **Historia** — zakres dat, filtry, ręczne dodawanie i edycja wpisów.
- **Statystyki** — agregaty w tygodniu / miesiącu, wykresy, udział workspace’ów.
- **Eksport (CSV)** — funkcja `workEntriesToCsv` w `lib/export/` (gotowa pod przycisk „Udostępnij” / zapis pliku; jeszcze niepodpięta pod ekran).
- **Widget (Android)** — podgląd czasu i sterowanie z ekranu głównego; **bez zalogowania** widget prowadzi do aplikacji zamiast odpalać timer *(zabezpieczenie pokazujące myślenie o UX i bezpieczeństwie)*.
- **Offline** — cache i kolejka zmian; synchronizacja po powrocie sieci.
- **Motyw i język** — **jasny / ciemny / systemowy** oraz **polski / angielski / język systemu** (zakładka Ustawienia); spójna paleta **`AppColors`**, motyw w **`buildWorkTimerTheme`**, teksty w **ARB** (`lib/l10n/app_en.arb`, `app_pl.arb`). Sterowanie czasem timera etykietami Play / Pause / Stop pozostaje po angielsku w obu lokalizacjach.

---

## Zrzuty ekranu *(do uzupełnienia przez autora)*

Poniżej: **propozycja nazw plików** i **co warto pokazać**. Umieść pliki np. w folderze `docs/screenshots/` i podlinkuj obrazki w tej sekcji.

<!--
  INSTRUKCJA DLA CIEBIE, KUBA:
  1. Utwórz folder docs/screenshots/
  2. Zrób zrzuty na emulatorze lub urządzeniu (jasny motyw, spójna rozdzielczość).
  3. Zamień ścieżki poniżej na prawdziwe linki markdown: ![opis](docs/screenshots/nazwa.png)
  4. Opcjonalnie: jeden plik złożony (np. Figma export) — wtedy jeden wiersz w tabeli.
-->

| Sugerowana nazwa pliku | Co pokazać |
|------------------------|------------|
| `01_splash_lub_login.png` | Ekran powitalny / logowanie (pierwszy kontakt z aplikacją). |
| `02_timer_glowny.png` | Zakładka Timera z widocznym licznikiem i wyborem trybu / workspace. |
| `03_historia.png` | Lista wpisów z filtrami lub szczegół edycji. |
| `04_statystyki.png` | Statystyki (wykres / podsumowanie). |
| `05_workspaces.png` | Zarządzanie workspace’ami. |
| `06_widget_android.png` | Widget na launcherze (opcjonalnie obok otwartej apki). |
| `07_ustawienia_lub_dark.png` | *(opcjonalnie)* Ustawienia języka/motywu albo ten sam ekran w trybie ciemnym. |

**Placeholder pod galerię** *(usuń ten blok po dodaniu grafik):*

```markdown
<!-- Przykład po dodaniu plików:
![Logowanie](docs/screenshots/01_splash_lub_login.png)
![Timer](docs/screenshots/02_timer_glowny.png)
-->
```

---

## Krótki opis do CV lub listu motywacyjnego *(szkic)*

> Aplikacja mobilna **Work Timer** (Flutter) służy do rejestrowania czasu pracy w wielu workspace’ach, z synchronizacją **Firebase** i obsługą **offline**. Zrealizowałem m.in. integrację **widgetu Android** z warstwą Flutter (współdzielony stan, foreground service, kanał natywny), spójny UX przy powrocie do aplikacji oraz ekran startowy ładowania danych przed wejściem w główny interfejs. Szczegóły techniczne: repozytorium → **TECHNICAL.md**.

*(Dostosuj pierwszą osobę / „my” wg kontekstu.)*

---

## Uruchomienie (skrót)

Wymagany **Flutter** i projekt **Firebase** (konfiguracja `firebase_options` i pliki platform). Szczegółowy przewodnik setupu, reguły Firestore i strategia danych: **[TECHNICAL.md](TECHNICAL.md)**.

```bash
flutter pub get
flutter run
```

Po edycji plików **`.arb`** (tłumaczenia) uruchom ponownie `flutter pub get` lub `flutter gen-l10n`, aby odświeżyć wygenerowane klasy w `lib/l10n/`.

Na GitHubie włącz **Actions** — po pushu do `main` odpala się **Flutter CI** (`analyze` + `flutter test`), szczegóły w **[TECHNICAL.md](TECHNICAL.md)** (sekcja GitHub Actions).

---

## Licencja i kontakt

- **Licencja:** *do uzupełnienia (np. MIT, własna, tylko portfolio)*  
- **Kontakt / portfolio:** *link do LinkedIn, strony lub e-mail*

---

*Ten plik jest przeznaczony dla **rekrutera i przeglądu portfolio**. Dokumentacja dla deweloperów znajduje się w **TECHNICAL.md**.*
