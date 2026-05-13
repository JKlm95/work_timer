# Kontrakt danych: aplikacja mobilna Work Timer ↔ panel pracodawcy

Ten dokument opisuje **ścieżki Firestore** i **podział odpowiedzialności** między aplikacją mobilną Flutter a panelem webowym pracodawcy (`work_timer_employer_panel`). Nie definiuje UI panelu — tylko dane.

---

## Ścieżki Firestore

| Ścieżka | Rola |
|---------|------|
| `users/{uid}/entries/{entryId}` | Historia sesji i wpisów ręcznych — **źródło prawdy** dla czasu przepracowanego, raportów i eksportów. |
| `users/{uid}/workspaces/{workspaceId}` | Projekty (nazwa, kolor, archiwum, stawka, udostępnienie pracodawcy itd.) — **źródło prawdy** dla konfiguracji projektów. |
| `users/{uid}/live/status` | **Stan na żywo** (online, stan timera, aktywny projekt, znaczniki sesji) — tylko podgląd dla panelu; **nie** zastępuje `entries`. Szczegóły pól: **[TECHNICAL.md](TECHNICAL.md)** § 4b. |
| `users/{uid}/profile/main` | Profil globalny pracownika (imię, nazwisko, e-mail wyświetlany w aplikacji) — **źródło prawdy** dla danych osobowych w kontekście konta. |
| `userEmailIndex/{emailLower}` | Indeks **lookup** UID i metadanych profilu po znormalizowanym adresie e-mail — ułatwia panelowi powiązanie konta pracownika z adresem. |

---

## Kto co zapisuje i czyta

### Zapisuje **mobile** (Flutter)

- `entries`, `workspaces` — przez `WorkRepository` / `FirebaseWorkStore` (w tym kolejka offline). **Wpisy czasu mogą też tworzyć i edytować panel pracodawcy** — patrz sekcja niżej „Wpisy `entries`”.
- `profile/main` — zapis z ekranu Ustawienia (`UserProfileCubit` / `UserProfileRepository`).
- `userEmailIndex/{emailLower}` — przy logowaniu i przy zapisie profilu (`UserEmailIndexService`); dokument musi być spójny z tokenem (patrz `firestore.rules`).
- `live/status` — `LiveStatusService` (logowanie, wylogowanie, zmiany timera, lifecycle, heartbeat).

### Czyta **głównie panel webowy**

- `entries`, `workspaces` — raporty, lista pracowników, szczegóły (zgodnie z uprawnieniami wdrożonymi w panelu i docelowo w regułach Firestore).
- `live/status` — widżety „Working / Paused / Online”, szacunek kwoty w locie (panel liczy z `sessionStartedAt` + `accumulatedSecondsBeforePause` wg **[TECHNICAL.md](TECHNICAL.md)** § 4b).
- `profile/main`, `userEmailIndex` — wyświetlanie imienia/nazwiska i powiązanie e-mail ↔ pracownik.

---

## Wpisy `entries` — mobile i panel pracodawcy

Ta sama kolekcja `users/{employeeUid}/entries/{entryId}` obsługuje:

| Źródło | Zachowanie |
|--------|------------|
| **Mobile** | Timer, ręczne wpisy, edycja; „usunięcie” w aplikacji to **soft delete** (`isDeleted: true`). |
| **Panel web** | CRUD po stronie pracodawcy (np. `createEmployeeEntry`, `updateEmployeeEntry`, `softDeleteEmployeeEntry`, `restoreEmployeeEntry`) — ten sam model pól co mobile, plus opcjonalne metadane. |

### Pola opcjonalne / techniczne z panelu

Mobile **ignoruje** przy parsowaniu (nie muszą być w modelu Dart), ale zostają w dokumencie przy `set(merge: true)` z aplikacji, o ile mobile ich nie nadpisuje tym samym kluczem: m.in. `editedAt`, `editedBy`, `createdBy`, `createdVia` (np. `"employer_panel"`). Wpis z `createdVia` jest normalnie widoczny w historii i statystykach, jeśli spełnia warunki widoczności.

### Soft delete

Usunięcie = `isDeleted: true` (nie usuwanie dokumentu). Mobile **nie** pokazuje takich wpisów w standardowej historii, **nie** sumuje ich w statystykach / kalendarzu / eksporcie ani w szacunkach rozliczeń (patrz `WorkEntry.countsInTimeAggregates`).

### `billingRatePercent`

Wpływa na szacunek kwot (`StatsService.buildBillingEstimate`, stawka × czas × procent / 100). Wartości dopuszczalne w regułach: **50, 80, 100, 150, 200**; **`null`** traktowane jak **100**; nieznana liczba całkowita → **100** (bezpieczny fallback).

### `entryType`

Brak pola lub nieznany string → fallback **`work`** (zgodnie z `entryTypeFromStorage`); dopasowanie **bez rozróżniania wielkości liter** (`VACATION` → urlop).

### Nieważny przedział czasu (`start >= end`)

Nie powinien wywalić aplikacji: czas trwania traktowany jak zero, wpis **pomijany** w sumach i raportach (nie wchodzi w `countsInTimeAggregates`).

### Konflikt offline vs panel

Przed wysłaniem wpisu z lokalnej kolejki `syncPending` pobierany jest aktualny dokument z serwera; jeśli **`updatedAt` na serwerze jest nowszy** niż w kolejce, mobile **nie wykonuje** `upsert` (wariant „wygrał panel / inna sesja”). Szczegół: `WorkRepository.syncPending` + `WorkRemoteStore.fetchEntry`.

---

## Źródło prawdy (podsumowanie)

| Obszar | Źródło prawdy | Uwagi |
|--------|----------------|--------|
| Historia czasu | `users/{uid}/entries` | Po **stop** timera mobile tworzy wpis tutaj; panel pokazuje raporty z tej kolekcji. |
| Konfiguracja projektów | `users/{uid}/workspaces` | Stawka, waluta, flagi udostępnienia pracodawcy. |
| Profil pracownika | `users/{uid}/profile/main` + indeks e-mail | Imię/nazwisko w UI mobile; panel może czytać to samo lub indeks. |
| „Co robi pracownik teraz” | `users/{uid}/live/status` | Odświeżane często; **nie** służy do rozliczeń końcowych — do tego służą `entries`. |

---

## Reguły bezpieczeństwa (Firestore)

Wdrożenie: **`firestore.rules`** w repozytorium.  
**MVP** może dopuszczać szeroki odczyt dla zalogowanych użytkowników (np. `live`, `userEmailIndex`) — **produkcja** powinna ograniczyć odczyt panelu pracodawcy do kont powiązanych z pracownikiem (np. lista śledzonych pracowników / członkostwo w organizacji). Szczegóły walidacji pól live: komentarz przy regule `users/{uid}/live` w pliku rules.

---

*Spójny opis techniczny aplikacji mobilnej: **[TECHNICAL.md](TECHNICAL.md)**. Checklistę testów ręcznych: **[QA_CHECKLIST.md](QA_CHECKLIST.md)**.*
