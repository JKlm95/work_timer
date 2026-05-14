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

## Zgody prawne (ToS / Privacy)

- [ ] **Nowy użytkownik** po pierwszym zalogowaniu: zamiast `HomeShell` pojawia się ekran zgód; linki Terms / Privacy otwierają się w przeglądarce (`url_launcher`).
- [ ] Checkbox wyłączony → przycisk **Continue** nieaktywny; po zaznaczeniu — aktywny; po zapisie — przejście do głównej aplikacji i dokument `users/{uid}/legal/consents` w Firestore (pola zgodne z **[DATA_CONTRACT.md](DATA_CONTRACT.md)**).
- [ ] **Wylogowanie** na ekranie zgód działa; ponowne logowanie — jeśli dokument już istnieje i jest poprawny, **pomija** ekran zgód.
- [ ] **Offline przy odczycie** zgód: komunikat + **Retry**; po przywróceniu sieci Retry przechodzi dalej (lub pokazuje ekran zgód jeśli nadal brak dokumentu).
- [ ] **Offline przy zapisie** zgód: komunikat błędu na ekranie; po powrocie online ponowna akceptacja zapisuje dokument (bez duplikacji logiki auth).
- [ ] **Uszkodzony dokument** (np. brak `acceptedAt` w danych): aplikacja traktuje jak brak zgody — ponowny ekran akceptacji (merge naprawia dokument przy zapisie).

---

## Projekty (workspaces)

- [ ] Utworzenie nowego projektu (nazwa wymagana).
- [ ] Edycja projektu: zmiana nazwy, koloru, waluty.
- [ ] **Stawka godzinowa:** ustawienie stawki > 0 — w `live/status` przy aktywnym projekcie pojawia się `hourlyRate` / `currency`; usunięcie stawki — pola **znika** (brak `0` jako fałszywej stawki).
- [ ] Włączenie **„Pola pod udostępnianie pracodawcy”** wymaga **nazwy firmy** i **służbowego e-maila** (walidacja formatu); brak pola e-maila pracodawcy w UI.
- [ ] Po zapisie: dokument `users/{uid}/workspaces/{id}` ma `isSharedWithEmployer`, `companyName`, `companySlug`, `employeeWorkEmail`, `employeeWorkEmailDomain`; **brak** aktywnego pola `linkedEmployerEmails` (legacy usuwane przez merge).
- [ ] **`employeeWorkEmailIndex/{workEmailLower}`:** po włączeniu sharingu z poprawnym mailem pojawia się / aktualizuje się dokument z `uid`, `workspaceIds` zawierającym id projektu, `domain` zgodnym z mailem.
- [ ] **Zmiana służbowego e-maila** przy projekcie: stary klucz indeksu traci `workspaceId`, nowy klucz go zyskuje (lub dokument pusty jest usuwany).
- [ ] **Wyłączenie udostępnienia** (`isSharedWithEmployer` off): w workspace znikają pola sharingu; indeks dla poprzedniego maila nie zawiera już tego `workspaceId` (dokument usunięty, jeśli lista pusta).
- [ ] **Slug firmy:** pusty slug przy edycji **nie zmienia** losowo istniejącego slug’a (stabilność); ręczna zmiana slug’a zapisuje się poprawnie.
- [ ] **Interpretacja panelu (poza mobile):** wpis `entries` widoczny dla pracodawcy tylko wtedy, gdy reguły biznesowe wiążą `entry.workspaceId` z workspace’em udostępnionym oraz dopasowanie **służbowego e-maila / domeny** do konta pracodawcy — **trackedEmployeeUids ≠ dostęp do wszystkich wpisów** (patrz **[DATA_CONTRACT.md](DATA_CONTRACT.md)**).
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
- [ ] Jeśli panel edytuje ten sam wpis co oczekuje w kolejce mobile: po syncu **wygrywa nowszy `updatedAt`** na serwerze (mobile nie nadpisuje starszą wersją z kolejki).

---

## Panel pracodawcy (web)

- [ ] Dla śledzonego pracownika: widok **Online / Offline** zgadza się z aplikacją (foreground + idle vs timer w tle — patrz TECHNICAL § 4b).
- [ ] Przy **running**: panel pokazuje stan pracy / szacunek zgodny z kontraktem czasu (`sessionStartedAt` + `accumulated…`).
- [ ] Przy **paused**: brak naliczania bieżącego segmentu; `accumulated…` = pełna suma do pauzy.
- [ ] Po **stop**: w raporcie panelu / liście wpisów pojawia się nowa sesja z `entries`.

### Wpisy czasu z panelu (`entries`)

- [ ] Utworzenie wpisu z panelu — widoczny w **Historii** mobile (odświeżenie / zakres dat), sumy w **Statystykach** zgodne (z uwzględnieniem `billingRatePercent` i typu wpisu).
- [ ] Edycja wpisu z panelu — mobile widzi zmiany po ponownym pobraniu danych.
- [ ] **Soft delete** z panelu (`isDeleted: true`) — wpis **znika** z historii / statystyk / eksportu na mobile.
- [ ] **Przywrócenie** wpisu (`isDeleted: false`) — wpis wraca do widoków i sum.
- [ ] Wpis z `createdVia: employer_panel` (lub innym) — **nie** jest ukrywany tylko z powodu tego pola.

---

## Regresja UI

- [ ] Historia: filtry, edycja wpisu, eksport CSV/PDF (próbka).
- [ ] Statystyki / kalendarz: podstawowa nawigacja bez crashy.
- [ ] Widget Android (jeśli w zakresie): start/stop spójny z aplikacją.

---

*Kontrakt ścieżek danych: **[DATA_CONTRACT.md](DATA_CONTRACT.md)**. Architektura mobilki: **[TECHNICAL.md](TECHNICAL.md)**.*
