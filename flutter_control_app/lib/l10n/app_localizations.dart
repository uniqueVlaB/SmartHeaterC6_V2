import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_uk.dart';

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
    Locale('uk'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Heater control'**
  String get appTitle;

  /// No description provided for @connectToDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect to your device'**
  String get connectToDevice;

  /// No description provided for @deviceUrl.
  ///
  /// In en, this message translates to:
  /// **'Device URL'**
  String get deviceUrl;

  /// No description provided for @deviceUrlHint.
  ///
  /// In en, this message translates to:
  /// **'http://192.168.1.xxx'**
  String get deviceUrlHint;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @wifiRequired.
  ///
  /// In en, this message translates to:
  /// **'Not connected to Wi-Fi. Please join the same network as the device.'**
  String get wifiRequired;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get navSchedule;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @connectionOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get connectionOnline;

  /// No description provided for @connectionConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connectionConnecting;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get connectionError;

  /// No description provided for @connectionOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get connectionOffline;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @statusHeating.
  ///
  /// In en, this message translates to:
  /// **'Heating'**
  String get statusHeating;

  /// No description provided for @statusIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get statusIdle;

  /// No description provided for @reasonBoost.
  ///
  /// In en, this message translates to:
  /// **'Boosting to {temp}°C'**
  String reasonBoost(String temp);

  /// No description provided for @reasonPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused – {h}m {s}s remaining'**
  String reasonPaused(int h, int s);

  /// No description provided for @reasonSchedule.
  ///
  /// In en, this message translates to:
  /// **'Following schedule ({from}–{to})'**
  String reasonSchedule(String from, String to);

  /// No description provided for @reasonCyclePause.
  ///
  /// In en, this message translates to:
  /// **'Cycle pause – {m}m remaining'**
  String reasonCyclePause(int m);

  /// No description provided for @reasonWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for temperature'**
  String get reasonWaiting;

  /// No description provided for @reasonDisabled.
  ///
  /// In en, this message translates to:
  /// **'Heater disabled'**
  String get reasonDisabled;

  /// No description provided for @labelTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get labelTarget;

  /// No description provided for @labelWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get labelWater;

  /// No description provided for @labelBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get labelBody;

  /// No description provided for @labelMaxTarget.
  ///
  /// In en, this message translates to:
  /// **'Max Target'**
  String get labelMaxTarget;

  /// No description provided for @labelHysteresis.
  ///
  /// In en, this message translates to:
  /// **'Hysteresis'**
  String get labelHysteresis;

  /// No description provided for @labelCpuTemp.
  ///
  /// In en, this message translates to:
  /// **'CPU Temp'**
  String get labelCpuTemp;

  /// No description provided for @labelPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get labelPower;

  /// No description provided for @labelVoltage.
  ///
  /// In en, this message translates to:
  /// **'Voltage'**
  String get labelVoltage;

  /// No description provided for @labelCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get labelCurrent;

  /// No description provided for @labelEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get labelEnergy;

  /// No description provided for @labelFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get labelFrequency;

  /// No description provided for @labelPowerFactor.
  ///
  /// In en, this message translates to:
  /// **'Power Factor'**
  String get labelPowerFactor;

  /// No description provided for @labelCpuLoad.
  ///
  /// In en, this message translates to:
  /// **'CPU Load'**
  String get labelCpuLoad;

  /// No description provided for @labelDefaultMode.
  ///
  /// In en, this message translates to:
  /// **'Default Mode'**
  String get labelDefaultMode;

  /// No description provided for @labelCycleMode.
  ///
  /// In en, this message translates to:
  /// **'Cycle Mode'**
  String get labelCycleMode;

  /// No description provided for @labelCycleModeOn.
  ///
  /// In en, this message translates to:
  /// **'On ({on}m / {off}m)'**
  String labelCycleModeOn(int on, int off);

  /// No description provided for @labelTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get labelTime;

  /// No description provided for @labelTimeSynced.
  ///
  /// In en, this message translates to:
  /// **'Time Synced'**
  String get labelTimeSynced;

  /// No description provided for @labelYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get labelYes;

  /// No description provided for @labelNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get labelNo;

  /// No description provided for @sectionTemperatures.
  ///
  /// In en, this message translates to:
  /// **'Temperatures'**
  String get sectionTemperatures;

  /// No description provided for @sectionPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get sectionPower;

  /// No description provided for @sectionSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get sectionSystem;

  /// No description provided for @sectionQuickControls.
  ///
  /// In en, this message translates to:
  /// **'Quick Controls'**
  String get sectionQuickControls;

  /// No description provided for @btnSetTarget.
  ///
  /// In en, this message translates to:
  /// **'Set Target'**
  String get btnSetTarget;

  /// No description provided for @btnBoost.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get btnBoost;

  /// No description provided for @btnPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get btnPause;

  /// No description provided for @btnResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get btnResume;

  /// No description provided for @dialogSetTarget.
  ///
  /// In en, this message translates to:
  /// **'Set Target Temperature'**
  String get dialogSetTarget;

  /// No description provided for @dialogSetTargetDesc.
  ///
  /// In en, this message translates to:
  /// **'Used in default heating mode'**
  String get dialogSetTargetDesc;

  /// No description provided for @dialogBoost.
  ///
  /// In en, this message translates to:
  /// **'Boost Temperature'**
  String get dialogBoost;

  /// No description provided for @dialogPause.
  ///
  /// In en, this message translates to:
  /// **'Pause Duration'**
  String get dialogPause;

  /// No description provided for @dialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// No description provided for @dialogSet.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get dialogSet;

  /// No description provided for @dialogSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get dialogSave;

  /// No description provided for @dialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get dialogConfirm;

  /// No description provided for @dialogRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get dialogRemove;

  /// No description provided for @dialogEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get dialogEdit;

  /// No description provided for @scheduleActive.
  ///
  /// In en, this message translates to:
  /// **'Schedule active: {from}–{to}  {temp}°C'**
  String scheduleActive(String from, String to, String temp);

  /// No description provided for @faultPrefix.
  ///
  /// In en, this message translates to:
  /// **'Fault: {code}'**
  String faultPrefix(String code);

  /// No description provided for @scheduleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No schedule slots'**
  String get scheduleEmpty;

  /// No description provided for @scheduleHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a heating schedule'**
  String get scheduleHint;

  /// No description provided for @scheduleAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Schedule Slot'**
  String get scheduleAddTitle;

  /// No description provided for @scheduleEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Slot'**
  String get scheduleEditTitle;

  /// No description provided for @scheduleDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get scheduleDays;

  /// No description provided for @scheduleFrom.
  ///
  /// In en, this message translates to:
  /// **'From: {time}'**
  String scheduleFrom(String time);

  /// No description provided for @scheduleTo.
  ///
  /// In en, this message translates to:
  /// **'To: {time}'**
  String scheduleTo(String time);

  /// No description provided for @scheduleTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target Temperature: {temp}°C'**
  String scheduleTargetLabel(String temp);

  /// No description provided for @scheduleRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove slot?'**
  String get scheduleRemoveConfirmTitle;

  /// No description provided for @scheduleRemoveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {from}–{to} on {days}?'**
  String scheduleRemoveConfirmBody(String from, String to, String days);

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// No description provided for @daysEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get daysEveryDay;

  /// No description provided for @daysWorkdays.
  ///
  /// In en, this message translates to:
  /// **'Workdays'**
  String get daysWorkdays;

  /// No description provided for @daysWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get daysWeekend;

  /// No description provided for @statsTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today ({date})'**
  String statsTodayTitle(String date);

  /// No description provided for @statsMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get statsMonthTitle;

  /// No description provided for @statsYearTitle.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get statsYearTitle;

  /// No description provided for @statsAllTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get statsAllTimeTitle;

  /// No description provided for @statsHeatingTime.
  ///
  /// In en, this message translates to:
  /// **'Heating time'**
  String get statsHeatingTime;

  /// No description provided for @statsSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get statsSessions;

  /// No description provided for @statsEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get statsEnergy;

  /// No description provided for @statsCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get statsCost;

  /// No description provided for @statsPrice.
  ///
  /// In en, this message translates to:
  /// **'Electricity Price'**
  String get statsPrice;

  /// No description provided for @statsSetPrice.
  ///
  /// In en, this message translates to:
  /// **'Set Price'**
  String get statsSetPrice;

  /// No description provided for @statsResetStats.
  ///
  /// In en, this message translates to:
  /// **'Reset Stats'**
  String get statsResetStats;

  /// No description provided for @statsResetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Statistics?'**
  String get statsResetConfirmTitle;

  /// No description provided for @statsResetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will clear all accumulated statistics.'**
  String get statsResetConfirmBody;

  /// No description provided for @statsElectricityPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price per kWh'**
  String get statsElectricityPriceLabel;

  /// No description provided for @statsElectricityPriceSuffix.
  ///
  /// In en, this message translates to:
  /// **'€/kWh'**
  String get statsElectricityPriceSuffix;

  /// No description provided for @statsSessionsLog.
  ///
  /// In en, this message translates to:
  /// **'Sessions Log'**
  String get statsSessionsLog;

  /// No description provided for @statsNoSessions.
  ///
  /// In en, this message translates to:
  /// **'No sessions recorded'**
  String get statsNoSessions;

  /// No description provided for @statsSessionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statsSessionUnknown;

  /// No description provided for @currencySymbol.
  ///
  /// In en, this message translates to:
  /// **'€'**
  String get currencySymbol;

  /// No description provided for @currencyPerKWh.
  ///
  /// In en, this message translates to:
  /// **'€/kWh'**
  String get currencyPerKWh;

  /// No description provided for @tariffSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Electricity Tariff'**
  String get tariffSectionTitle;

  /// No description provided for @tariffModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Day/Night Tariff Mode'**
  String get tariffModeLabel;

  /// No description provided for @tariffModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Use different prices for day and night'**
  String get tariffModeDesc;

  /// No description provided for @tariffDayZone.
  ///
  /// In en, this message translates to:
  /// **'Day zone'**
  String get tariffDayZone;

  /// No description provided for @tariffNightZone.
  ///
  /// In en, this message translates to:
  /// **'Night zone'**
  String get tariffNightZone;

  /// No description provided for @tariffActiveZone.
  ///
  /// In en, this message translates to:
  /// **'Active zone: {zone}'**
  String tariffActiveZone(String zone);

  /// No description provided for @tariffDayPrice.
  ///
  /// In en, this message translates to:
  /// **'Day price ({h}:00)'**
  String tariffDayPrice(String h);

  /// No description provided for @tariffNightPrice.
  ///
  /// In en, this message translates to:
  /// **'Night price ({h}:00)'**
  String tariffNightPrice(String h);

  /// No description provided for @tariffDayStart.
  ///
  /// In en, this message translates to:
  /// **'Day starts at'**
  String get tariffDayStart;

  /// No description provided for @tariffNightStart.
  ///
  /// In en, this message translates to:
  /// **'Night starts at'**
  String get tariffNightStart;

  /// No description provided for @tariffSetDayPrice.
  ///
  /// In en, this message translates to:
  /// **'Set Day Price'**
  String get tariffSetDayPrice;

  /// No description provided for @tariffSetNightPrice.
  ///
  /// In en, this message translates to:
  /// **'Set Night Price'**
  String get tariffSetNightPrice;

  /// No description provided for @tariffSetDayStart.
  ///
  /// In en, this message translates to:
  /// **'Day Start Hour'**
  String get tariffSetDayStart;

  /// No description provided for @tariffSetNightStart.
  ///
  /// In en, this message translates to:
  /// **'Night Start Hour'**
  String get tariffSetNightStart;

  /// No description provided for @tariffHour.
  ///
  /// In en, this message translates to:
  /// **'{h}:00'**
  String tariffHour(String h);

  /// No description provided for @tariffCurrentPrice.
  ///
  /// In en, this message translates to:
  /// **'Current price'**
  String get tariffCurrentPrice;

  /// No description provided for @settingsHeater.
  ///
  /// In en, this message translates to:
  /// **'Heater'**
  String get settingsHeater;

  /// No description provided for @settingsDefaultMode.
  ///
  /// In en, this message translates to:
  /// **'Default Mode'**
  String get settingsDefaultMode;

  /// No description provided for @settingsDefaultModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Follow target temperature on startup'**
  String get settingsDefaultModeDesc;

  /// No description provided for @settingsMaxTarget.
  ///
  /// In en, this message translates to:
  /// **'Max Target Temperature'**
  String get settingsMaxTarget;

  /// No description provided for @settingsHysteresis.
  ///
  /// In en, this message translates to:
  /// **'Hysteresis'**
  String get settingsHysteresis;

  /// No description provided for @settingsDutyCycle.
  ///
  /// In en, this message translates to:
  /// **'Duty-Cycle Mode'**
  String get settingsDutyCycle;

  /// No description provided for @settingsCycleMode.
  ///
  /// In en, this message translates to:
  /// **'Cycle Mode'**
  String get settingsCycleMode;

  /// No description provided for @settingsCycleModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Alternate on/off intervals'**
  String get settingsCycleModeDesc;

  /// No description provided for @settingsCycleConfig.
  ///
  /// In en, this message translates to:
  /// **'Cycle Config'**
  String get settingsCycleConfig;

  /// No description provided for @settingsCycleConfigDesc.
  ///
  /// In en, this message translates to:
  /// **'On: {on}m  ·  Off: {off}m'**
  String settingsCycleConfigDesc(int on, int off);

  /// No description provided for @settingsCycleConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Cycle Configuration'**
  String get settingsCycleConfigTitle;

  /// No description provided for @settingsCycleOn.
  ///
  /// In en, this message translates to:
  /// **'On: {min} min'**
  String settingsCycleOn(int min);

  /// No description provided for @settingsCycleOff.
  ///
  /// In en, this message translates to:
  /// **'Off: {min} min'**
  String settingsCycleOff(int min);

  /// No description provided for @settingsLed.
  ///
  /// In en, this message translates to:
  /// **'LED'**
  String get settingsLed;

  /// No description provided for @settingsStatusLed.
  ///
  /// In en, this message translates to:
  /// **'Status LED'**
  String get settingsStatusLed;

  /// No description provided for @settingsStatusLedDesc.
  ///
  /// In en, this message translates to:
  /// **'Enable device status LED'**
  String get settingsStatusLedDesc;

  /// No description provided for @settingsSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsSystem;

  /// No description provided for @settingsPeriodicRestart.
  ///
  /// In en, this message translates to:
  /// **'Periodic Restart'**
  String get settingsPeriodicRestart;

  /// No description provided for @settingsPeriodicRestartDesc.
  ///
  /// In en, this message translates to:
  /// **'Every {h}h'**
  String settingsPeriodicRestartDesc(int h);

  /// No description provided for @settingsPeriodicRestartDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get settingsPeriodicRestartDisabled;

  /// No description provided for @settingsRestartInterval.
  ///
  /// In en, this message translates to:
  /// **'Restart Interval'**
  String get settingsRestartInterval;

  /// No description provided for @settingsRestartIntervalDesc.
  ///
  /// In en, this message translates to:
  /// **'{h} hours'**
  String settingsRestartIntervalDesc(int h);

  /// No description provided for @settingsRestartDevice.
  ///
  /// In en, this message translates to:
  /// **'Restart Device'**
  String get settingsRestartDevice;

  /// No description provided for @settingsRestartDeviceMsg.
  ///
  /// In en, this message translates to:
  /// **'Restart the heater controller?'**
  String get settingsRestartDeviceMsg;

  /// No description provided for @settingsFactoryReset.
  ///
  /// In en, this message translates to:
  /// **'Factory Reset'**
  String get settingsFactoryReset;

  /// No description provided for @settingsFactoryResetMsg.
  ///
  /// In en, this message translates to:
  /// **'This will erase all settings. Are you sure?'**
  String get settingsFactoryResetMsg;

  /// No description provided for @settingsDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get settingsDevice;

  /// No description provided for @settingsConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get settingsConnection;

  /// No description provided for @settingsUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get settingsUrl;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get settingsPushNotifications;

  /// No description provided for @settingsPushComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get settingsPushComingSoon;

  /// No description provided for @settingsRestartIntervalTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart Interval'**
  String get settingsRestartIntervalTitle;

  /// No description provided for @settingsApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsApp;

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

  /// No description provided for @settingsLanguageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @settingsLanguageUk.
  ///
  /// In en, this message translates to:
  /// **'Ukrainian'**
  String get settingsLanguageUk;

  /// No description provided for @btnCancelPause.
  ///
  /// In en, this message translates to:
  /// **'Cancel Pause'**
  String get btnCancelPause;
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
      <String>['en', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
