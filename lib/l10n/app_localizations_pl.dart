// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Work Timer';

  @override
  String get splashLoading => 'Ładowanie…';

  @override
  String get navTimer => 'Timer';

  @override
  String get navHistory => 'Historia';

  @override
  String get navStats => 'Statystyki';

  @override
  String get navWorkspaces => 'Projekty';

  @override
  String get navCalendar => 'Kalendarz';

  @override
  String get navSettings => 'Ustawienia';

  @override
  String get authTitle => 'Logowanie';

  @override
  String get authEmail => 'E-mail';

  @override
  String get authPassword => 'Hasło';

  @override
  String get authForgotPassword => 'Zapomniałeś hasła?';

  @override
  String get authSignIn => 'Zaloguj';

  @override
  String get authSignUp => 'Załóż konto';

  @override
  String get authToggleToSignIn => 'Masz konto? Zaloguj się';

  @override
  String get authToggleToSignUp => 'Nie masz konta? Załóż';

  @override
  String get authValEmailRequired => 'Podaj e-mail';

  @override
  String get authValEmailInvalid => 'Niepoprawny e-mail';

  @override
  String get authValPasswordShort => 'Hasło min. 6 znaków';

  @override
  String get authResetTitle => 'Reset hasła';

  @override
  String get authResetBody =>
      'Podaj adres e-mail konta — wyślemy link do ustawienia nowego hasła.';

  @override
  String get authResetSend => 'Wyślij link';

  @override
  String get authResetSnack =>
      'Jeśli konto istnieje, wysłaliśmy link do resetu na e-mail.';

  @override
  String get commonCancel => 'Anuluj';

  @override
  String get commonAdd => 'Dodaj';

  @override
  String get commonSave => 'Zapisz';

  @override
  String get timerWorkMode => 'Tryb pracy';

  @override
  String get timerWorkspace => 'Projekt';

  @override
  String get timerWorkspaceLoading => 'Ładowanie projektów…';

  @override
  String get timerArchivedProjectSnack =>
      'Ten projekt jest zarchiwizowany — wybierz aktywny, żeby wystartować timer.';

  @override
  String get timerLockedMode => 'Tryb zablokowany na czas sesji.';

  @override
  String get timerReady => 'Gotowy';

  @override
  String get timerRunning => 'Liczę…';

  @override
  String get timerPaused => 'Pauza';

  @override
  String get timerStatusIdle => 'Bezczynny';

  @override
  String get timerStatusRunning => 'W toku';

  @override
  String get timerStatusPaused => 'Wstrzymany';

  @override
  String get timerPlay => 'Play';

  @override
  String get timerPause => 'Pause';

  @override
  String get timerStop => 'Stop';

  @override
  String get timerActionStart => 'Start';

  @override
  String get timerActionResume => 'Wznów';

  @override
  String get dashboardToday => 'Dziś';

  @override
  String get dashboardThisWeek => 'Ten tydzień';

  @override
  String get dashboardLastSession => 'Ostatnia sesja';

  @override
  String get dashboardNoSessionsTitle => 'Brak sesji';

  @override
  String get dashboardNoSessionsBody =>
      'Uruchom timer lub dodaj wpis w Historii, żeby zobaczyć czas tutaj.';

  @override
  String get historyEmptyNoDataInRange => 'Brak sesji w tym okresie.';

  @override
  String get historyEmptyAdjustFilters =>
      'Zmień filtry lub wybierz inny zakres dat.';

  @override
  String get syncOfflineBanner =>
      'Widzisz dane z pamięci podręcznej. Synchronizacja może być ograniczona offline.';

  @override
  String get statsCardToday => 'Dziś';

  @override
  String get statsCardThisWeek => 'Ten tydzień';

  @override
  String get statsCardThisMonth => 'Ten miesiąc';

  @override
  String get statsAvgSession => 'Średnia sesja';

  @override
  String get statsSessionCount => 'Sesje';

  @override
  String get statsWeeklyOverview => 'Podsumowanie tygodnia';

  @override
  String get statsEmptyTitle => 'Brak statystyk';

  @override
  String get statsEmptyBody =>
      'Zapisz kilka sesji pracy, żeby zobaczyć podsumowania i wykresy.';

  @override
  String get settingsWidgetTitle => 'Widżet ekranu głównego';

  @override
  String get settingsWidgetDescription =>
      'Steruj timerem prosto z widżetu na ekranie głównym Androida.';

  @override
  String get workModeRemote => 'Remote';

  @override
  String get workModeOffice => 'Biuro';

  @override
  String get statsWeek => 'Tydzień';

  @override
  String get statsMonth => 'Miesiąc';

  @override
  String get statsBasicTitle => 'Podstawowe statystyki';

  @override
  String statsTotal(String duration) {
    return 'Suma: $duration';
  }

  @override
  String statsActiveDays(int count) {
    return 'Dni aktywne: $count';
  }

  @override
  String statsAvgPerDay(String duration) {
    return 'Średnio / aktywny dzień: $duration';
  }

  @override
  String get statsDailyChart => 'Wykres dzienny';

  @override
  String get statsWorkspaceShare => 'Czas wg projektu';

  @override
  String get statsBillingTitle => 'Rozliczenia (szacunek)';

  @override
  String get statsBillableHours => 'Czas rozliczalny';

  @override
  String get statsNonBillableHours => 'Czas nierozliczalny';

  @override
  String get statsEstimatedEarnings => 'Szacowany przychód wg waluty';

  @override
  String get statsEstimatedEarningsEmpty =>
      'Ustaw stawkę przy projekcie, żeby zobaczyć szacunki.';

  @override
  String statsEstimatedEarningsLine(String code, String amount) {
    return '$code: $amount';
  }

  @override
  String get statsNoData => 'Brak danych';

  @override
  String get statsAllWorkspaces => 'Wszystkie';

  @override
  String get historyFilters => 'Filtry';

  @override
  String get historyWorkMode => 'Tryb pracy';

  @override
  String get historyAllModes => 'Wszystkie';

  @override
  String historyWorkspaceLabel(String name) {
    return 'Projekt: $name';
  }

  @override
  String historyFilteredSum(String duration) {
    return 'W filtrze: $duration';
  }

  @override
  String get historyEmptyFiltered => 'Brak wpisów dla wybranych filtrów.';

  @override
  String get historyAddEntry => 'Dodaj wpis';

  @override
  String get historyEditEntry => 'Edytuj wpis';

  @override
  String get historyValEndAfterStart => 'Godzina końca musi być po starcie.';

  @override
  String historyStart(String time) {
    return 'Start: $time';
  }

  @override
  String historyEnd(String time) {
    return 'Koniec: $time';
  }

  @override
  String get historyMenuEdit => 'Edytuj';

  @override
  String get historyMenuDelete => 'Usuń';

  @override
  String get historyExportCsv => 'Eksport do Excela (CSV)';

  @override
  String get historyExportCsvTooltip =>
      'Eksport przefiltrowanych wpisów jako CSV';

  @override
  String get historyExportShare => 'Udostępnij…';

  @override
  String get historyExportSaveLocal => 'Zapisz na urządzeniu';

  @override
  String get historyExportSaveDialogTitle => 'Zapisz plik CSV';

  @override
  String historyExportSaved(String fileName) {
    return 'Zapisano: $fileName';
  }

  @override
  String get historyExportSaveWebHint =>
      'W przeglądarce użyj „Udostępnij” — lokalnego zapisu tu nie ma.';

  @override
  String get historyExportEmpty =>
      'Brak wpisów do eksportu przy wybranych filtrach.';

  @override
  String get historyExportError =>
      'Nie udało się utworzyć lub udostępnić pliku.';

  @override
  String get historyExportShareSubject => 'Eksport Work Timer';

  @override
  String get historyEntryTypeLabel => 'Typ wpisu';

  @override
  String get historyBillableLabel => 'Rozliczalny';

  @override
  String get historyTaskLabel => 'Zadanie / tytuł';

  @override
  String get historyNoteLabel => 'Notatka';

  @override
  String get historyAllEntryTypes => 'Wszystkie typy';

  @override
  String get entryTypeWork => 'Praca';

  @override
  String get entryTypeVacation => 'Urlop';

  @override
  String get entryTypeSickLeave => 'L4 / chorobowe';

  @override
  String get entryTypeBusinessTrip => 'Delegacja';

  @override
  String get entryTypeOther => 'Inne';

  @override
  String get workspacesNewTitle => 'Nowy workspace';

  @override
  String get workspacesRenameTitle => 'Zmień nazwę';

  @override
  String get workspacesNameLabel => 'Nazwa';

  @override
  String get workspacesActive => 'Aktywny';

  @override
  String get workspacesInactive => 'Nieaktywny';

  @override
  String get workspacesFab => 'Dodaj workspace';

  @override
  String get projectsFab => 'Dodaj projekt';

  @override
  String get projectsArchivedSection => 'Zarchiwizowane';

  @override
  String get projectsNewTitle => 'Nowy projekt';

  @override
  String get projectsEditTitle => 'Edycja projektu';

  @override
  String get projectsNameLabel => 'Nazwa projektu';

  @override
  String get projectsArchived => 'Zarchiwizowany';

  @override
  String get projectsArchivedSubtitle =>
      'Ukrywa z listy; blokuje start timera.';

  @override
  String get projectsHourlyRate => 'Stawka godzinowa (opcjonalnie)';

  @override
  String get projectsCurrency => 'Waluta';

  @override
  String get projectsCompanyName => 'Nazwa firmy';

  @override
  String get projectsCompanySlugHint => 'Slug firmy (opcjonalnie)';

  @override
  String get projectsEmployeeFirstName => 'Imię';

  @override
  String get projectsEmployeeLastName => 'Nazwisko';

  @override
  String get projectsEmployeeWorkEmail => 'Służbowy e-mail';

  @override
  String get projectsEmployerEmailsHint =>
      'E-maile pracodawcy (rozdziel przecinkiem)';

  @override
  String get projectsShareEmployer => 'Pola pod udostępnianie pracodawcy';

  @override
  String get projectsArchiveAction => 'Archiwizuj';

  @override
  String get projectsRestoreAction => 'Przywróć';

  @override
  String get projectsColorSection => 'Kolor';

  @override
  String get projectsColorHexOptional => 'Własny kolor (hex, opcjonalnie)';

  @override
  String get projectsValidationName => 'Podaj nazwę projektu.';

  @override
  String get calendarTitle => 'Kalendarz';

  @override
  String get debriefTitle => 'Podsumowanie sesji';

  @override
  String get debriefTaskLabel => 'Zadanie / tytuł';

  @override
  String get debriefNoteLabel => 'Notatka';

  @override
  String get debriefBillableLabel => 'Rozliczalne';

  @override
  String get debriefDontShowAgain => 'Nie pokazuj ponownie';

  @override
  String get settingsDebriefSection => 'Po zatrzymaniu timera';

  @override
  String get settingsDebriefToggle => 'Pokaż dialog podsumowania';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get settingsAppearance => 'Wygląd';

  @override
  String get settingsLanguage => 'Język';

  @override
  String get settingsLanguageSystem => 'Domyślny systemu';

  @override
  String get settingsLanguagePl => 'Polski';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsTheme => 'Motyw';

  @override
  String get settingsThemeLight => 'Jasny';

  @override
  String get settingsThemeDark => 'Ciemny';

  @override
  String get settingsThemeSystem => 'Domyślny systemu';

  @override
  String get signOut => 'Wyloguj';

  @override
  String get errorAuthInvalidEmail => 'Nieprawidłowy adres e-mail.';

  @override
  String get errorAuthUserNotFound => 'Brak konta z tym adresem e-mail.';

  @override
  String get errorAuthWrongPassword => 'Nieprawidłowe hasło.';

  @override
  String get errorAuthEmailInUse => 'Ten e-mail jest już zarejestrowany.';

  @override
  String get errorAuthWeakPassword => 'Hasło jest zbyt słabe.';

  @override
  String get errorAuthNetwork => 'Błąd sieci. Sprawdź połączenie.';

  @override
  String get errorAuthTooManyRequests => 'Zbyt wiele prób. Spróbuj później.';

  @override
  String get errorAuthUserDisabled => 'To konto zostało wyłączone.';

  @override
  String get errorAuthInvalidCredential => 'Nieprawidłowy e-mail lub hasło.';

  @override
  String get errorAuthOperationNotAllowed =>
      'Ta metoda logowania nie jest włączona.';

  @override
  String get errorAuthGeneric =>
      'Nie udało się wykonać operacji. Spróbuj ponownie.';
}
