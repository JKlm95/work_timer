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
  String get navWorkspaces => 'Workspace';

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
  String get timerWorkspace => 'Workspace';

  @override
  String get timerWorkspaceLoading => 'Ładowanie workspace…';

  @override
  String get timerLockedMode => 'Tryb zablokowany na czas sesji.';

  @override
  String get timerReady => 'Gotowy';

  @override
  String get timerRunning => 'Liczę…';

  @override
  String get timerPaused => 'Pauza';

  @override
  String get timerPlay => 'Play';

  @override
  String get timerPause => 'Pause';

  @override
  String get timerStop => 'Stop';

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
  String get statsWorkspaceShare => 'Udział workspace';

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
    return 'Workspace: $name';
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
