// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Work Timer';

  @override
  String get splashLoading => 'Loading…';

  @override
  String get navTimer => 'Timer';

  @override
  String get navHistory => 'History';

  @override
  String get navStats => 'Stats';

  @override
  String get navWorkspaces => 'Workspaces';

  @override
  String get navSettings => 'Settings';

  @override
  String get authTitle => 'Sign in';

  @override
  String get authEmail => 'E-mail';

  @override
  String get authPassword => 'Password';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Create account';

  @override
  String get authToggleToSignIn => 'Have an account? Sign in';

  @override
  String get authToggleToSignUp => 'No account? Create one';

  @override
  String get authValEmailRequired => 'Enter e-mail';

  @override
  String get authValEmailInvalid => 'Invalid e-mail';

  @override
  String get authValPasswordShort => 'Password at least 6 characters';

  @override
  String get authResetTitle => 'Reset password';

  @override
  String get authResetBody =>
      'Enter the account e-mail — we’ll send a link to set a new password.';

  @override
  String get authResetSend => 'Send link';

  @override
  String get authResetSnack =>
      'If the account exists, we sent a reset link to the e-mail.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonSave => 'Save';

  @override
  String get timerWorkMode => 'Work mode';

  @override
  String get timerWorkspace => 'Workspace';

  @override
  String get timerWorkspaceLoading => 'Loading workspaces…';

  @override
  String get timerLockedMode => 'Mode is locked for the session.';

  @override
  String get timerReady => 'Ready';

  @override
  String get timerRunning => 'Running…';

  @override
  String get timerPaused => 'Paused';

  @override
  String get timerStatusIdle => 'Idle';

  @override
  String get timerStatusRunning => 'Running';

  @override
  String get timerStatusPaused => 'Paused';

  @override
  String get timerPlay => 'Play';

  @override
  String get timerPause => 'Pause';

  @override
  String get timerStop => 'Stop';

  @override
  String get timerActionStart => 'Start';

  @override
  String get timerActionResume => 'Resume';

  @override
  String get dashboardToday => 'Today';

  @override
  String get dashboardThisWeek => 'This week';

  @override
  String get dashboardLastSession => 'Last session';

  @override
  String get dashboardNoSessionsTitle => 'No sessions yet';

  @override
  String get dashboardNoSessionsBody =>
      'Start the timer or add an entry from History to see your time here.';

  @override
  String get historyEmptyNoDataInRange => 'No sessions in this period.';

  @override
  String get historyEmptyAdjustFilters =>
      'Try adjusting filters or pick another date range.';

  @override
  String get syncOfflineBanner =>
      'Showing cached data. Sync may be limited while offline.';

  @override
  String get statsCardToday => 'Today';

  @override
  String get statsCardThisWeek => 'This week';

  @override
  String get statsCardThisMonth => 'This month';

  @override
  String get statsAvgSession => 'Average session';

  @override
  String get statsSessionCount => 'Sessions';

  @override
  String get statsWeeklyOverview => 'Week overview';

  @override
  String get statsEmptyTitle => 'No statistics yet';

  @override
  String get statsEmptyBody =>
      'Log some work sessions to see summaries and charts here.';

  @override
  String get settingsWidgetTitle => 'Home screen widget';

  @override
  String get settingsWidgetDescription =>
      'Control the timer directly from your Android home screen widget.';

  @override
  String get workModeRemote => 'Remote';

  @override
  String get workModeOffice => 'Office';

  @override
  String get statsWeek => 'Week';

  @override
  String get statsMonth => 'Month';

  @override
  String get statsBasicTitle => 'Basic stats';

  @override
  String statsTotal(String duration) {
    return 'Total: $duration';
  }

  @override
  String statsActiveDays(int count) {
    return 'Active days: $count';
  }

  @override
  String statsAvgPerDay(String duration) {
    return 'Average / active day: $duration';
  }

  @override
  String get statsDailyChart => 'Daily chart';

  @override
  String get statsWorkspaceShare => 'Workspace share';

  @override
  String get statsNoData => 'No data';

  @override
  String get statsAllWorkspaces => 'All';

  @override
  String get historyFilters => 'Filters';

  @override
  String get historyWorkMode => 'Work mode';

  @override
  String get historyAllModes => 'All';

  @override
  String historyWorkspaceLabel(String name) {
    return 'Workspace: $name';
  }

  @override
  String historyFilteredSum(String duration) {
    return 'In filter: $duration';
  }

  @override
  String get historyEmptyFiltered => 'No entries for the selected filters.';

  @override
  String get historyAddEntry => 'Add entry';

  @override
  String get historyEditEntry => 'Edit entry';

  @override
  String get historyValEndAfterStart => 'End time must be after start.';

  @override
  String historyStart(String time) {
    return 'Start: $time';
  }

  @override
  String historyEnd(String time) {
    return 'End: $time';
  }

  @override
  String get historyMenuEdit => 'Edit';

  @override
  String get historyMenuDelete => 'Delete';

  @override
  String get historyExportCsv => 'Export for Excel (CSV)';

  @override
  String get historyExportCsvTooltip =>
      'Share filtered entries as a CSV file (opens in Excel)';

  @override
  String get historyExportEmpty =>
      'No entries to export for the current filters.';

  @override
  String get historyExportError => 'Could not create or share the file.';

  @override
  String get historyExportShareSubject => 'Work Timer export';

  @override
  String get workspacesNewTitle => 'New workspace';

  @override
  String get workspacesRenameTitle => 'Rename';

  @override
  String get workspacesNameLabel => 'Name';

  @override
  String get workspacesActive => 'Active';

  @override
  String get workspacesInactive => 'Inactive';

  @override
  String get workspacesFab => 'Add workspace';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsLanguagePl => 'Polski';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System default';

  @override
  String get signOut => 'Sign out';

  @override
  String get errorAuthInvalidEmail => 'Invalid e-mail address.';

  @override
  String get errorAuthUserNotFound => 'No account with this e-mail.';

  @override
  String get errorAuthWrongPassword => 'Wrong password.';

  @override
  String get errorAuthEmailInUse => 'This e-mail is already registered.';

  @override
  String get errorAuthWeakPassword => 'Password is too weak.';

  @override
  String get errorAuthNetwork => 'Network error. Check your connection.';

  @override
  String get errorAuthTooManyRequests => 'Too many attempts. Try again later.';

  @override
  String get errorAuthUserDisabled => 'This account has been disabled.';

  @override
  String get errorAuthInvalidCredential => 'Incorrect e-mail or password.';

  @override
  String get errorAuthOperationNotAllowed =>
      'This sign-in method is not enabled.';

  @override
  String get errorAuthGeneric => 'Could not complete the request. Try again.';
}
