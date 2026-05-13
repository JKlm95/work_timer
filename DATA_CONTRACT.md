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

### Zapisuje **wyłącznie mobile** (Flutter)

- `entries`, `workspaces` — przez `WorkRepository` / `FirebaseWorkStore` (w tym kolejka offline).
- `profile/main` — zapis z ekranu Ustawienia (`UserProfileCubit` / `UserProfileRepository`).
- `userEmailIndex/{emailLower}` — przy logowaniu i przy zapisie profilu (`UserEmailIndexService`); dokument musi być spójny z tokenem (patrz `firestore.rules`).
- `live/status` — `LiveStatusService` (logowanie, wylogowanie, zmiany timera, lifecycle, heartbeat).

### Czyta **głównie panel webowy**

- `entries`, `workspaces` — raporty, lista pracowników, szczegóły (zgodnie z uprawnieniami wdrożonymi w panelu i docelowo w regułach Firestore).
- `live/status` — widżety „Working / Paused / Online”, szacunek kwoty w locie (panel liczy z `sessionStartedAt` + `accumulatedSecondsBeforePause` wg **[TECHNICAL.md](TECHNICAL.md)** § 4b).
- `profile/main`, `userEmailIndex` — wyświetlanie imienia/nazwiska i powiązanie e-mail ↔ pracownik.

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
