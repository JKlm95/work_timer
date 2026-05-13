import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Timer'**
  String get appTitle;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get splashLoading;

  /// No description provided for @navTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get navTimer;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @navWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get navWorkspaces;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authTitle;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUp;

  /// No description provided for @authToggleToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Have an account? Sign in'**
  String get authToggleToSignIn;

  /// No description provided for @authToggleToSignUp.
  ///
  /// In en, this message translates to:
  /// **'No account? Create one'**
  String get authToggleToSignUp;

  /// No description provided for @authValEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter e-mail'**
  String get authValEmailRequired;

  /// No description provided for @authValEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid e-mail'**
  String get authValEmailInvalid;

  /// No description provided for @authValPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Password at least 6 characters'**
  String get authValPasswordShort;

  /// No description provided for @authResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetTitle;

  /// No description provided for @authResetBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the account e-mail — we’ll send a link to set a new password.'**
  String get authResetBody;

  /// No description provided for @authResetSend.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get authResetSend;

  /// No description provided for @authResetSnack.
  ///
  /// In en, this message translates to:
  /// **'If the account exists, we sent a reset link to the e-mail.'**
  String get authResetSnack;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @timerWorkMode.
  ///
  /// In en, this message translates to:
  /// **'Work mode'**
  String get timerWorkMode;

  /// No description provided for @timerWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get timerWorkspace;

  /// No description provided for @timerWorkspaceLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading projects…'**
  String get timerWorkspaceLoading;

  /// No description provided for @timerArchivedProjectSnack.
  ///
  /// In en, this message translates to:
  /// **'This project is archived — start timer on an active project.'**
  String get timerArchivedProjectSnack;

  /// No description provided for @timerLockedMode.
  ///
  /// In en, this message translates to:
  /// **'Mode is locked for the session.'**
  String get timerLockedMode;

  /// No description provided for @timerReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get timerReady;

  /// No description provided for @timerRunning.
  ///
  /// In en, this message translates to:
  /// **'Running…'**
  String get timerRunning;

  /// No description provided for @timerPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get timerPaused;

  /// No description provided for @timerStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get timerStatusIdle;

  /// No description provided for @timerStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get timerStatusRunning;

  /// No description provided for @timerStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get timerStatusPaused;

  /// No description provided for @timerPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get timerPlay;

  /// No description provided for @timerPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get timerPause;

  /// No description provided for @timerStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get timerStop;

  /// No description provided for @timerActionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get timerActionStart;

  /// No description provided for @timerActionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get timerActionResume;

  /// No description provided for @dashboardToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardToday;

  /// No description provided for @dashboardThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get dashboardThisWeek;

  /// No description provided for @dashboardLastSession.
  ///
  /// In en, this message translates to:
  /// **'Last session'**
  String get dashboardLastSession;

  /// No description provided for @dashboardNoSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get dashboardNoSessionsTitle;

  /// No description provided for @dashboardNoSessionsBody.
  ///
  /// In en, this message translates to:
  /// **'Start the timer or add an entry from History to see your time here.'**
  String get dashboardNoSessionsBody;

  /// No description provided for @historyEmptyNoDataInRange.
  ///
  /// In en, this message translates to:
  /// **'No sessions in this period.'**
  String get historyEmptyNoDataInRange;

  /// No description provided for @historyEmptyAdjustFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting filters or pick another date range.'**
  String get historyEmptyAdjustFilters;

  /// No description provided for @syncOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline or server unavailable — showing cached data. Changes will sync when you are back online.'**
  String get syncOfflineBanner;

  /// No description provided for @statsCardToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statsCardToday;

  /// No description provided for @statsCardThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get statsCardThisWeek;

  /// No description provided for @statsCardThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get statsCardThisMonth;

  /// No description provided for @statsAvgSession.
  ///
  /// In en, this message translates to:
  /// **'Average session'**
  String get statsAvgSession;

  /// No description provided for @statsSessionCount.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get statsSessionCount;

  /// No description provided for @statsWeeklyOverview.
  ///
  /// In en, this message translates to:
  /// **'Week overview'**
  String get statsWeeklyOverview;

  /// No description provided for @statsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No statistics yet'**
  String get statsEmptyTitle;

  /// No description provided for @statsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Log some work sessions to see summaries and charts here.'**
  String get statsEmptyBody;

  /// No description provided for @settingsWidgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Home screen widget'**
  String get settingsWidgetTitle;

  /// No description provided for @settingsWidgetDescription.
  ///
  /// In en, this message translates to:
  /// **'Control the timer directly from your Android home screen widget.'**
  String get settingsWidgetDescription;

  /// No description provided for @workModeRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get workModeRemote;

  /// No description provided for @workModeOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get workModeOffice;

  /// No description provided for @statsWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get statsWeek;

  /// No description provided for @statsMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get statsMonth;

  /// No description provided for @statsBasicTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic stats'**
  String get statsBasicTitle;

  /// No description provided for @statsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {duration}'**
  String statsTotal(String duration);

  /// No description provided for @statsActiveDays.
  ///
  /// In en, this message translates to:
  /// **'Active days: {count}'**
  String statsActiveDays(int count);

  /// No description provided for @statsAvgPerDay.
  ///
  /// In en, this message translates to:
  /// **'Average / active day: {duration}'**
  String statsAvgPerDay(String duration);

  /// No description provided for @statsDailyChart.
  ///
  /// In en, this message translates to:
  /// **'Daily chart'**
  String get statsDailyChart;

  /// No description provided for @statsWorkspaceShare.
  ///
  /// In en, this message translates to:
  /// **'Time by project'**
  String get statsWorkspaceShare;

  /// No description provided for @statsBillingTitle.
  ///
  /// In en, this message translates to:
  /// **'Billing (estimate)'**
  String get statsBillingTitle;

  /// No description provided for @statsBillableHours.
  ///
  /// In en, this message translates to:
  /// **'Billable time'**
  String get statsBillableHours;

  /// No description provided for @statsNonBillableHours.
  ///
  /// In en, this message translates to:
  /// **'Non-billable time'**
  String get statsNonBillableHours;

  /// No description provided for @statsEstimatedEarnings.
  ///
  /// In en, this message translates to:
  /// **'Estimated earnings by currency'**
  String get statsEstimatedEarnings;

  /// No description provided for @statsEstimatedEarningsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Set an hourly rate on a project to see estimates.'**
  String get statsEstimatedEarningsEmpty;

  /// No description provided for @statsEstimatedEarningsLine.
  ///
  /// In en, this message translates to:
  /// **'{code}: {amount}'**
  String statsEstimatedEarningsLine(String code, String amount);

  /// No description provided for @statsNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get statsNoData;

  /// No description provided for @statsAllWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get statsAllWorkspaces;

  /// No description provided for @historyFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get historyFilters;

  /// No description provided for @historyWorkMode.
  ///
  /// In en, this message translates to:
  /// **'Work mode'**
  String get historyWorkMode;

  /// No description provided for @historyAllModes.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get historyAllModes;

  /// No description provided for @historyWorkspaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Project: {name}'**
  String historyWorkspaceLabel(String name);

  /// No description provided for @historyFilteredSum.
  ///
  /// In en, this message translates to:
  /// **'In filter: {duration}'**
  String historyFilteredSum(String duration);

  /// No description provided for @historyEmptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'No entries for the selected filters.'**
  String get historyEmptyFiltered;

  /// No description provided for @historyAddEntry.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get historyAddEntry;

  /// No description provided for @historyEditEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get historyEditEntry;

  /// No description provided for @historyValEndAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start.'**
  String get historyValEndAfterStart;

  /// No description provided for @historyStart.
  ///
  /// In en, this message translates to:
  /// **'Start: {time}'**
  String historyStart(String time);

  /// No description provided for @historyEnd.
  ///
  /// In en, this message translates to:
  /// **'End: {time}'**
  String historyEnd(String time);

  /// No description provided for @historyMenuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get historyMenuEdit;

  /// No description provided for @historyMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get historyMenuDelete;

  /// No description provided for @historyExportMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export filtered entries (CSV or PDF)'**
  String get historyExportMenuTooltip;

  /// No description provided for @historyExportShareCsv.
  ///
  /// In en, this message translates to:
  /// **'Share CSV…'**
  String get historyExportShareCsv;

  /// No description provided for @historyExportSaveCsv.
  ///
  /// In en, this message translates to:
  /// **'Save CSV to device'**
  String get historyExportSaveCsv;

  /// No description provided for @historyExportSharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF…'**
  String get historyExportSharePdf;

  /// No description provided for @historyExportSavePdf.
  ///
  /// In en, this message translates to:
  /// **'Save PDF to device'**
  String get historyExportSavePdf;

  /// No description provided for @historyExportSaveCsvDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save CSV file'**
  String get historyExportSaveCsvDialogTitle;

  /// No description provided for @historyExportSavePdfDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save PDF file'**
  String get historyExportSavePdfDialogTitle;

  /// No description provided for @exportPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Timer — sessions'**
  String get exportPdfTitle;

  /// No description provided for @exportPdfMeta.
  ///
  /// In en, this message translates to:
  /// **'Range: {from} — {to} · Generated: {at}'**
  String exportPdfMeta(String from, String to, String at);

  /// No description provided for @exportHdrId.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get exportHdrId;

  /// No description provided for @exportHdrWorkspaceId.
  ///
  /// In en, this message translates to:
  /// **'Project ID'**
  String get exportHdrWorkspaceId;

  /// No description provided for @exportHdrProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get exportHdrProject;

  /// No description provided for @exportHdrStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get exportHdrStart;

  /// No description provided for @exportHdrEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get exportHdrEnd;

  /// No description provided for @exportHdrDurationHm.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get exportHdrDurationHm;

  /// No description provided for @exportHdrMode.
  ///
  /// In en, this message translates to:
  /// **'Work mode'**
  String get exportHdrMode;

  /// No description provided for @exportHdrEntryType.
  ///
  /// In en, this message translates to:
  /// **'Entry type'**
  String get exportHdrEntryType;

  /// No description provided for @exportHdrBillable.
  ///
  /// In en, this message translates to:
  /// **'Billable'**
  String get exportHdrBillable;

  /// No description provided for @exportHdrBillingPercent.
  ///
  /// In en, this message translates to:
  /// **'Billing %'**
  String get exportHdrBillingPercent;

  /// No description provided for @exportHdrTask.
  ///
  /// In en, this message translates to:
  /// **'Task / title'**
  String get exportHdrTask;

  /// No description provided for @exportHdrNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get exportHdrNote;

  /// No description provided for @exportBillableYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get exportBillableYes;

  /// No description provided for @exportBillableNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get exportBillableNo;

  /// No description provided for @historyExportSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: {fileName}'**
  String historyExportSaved(String fileName);

  /// No description provided for @historyExportSaveWebHint.
  ///
  /// In en, this message translates to:
  /// **'In the browser, use Share for CSV / PDF — local save isn’t supported here.'**
  String get historyExportSaveWebHint;

  /// No description provided for @historyExportEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries to export for the current filters.'**
  String get historyExportEmpty;

  /// No description provided for @historyExportError.
  ///
  /// In en, this message translates to:
  /// **'Could not create or share the file.'**
  String get historyExportError;

  /// No description provided for @historyExportShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Work Timer export'**
  String get historyExportShareSubject;

  /// No description provided for @historyEntryTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Entry type'**
  String get historyEntryTypeLabel;

  /// No description provided for @historyBillableLabel.
  ///
  /// In en, this message translates to:
  /// **'Billable'**
  String get historyBillableLabel;

  /// No description provided for @historyBillingRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Billing rate (%)'**
  String get historyBillingRateLabel;

  /// No description provided for @historyTaskLabel.
  ///
  /// In en, this message translates to:
  /// **'Task / title'**
  String get historyTaskLabel;

  /// No description provided for @historyNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get historyNoteLabel;

  /// No description provided for @historyAllEntryTypes.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get historyAllEntryTypes;

  /// No description provided for @historyBadgeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get historyBadgeDeleted;

  /// No description provided for @entryTypeWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get entryTypeWork;

  /// No description provided for @entryTypeVacation.
  ///
  /// In en, this message translates to:
  /// **'Vacation'**
  String get entryTypeVacation;

  /// No description provided for @entryTypeSickLeave.
  ///
  /// In en, this message translates to:
  /// **'Sick leave'**
  String get entryTypeSickLeave;

  /// No description provided for @entryTypeBusinessTrip.
  ///
  /// In en, this message translates to:
  /// **'Business trip'**
  String get entryTypeBusinessTrip;

  /// No description provided for @entryTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get entryTypeOther;

  /// No description provided for @workspacesNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New workspace'**
  String get workspacesNewTitle;

  /// No description provided for @workspacesRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get workspacesRenameTitle;

  /// No description provided for @workspacesNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get workspacesNameLabel;

  /// No description provided for @workspacesActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get workspacesActive;

  /// No description provided for @workspacesInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get workspacesInactive;

  /// No description provided for @workspacesFab.
  ///
  /// In en, this message translates to:
  /// **'Add workspace'**
  String get workspacesFab;

  /// No description provided for @projectsFab.
  ///
  /// In en, this message translates to:
  /// **'Add project'**
  String get projectsFab;

  /// No description provided for @projectsArchivedSection.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get projectsArchivedSection;

  /// No description provided for @projectsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get projectsNewTitle;

  /// No description provided for @projectsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit project'**
  String get projectsEditTitle;

  /// No description provided for @projectsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectsNameLabel;

  /// No description provided for @projectsArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get projectsArchived;

  /// No description provided for @projectsArchivedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide from picker; block timer start.'**
  String get projectsArchivedSubtitle;

  /// No description provided for @projectsHourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Hourly rate (optional)'**
  String get projectsHourlyRate;

  /// No description provided for @projectsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get projectsCurrency;

  /// No description provided for @projectsCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get projectsCompanyName;

  /// No description provided for @projectsCompanySlugHint.
  ///
  /// In en, this message translates to:
  /// **'Company slug (optional)'**
  String get projectsCompanySlugHint;

  /// No description provided for @projectsShareEmployerProfileNamesHint.
  ///
  /// In en, this message translates to:
  /// **'Employee first and last name are taken from Settings → Your profile.'**
  String get projectsShareEmployerProfileNamesHint;

  /// No description provided for @projectsEmployeeWorkEmail.
  ///
  /// In en, this message translates to:
  /// **'Work e-mail'**
  String get projectsEmployeeWorkEmail;

  /// No description provided for @projectsEmployerEmailsHint.
  ///
  /// In en, this message translates to:
  /// **'Employer e-mails (comma-separated)'**
  String get projectsEmployerEmailsHint;

  /// No description provided for @projectsShareEmployer.
  ///
  /// In en, this message translates to:
  /// **'Prepare fields for employer sharing'**
  String get projectsShareEmployer;

  /// No description provided for @projectsShareEmployerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When enabled, company and contact fields are stored with the project so an employer panel can match this project to your account. Your display name comes from Settings → Your profile.'**
  String get projectsShareEmployerSubtitle;

  /// No description provided for @projectsHourlyRatePanelHint.
  ///
  /// In en, this message translates to:
  /// **'Without an hourly rate, billing estimates and employer live amounts may stay empty — time is still tracked.'**
  String get projectsHourlyRatePanelHint;

  /// No description provided for @projectsArchiveAction.
  ///
  /// In en, this message translates to:
  /// **'Move to archived'**
  String get projectsArchiveAction;

  /// No description provided for @projectsRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore project'**
  String get projectsRestoreAction;

  /// No description provided for @projectsColorSection.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get projectsColorSection;

  /// No description provided for @projectsColorHexOptional.
  ///
  /// In en, this message translates to:
  /// **'Custom color (hex, optional)'**
  String get projectsColorHexOptional;

  /// No description provided for @projectsValidationName.
  ///
  /// In en, this message translates to:
  /// **'Enter a project name.'**
  String get projectsValidationName;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @debriefTitle.
  ///
  /// In en, this message translates to:
  /// **'Session summary'**
  String get debriefTitle;

  /// No description provided for @debriefTaskLabel.
  ///
  /// In en, this message translates to:
  /// **'Task / title'**
  String get debriefTaskLabel;

  /// No description provided for @debriefNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get debriefNoteLabel;

  /// No description provided for @debriefBillableLabel.
  ///
  /// In en, this message translates to:
  /// **'Billable'**
  String get debriefBillableLabel;

  /// No description provided for @debriefDontShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show again'**
  String get debriefDontShowAgain;

  /// No description provided for @settingsDebriefSection.
  ///
  /// In en, this message translates to:
  /// **'After stopping timer'**
  String get settingsDebriefSection;

  /// No description provided for @settingsDebriefToggle.
  ///
  /// In en, this message translates to:
  /// **'Show session summary dialog'**
  String get settingsDebriefToggle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsProfileSection.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get settingsProfileSection;

  /// No description provided for @settingsProfileFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get settingsProfileFirstName;

  /// No description provided for @settingsProfileLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get settingsProfileLastName;

  /// No description provided for @settingsProfileEmail.
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get settingsProfileEmail;

  /// No description provided for @settingsProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get settingsProfileSave;

  /// No description provided for @settingsProfileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name and/or last name.'**
  String get settingsProfileNameRequired;

  /// No description provided for @settingsProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get settingsProfileSaved;

  /// No description provided for @settingsProfileIndexSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Profile saved, but syncing the e-mail directory failed. Try again later.'**
  String get settingsProfileIndexSyncFailed;

  /// No description provided for @settingsProfileEmployerPanelHint.
  ///
  /// In en, this message translates to:
  /// **'Your name and e-mail are shown to employers when you share a project and in the employer dashboard lookup.'**
  String get settingsProfileEmployerPanelHint;

  /// No description provided for @settingsOfflineSyncHint.
  ///
  /// In en, this message translates to:
  /// **'Without network, the app keeps working on cached data. New entries and project changes are queued and sent to the cloud when you are back online.'**
  String get settingsOfflineSyncHint;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguagePl.
  ///
  /// In en, this message translates to:
  /// **'Polski'**
  String get settingsLanguagePl;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsThemeSystem;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @errorAuthInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid e-mail address.'**
  String get errorAuthInvalidEmail;

  /// No description provided for @errorAuthUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account with this e-mail.'**
  String get errorAuthUserNotFound;

  /// No description provided for @errorAuthWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password.'**
  String get errorAuthWrongPassword;

  /// No description provided for @errorAuthEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This e-mail is already registered.'**
  String get errorAuthEmailInUse;

  /// No description provided for @errorAuthWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak.'**
  String get errorAuthWeakPassword;

  /// No description provided for @errorAuthNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection.'**
  String get errorAuthNetwork;

  /// No description provided for @errorAuthTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get errorAuthTooManyRequests;

  /// No description provided for @errorAuthUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get errorAuthUserDisabled;

  /// No description provided for @errorAuthInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Incorrect e-mail or password.'**
  String get errorAuthInvalidCredential;

  /// No description provided for @errorAuthOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is not enabled.'**
  String get errorAuthOperationNotAllowed;

  /// No description provided for @errorAuthGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the request. Try again.'**
  String get errorAuthGeneric;

  /// No description provided for @debriefSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get debriefSkip;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Project report'**
  String get reportTitle;

  /// No description provided for @reportPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Timer — {project}'**
  String reportPdfTitle(String project);

  /// No description provided for @reportPdfMeta.
  ///
  /// In en, this message translates to:
  /// **'Project: {project} · Period: {from} — {to} · Generated: {at}'**
  String reportPdfMeta(String project, String from, String to, String at);

  /// No description provided for @reportRangeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get reportRangeToday;

  /// No description provided for @reportRangeThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get reportRangeThisWeek;

  /// No description provided for @reportRangeThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get reportRangeThisMonth;

  /// No description provided for @reportRangePreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get reportRangePreviousMonth;

  /// No description provided for @reportRangeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get reportRangeCustom;

  /// No description provided for @reportDateRangeSection.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get reportDateRangeSection;

  /// No description provided for @reportSummarySection.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get reportSummarySection;

  /// No description provided for @reportEntriesSection.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get reportEntriesSection;

  /// No description provided for @reportTotalTime.
  ///
  /// In en, this message translates to:
  /// **'Total time'**
  String get reportTotalTime;

  /// No description provided for @reportEstimatedEarnings.
  ///
  /// In en, this message translates to:
  /// **'Estimated earnings'**
  String get reportEstimatedEarnings;

  /// No description provided for @reportEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No report data for this date range.'**
  String get reportEmptyTitle;

  /// No description provided for @reportEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try another range or log time.'**
  String get reportEmptyBody;

  /// No description provided for @reportExportEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export for this range.'**
  String get reportExportEmpty;

  /// No description provided for @projectDetailMonthSummary.
  ///
  /// In en, this message translates to:
  /// **'This month (estimate)'**
  String get projectDetailMonthSummary;

  /// No description provided for @projectDetailUseForTimer.
  ///
  /// In en, this message translates to:
  /// **'Go to timer with this project'**
  String get projectDetailUseForTimer;

  /// No description provided for @projectDetailOpenReport.
  ///
  /// In en, this message translates to:
  /// **'Open project report'**
  String get projectDetailOpenReport;

  /// No description provided for @statsOpenProjectReport.
  ///
  /// In en, this message translates to:
  /// **'Project report'**
  String get statsOpenProjectReport;

  /// No description provided for @workspacesActiveDetailHint.
  ///
  /// In en, this message translates to:
  /// **'Active for timer — tap for details'**
  String get workspacesActiveDetailHint;

  /// No description provided for @workspacesInactiveDetailHint.
  ///
  /// In en, this message translates to:
  /// **'Tap for details · menu for quick actions'**
  String get workspacesInactiveDetailHint;

  /// No description provided for @workspacesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get workspacesEmptyTitle;

  /// No description provided for @workspacesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create your first project to start tracking time.'**
  String get workspacesEmptyBody;

  /// No description provided for @calendarDaySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Day summary'**
  String get calendarDaySummaryTitle;

  /// No description provided for @calendarDayEstimatedHint.
  ///
  /// In en, this message translates to:
  /// **'Estimated earnings'**
  String get calendarDayEstimatedHint;

  /// No description provided for @calendarDayNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries on this day.'**
  String get calendarDayNoEntries;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
