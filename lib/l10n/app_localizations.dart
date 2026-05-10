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
  /// **'Workspaces'**
  String get navWorkspaces;

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
  /// **'Workspace'**
  String get timerWorkspace;

  /// No description provided for @timerWorkspaceLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading workspaces…'**
  String get timerWorkspaceLoading;

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
  /// **'Showing cached data. Sync may be limited while offline.'**
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
  /// **'Workspace share'**
  String get statsWorkspaceShare;

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
  /// **'Workspace: {name}'**
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

  /// No description provided for @historyExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export for Excel (CSV)'**
  String get historyExportCsv;

  /// No description provided for @historyExportCsvTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share filtered entries as a CSV file (opens in Excel)'**
  String get historyExportCsvTooltip;

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

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

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
