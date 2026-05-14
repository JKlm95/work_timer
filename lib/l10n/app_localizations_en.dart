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
  String get navWorkspaces => 'Projects';

  @override
  String get navCalendar => 'Calendar';

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
  String get timerWorkspace => 'Project';

  @override
  String get timerWorkspaceLoading => 'Loading projects…';

  @override
  String get timerArchivedProjectSnack =>
      'This project is archived — start timer on an active project.';

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
      'Offline or server unavailable — showing cached data. Changes will sync when you are back online.';

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
  String get statsWorkspaceShare => 'Time by project';

  @override
  String get statsBillingTitle => 'Billing (estimate)';

  @override
  String get statsBillableHours => 'Billable time';

  @override
  String get statsNonBillableHours => 'Non-billable time';

  @override
  String get statsEstimatedEarnings => 'Estimated earnings by currency';

  @override
  String get statsEstimatedEarningsEmpty =>
      'Set an hourly rate on a project to see estimates.';

  @override
  String statsEstimatedEarningsLine(String code, String amount) {
    return '$code: $amount';
  }

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
    return 'Project: $name';
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
  String get historyExportMenuTooltip => 'Export filtered entries (CSV or PDF)';

  @override
  String get historyExportShareCsv => 'Share CSV…';

  @override
  String get historyExportSaveCsv => 'Save CSV to device';

  @override
  String get historyExportSharePdf => 'Share PDF…';

  @override
  String get historyExportSavePdf => 'Save PDF to device';

  @override
  String get historyExportSaveCsvDialogTitle => 'Save CSV file';

  @override
  String get historyExportSavePdfDialogTitle => 'Save PDF file';

  @override
  String get exportPdfTitle => 'Work Timer — sessions';

  @override
  String exportPdfMeta(String from, String to, String at) {
    return 'Range: $from — $to · Generated: $at';
  }

  @override
  String get exportHdrId => 'ID';

  @override
  String get exportHdrWorkspaceId => 'Project ID';

  @override
  String get exportHdrProject => 'Project';

  @override
  String get exportHdrStart => 'Start';

  @override
  String get exportHdrEnd => 'End';

  @override
  String get exportHdrDurationHm => 'Duration';

  @override
  String get exportHdrMode => 'Work mode';

  @override
  String get exportHdrEntryType => 'Entry type';

  @override
  String get exportHdrBillable => 'Billable';

  @override
  String get exportHdrBillingPercent => 'Billing %';

  @override
  String get exportHdrTask => 'Task / title';

  @override
  String get exportHdrNote => 'Note';

  @override
  String get exportBillableYes => 'Yes';

  @override
  String get exportBillableNo => 'No';

  @override
  String historyExportSaved(String fileName) {
    return 'Saved: $fileName';
  }

  @override
  String get historyExportSaveWebHint =>
      'In the browser, use Share for CSV / PDF — local save isn’t supported here.';

  @override
  String get historyExportEmpty =>
      'No entries to export for the current filters.';

  @override
  String get historyExportError => 'Could not create or share the file.';

  @override
  String get historyExportShareSubject => 'Work Timer export';

  @override
  String get historyEntryTypeLabel => 'Entry type';

  @override
  String get historyBillableLabel => 'Billable';

  @override
  String get historyBillingRateLabel => 'Billing rate (%)';

  @override
  String get historyTaskLabel => 'Task / title';

  @override
  String get historyNoteLabel => 'Note';

  @override
  String get historyAllEntryTypes => 'All types';

  @override
  String get historyBadgeDeleted => 'Removed';

  @override
  String get entryTypeWork => 'Work';

  @override
  String get entryTypeVacation => 'Vacation';

  @override
  String get entryTypeSickLeave => 'Sick leave';

  @override
  String get entryTypeBusinessTrip => 'Business trip';

  @override
  String get entryTypeOther => 'Other';

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
  String get projectsFab => 'Add project';

  @override
  String get projectsArchivedSection => 'Archived';

  @override
  String get projectsNewTitle => 'New project';

  @override
  String get projectsEditTitle => 'Edit project';

  @override
  String get projectsNameLabel => 'Project name';

  @override
  String get projectsArchived => 'Archived';

  @override
  String get projectsArchivedSubtitle => 'Hide from picker; block timer start.';

  @override
  String get projectsHourlyRate => 'Hourly rate (optional)';

  @override
  String get projectsCurrency => 'Currency';

  @override
  String get projectsCompanyName => 'Company name';

  @override
  String get projectsCompanySlugHint => 'Company slug (optional)';

  @override
  String get projectsShareEmployerProfileNamesHint =>
      'Employee first and last name are taken from Settings → Your profile.';

  @override
  String get projectsEmployeeWorkEmail => 'Work e-mail';

  @override
  String get projectsShareEmployer => 'Prepare fields for employer sharing';

  @override
  String get projectsShareEmployerSubtitle =>
      'When enabled, store your company name and work e-mail for this project. The employer panel can look you up by that work e-mail. Your display name comes from Settings → Your profile.';

  @override
  String get projectsWorkEmailRequired =>
      'Work e-mail is required when sharing with an employer.';

  @override
  String get projectsWorkEmailInvalid => 'Enter a valid work e-mail address.';

  @override
  String get projectsCompanyNameRequired =>
      'Company name is required when sharing with an employer.';

  @override
  String get projectsHourlyRatePanelHint =>
      'Without an hourly rate, billing estimates and employer live amounts may stay empty — time is still tracked.';

  @override
  String get projectsArchiveAction => 'Move to archived';

  @override
  String get projectsRestoreAction => 'Restore project';

  @override
  String get projectsColorSection => 'Color';

  @override
  String get projectsColorHexOptional => 'Custom color (hex, optional)';

  @override
  String get projectsValidationName => 'Enter a project name.';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get debriefTitle => 'Session summary';

  @override
  String get debriefTaskLabel => 'Task / title';

  @override
  String get debriefNoteLabel => 'Note';

  @override
  String get debriefBillableLabel => 'Billable';

  @override
  String get debriefDontShowAgain => 'Don\'t show again';

  @override
  String get settingsDebriefSection => 'After stopping timer';

  @override
  String get settingsDebriefToggle => 'Show session summary dialog';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProfileSection => 'Your profile';

  @override
  String get settingsProfileFirstName => 'First name';

  @override
  String get settingsProfileLastName => 'Last name';

  @override
  String get settingsProfileEmail => 'E-mail';

  @override
  String get settingsProfileSave => 'Save profile';

  @override
  String get settingsProfileNameRequired =>
      'Enter your first name and/or last name.';

  @override
  String get settingsProfileSaved => 'Profile saved.';

  @override
  String get settingsProfileIndexSyncFailed =>
      'Profile saved, but syncing the e-mail directory failed. Try again later.';

  @override
  String get settingsProfileEmployerPanelHint =>
      'Your name and e-mail are shown to employers when you share a project and in the employer dashboard lookup.';

  @override
  String get settingsOfflineSyncHint =>
      'Without network, the app keeps working on cached data. New entries and project changes are queued and sent to the cloud when you are back online.';

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

  @override
  String get debriefSkip => 'Skip';

  @override
  String get reportTitle => 'Project report';

  @override
  String reportPdfTitle(String project) {
    return 'Work Timer — $project';
  }

  @override
  String reportPdfMeta(String project, String from, String to, String at) {
    return 'Project: $project · Period: $from — $to · Generated: $at';
  }

  @override
  String get reportRangeToday => 'Today';

  @override
  String get reportRangeThisWeek => 'This week';

  @override
  String get reportRangeThisMonth => 'This month';

  @override
  String get reportRangePreviousMonth => 'Previous month';

  @override
  String get reportRangeCustom => 'Custom…';

  @override
  String get reportDateRangeSection => 'Date range';

  @override
  String get reportSummarySection => 'Summary';

  @override
  String get reportEntriesSection => 'Entries';

  @override
  String get reportTotalTime => 'Total time';

  @override
  String get reportEstimatedEarnings => 'Estimated earnings';

  @override
  String get reportEmptyTitle => 'No report data for this date range.';

  @override
  String get reportEmptyBody => 'Try another range or log time.';

  @override
  String get reportExportEmpty => 'Nothing to export for this range.';

  @override
  String get projectDetailMonthSummary => 'This month (estimate)';

  @override
  String get projectDetailUseForTimer => 'Go to timer with this project';

  @override
  String get projectDetailOpenReport => 'Open project report';

  @override
  String get statsOpenProjectReport => 'Project report';

  @override
  String get workspacesActiveDetailHint => 'Active for timer — tap for details';

  @override
  String get workspacesInactiveDetailHint =>
      'Tap for details · menu for quick actions';

  @override
  String get workspacesEmptyTitle => 'No projects yet';

  @override
  String get workspacesEmptyBody =>
      'Create your first project to start tracking time.';

  @override
  String get calendarDaySummaryTitle => 'Day summary';

  @override
  String get calendarDayEstimatedHint => 'Estimated earnings';

  @override
  String get calendarDayNoEntries => 'No entries on this day.';

  @override
  String get legalScreenTitle => 'Legal';

  @override
  String get legalIntro =>
      'To continue using Work Timer, you must accept the Terms of Service and the Privacy Policy.';

  @override
  String get legalTermsLink => 'Terms of Service';

  @override
  String get legalPrivacyLink => 'Privacy Policy';

  @override
  String get legalCheckboxLabel =>
      'I have read and agree to the Terms of Service and the Privacy Policy.';

  @override
  String get legalContinue => 'Continue';

  @override
  String get legalSaveFailed =>
      'Could not save your acceptance. Check your connection and try again.';

  @override
  String get legalCouldNotOpenLink => 'Could not open the link.';

  @override
  String get legalCheckFailed =>
      'We could not verify your saved acceptance. Check your connection.';

  @override
  String get legalRetry => 'Retry';
}
