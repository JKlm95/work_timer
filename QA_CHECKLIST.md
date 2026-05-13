# QA — checklista ręczna (Work Timer + panel pracodawcy)

Zaznaczaj punkty przy wydaniu / przed demo. Wymaga działającego Firebase, wdrożonych **reguł** z repozytorium oraz skonfigurowanego panelu pracodawcy (jeśli testujesz widok „live”).

---

## Konto i profil

- [ ] Rejestracja nowego użytkownika (e-mail / hasło).
- [ ] Logowanie i wylogowanie (po wylogowaniu w `live/status`: `isOnline: false`, `timerState: idle`).
- [ ] Reset hasła (link z e-maila).
- [ ] **Ustawienia → Twój profil:** zapis imienia/nazwiska; komunikat sukcesu; ponowne wejście — dane się zgadzają.
- [ ] Po zapisie profilu: w Firestore `users/{uid}/profile/main` oraz wpis w `userEmailIndex` (jeśli dotyczy) są zaktualizowane.

---

## Projekty (workspaces)

- [ ] Utworzenie nowego projektu (nazwa wymagana).
- [ ] Edycja projektu: zmiana nazwy, koloru, waluty.
- [ ] **Stawka godzinowa:** ustawienie stawki > 0 — w `live/status` przy aktywnym projekcie pojawia się `hourlyRate` / `currency`; usunięcie stawki — pola **znika** (brak `0` jako fałszywej stawki).
- [ ] Włączenie **„Pola pod udostępnianie pracodawcy”** — zapis pól firmy / e-maili; dokument workspace w Firestore zawiera oczekiwane pola.
- [ ] Archiwum / przywrócenie projektu; timer **nie** startuje na zarchiwizowanym projekcie (komunikat).

---

## Timer (mobile)

- [ ] **Start** — stan `running`; po zapisie `live/status`: `timerState: running`, sensowne `sessionStartedAt` / `accumulatedSecondsBeforePause`.
- [ ] **Pauza** — `timerState: paused`; `accumulatedSecondsBeforePause` rośnie zgodnie z czasem do pauzy.
- [ ] **Wznowienie** — z powrotem `running`; nowy segment — `sessionStartedAt` odzwierciedla wznowienie.
- [ ] **Stop** — wpis w historii (`entries`); `live/status`: `idle`, sesja wyczyszczona; czas w raporcie/stats zgodny z oczekiwaniem.

---

## Offline i synchronizacja

- [ ] Z włączonym trybem offline / wyłączoną siecią: dodanie wpisu lub zmiana — dane lokalnie; **banner** o cache / kolejce (Timer / Historia).
- [ ] Powrót online: `syncPending` — wpisy i workspace’y trafiają do Firestore bez duplikatów (wg obserwacji w konsoli lub odświeżeniu listy).

---

## Panel pracodawcy (web)

- [ ] Dla śledzonego pracownika: widok **Online / Offline** zgadza się z aplikacją (foreground + idle vs timer w tle — patrz TECHNICAL § 4b).
- [ ] Przy **running**: panel pokazuje stan pracy / szacunek zgodny z kontraktem czasu (`sessionStartedAt` + `accumulated…`).
- [ ] Przy **paused**: brak naliczania bieżącego segmentu; `accumulated…` = pełna suma do pauzy.
- [ ] Po **stop**: w raporcie panelu / liście wpisów pojawia się nowa sesja z `entries`.

---

## Regresja UI

- [ ] Historia: filtry, edycja wpisu, eksport CSV/PDF (próbka).
- [ ] Statystyki / kalendarz: podstawowa nawigacja bez crashy.
- [ ] Widget Android (jeśli w zakresie): start/stop spójny z aplikacją.

---

*Kontrakt ścieżek danych: **[DATA_CONTRACT.md](DATA_CONTRACT.md)**. Architektura mobilki: **[TECHNICAL.md](TECHNICAL.md)**.*
