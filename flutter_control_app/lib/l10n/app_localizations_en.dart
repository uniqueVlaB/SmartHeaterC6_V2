// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Heater control';

  @override
  String get connectToDevice => 'Connect to your device';

  @override
  String get deviceUrl => 'Device URL';

  @override
  String get deviceUrlHint => 'http://192.168.1.xxx';

  @override
  String get connecting => 'Connecting…';

  @override
  String get connect => 'Connect';

  @override
  String get wifiRequired =>
      'Not connected to Wi-Fi. Please join the same network as the device.';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Settings';

  @override
  String get connectionOnline => 'Online';

  @override
  String get connectionConnecting => 'Connecting';

  @override
  String get connectionError => 'Error';

  @override
  String get connectionOffline => 'Offline';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get retry => 'Retry';

  @override
  String get statusHeating => 'Heating';

  @override
  String get statusIdle => 'Idle';

  @override
  String reasonBoost(String temp) {
    return 'Boosting to $temp°C';
  }

  @override
  String reasonPaused(int h, int s) {
    return 'Paused – ${h}m ${s}s remaining';
  }

  @override
  String reasonSchedule(String from, String to) {
    return 'Following schedule ($from–$to)';
  }

  @override
  String reasonCyclePause(int m) {
    return 'Cycle pause – ${m}m remaining';
  }

  @override
  String get reasonWaiting => 'Waiting for temperature';

  @override
  String get reasonDisabled => 'Heater disabled';

  @override
  String get labelTarget => 'Target';

  @override
  String get labelWater => 'Water';

  @override
  String get labelBody => 'Body';

  @override
  String get labelMaxTarget => 'Max Target';

  @override
  String get labelHysteresis => 'Hysteresis';

  @override
  String get labelCpuTemp => 'CPU Temp';

  @override
  String get labelPower => 'Power';

  @override
  String get labelVoltage => 'Voltage';

  @override
  String get labelCurrent => 'Current';

  @override
  String get labelEnergy => 'Energy';

  @override
  String get labelFrequency => 'Frequency';

  @override
  String get labelPowerFactor => 'Power Factor';

  @override
  String get labelCpuLoad => 'CPU Load';

  @override
  String get labelDefaultMode => 'Default Mode';

  @override
  String get labelCycleMode => 'Cycle Mode';

  @override
  String labelCycleModeOn(int on, int off) {
    return 'On (${on}m / ${off}m)';
  }

  @override
  String get labelTime => 'Time';

  @override
  String get labelTimeSynced => 'Time Synced';

  @override
  String get labelYes => 'Yes';

  @override
  String get labelNo => 'No';

  @override
  String get sectionTemperatures => 'Temperatures';

  @override
  String get sectionPower => 'Power';

  @override
  String get sectionSystem => 'System';

  @override
  String get sectionQuickControls => 'Quick Controls';

  @override
  String get btnSetTarget => 'Set Target';

  @override
  String get btnBoost => 'Boost';

  @override
  String get btnPause => 'Pause';

  @override
  String get btnResume => 'Resume';

  @override
  String get dialogSetTarget => 'Set Target Temperature';

  @override
  String get dialogSetTargetDesc => 'Used in default heating mode';

  @override
  String get dialogBoost => 'Boost Temperature';

  @override
  String get dialogPause => 'Pause Duration';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get dialogSet => 'Set';

  @override
  String get dialogSave => 'Save';

  @override
  String get dialogConfirm => 'Confirm';

  @override
  String get dialogRemove => 'Remove';

  @override
  String get dialogEdit => 'Edit';

  @override
  String scheduleActive(String from, String to, String temp) {
    return 'Schedule active: $from–$to  $temp°C';
  }

  @override
  String faultPrefix(String code) {
    return 'Fault: $code';
  }

  @override
  String get scheduleEmpty => 'No schedule slots';

  @override
  String get scheduleHint => 'Tap + to add a heating schedule';

  @override
  String get scheduleAddTitle => 'Add Schedule Slot';

  @override
  String get scheduleEditTitle => 'Edit Slot';

  @override
  String get scheduleDays => 'Days';

  @override
  String scheduleFrom(String time) {
    return 'From: $time';
  }

  @override
  String scheduleTo(String time) {
    return 'To: $time';
  }

  @override
  String scheduleTargetLabel(String temp) {
    return 'Target Temperature: $temp°C';
  }

  @override
  String get scheduleRemoveConfirmTitle => 'Remove slot?';

  @override
  String scheduleRemoveConfirmBody(String from, String to, String days) {
    return 'Remove $from–$to on $days?';
  }

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get daySat => 'Sat';

  @override
  String get daySun => 'Sun';

  @override
  String get daysEveryDay => 'Every day';

  @override
  String get daysWorkdays => 'Workdays';

  @override
  String get daysWeekend => 'Weekend';

  @override
  String statsTodayTitle(String date) {
    return 'Today ($date)';
  }

  @override
  String get statsMonthTitle => 'This Month';

  @override
  String get statsYearTitle => 'This Year';

  @override
  String get statsAllTimeTitle => 'All Time';

  @override
  String get statsHeatingTime => 'Heating time';

  @override
  String get statsSessions => 'Sessions';

  @override
  String get statsEnergy => 'Energy';

  @override
  String get statsCost => 'Cost';

  @override
  String get statsPrice => 'Electricity Price';

  @override
  String get statsSetPrice => 'Set Price';

  @override
  String get statsResetStats => 'Reset Stats';

  @override
  String get statsResetConfirmTitle => 'Reset Statistics?';

  @override
  String get statsResetConfirmBody =>
      'This will clear all accumulated statistics.';

  @override
  String get statsElectricityPriceLabel => 'Price per kWh';

  @override
  String get statsElectricityPriceSuffix => '€/kWh';

  @override
  String get statsSessionsLog => 'Sessions Log';

  @override
  String get statsNoSessions => 'No sessions recorded';

  @override
  String get statsSessionUnknown => 'Unknown';

  @override
  String get currencySymbol => '€';

  @override
  String get currencyPerKWh => '€/kWh';

  @override
  String get tariffSectionTitle => 'Electricity Tariff';

  @override
  String get tariffModeLabel => 'Day/Night Tariff Mode';

  @override
  String get tariffModeDesc => 'Use different prices for day and night';

  @override
  String get tariffDayZone => 'Day zone';

  @override
  String get tariffNightZone => 'Night zone';

  @override
  String tariffActiveZone(String zone) {
    return 'Active zone: $zone';
  }

  @override
  String tariffDayPrice(String h) {
    return 'Day price ($h:00)';
  }

  @override
  String tariffNightPrice(String h) {
    return 'Night price ($h:00)';
  }

  @override
  String get tariffDayStart => 'Day starts at';

  @override
  String get tariffNightStart => 'Night starts at';

  @override
  String get tariffSetDayPrice => 'Set Day Price';

  @override
  String get tariffSetNightPrice => 'Set Night Price';

  @override
  String get tariffSetDayStart => 'Day Start Hour';

  @override
  String get tariffSetNightStart => 'Night Start Hour';

  @override
  String tariffHour(String h) {
    return '$h:00';
  }

  @override
  String get tariffCurrentPrice => 'Current price';

  @override
  String get settingsHeater => 'Heater';

  @override
  String get settingsDefaultMode => 'Default Mode';

  @override
  String get settingsDefaultModeDesc => 'Follow target temperature on startup';

  @override
  String get settingsMaxTarget => 'Max Target Temperature';

  @override
  String get settingsHysteresis => 'Hysteresis';

  @override
  String get settingsDutyCycle => 'Duty-Cycle Mode';

  @override
  String get settingsCycleMode => 'Cycle Mode';

  @override
  String get settingsCycleModeDesc => 'Alternate on/off intervals';

  @override
  String get settingsCycleConfig => 'Cycle Config';

  @override
  String settingsCycleConfigDesc(int on, int off) {
    return 'On: ${on}m  ·  Off: ${off}m';
  }

  @override
  String get settingsCycleConfigTitle => 'Cycle Configuration';

  @override
  String settingsCycleOn(int min) {
    return 'On: $min min';
  }

  @override
  String settingsCycleOff(int min) {
    return 'Off: $min min';
  }

  @override
  String get settingsLed => 'LED';

  @override
  String get settingsStatusLed => 'Status LED';

  @override
  String get settingsStatusLedDesc => 'Enable device status LED';

  @override
  String get settingsSystem => 'System';

  @override
  String get settingsPeriodicRestart => 'Periodic Restart';

  @override
  String settingsPeriodicRestartDesc(int h) {
    return 'Every ${h}h';
  }

  @override
  String get settingsPeriodicRestartDisabled => 'Disabled';

  @override
  String get settingsRestartInterval => 'Restart Interval';

  @override
  String settingsRestartIntervalDesc(int h) {
    return '$h hours';
  }

  @override
  String get settingsRestartDevice => 'Restart Device';

  @override
  String get settingsRestartDeviceMsg => 'Restart the heater controller?';

  @override
  String get settingsFactoryReset => 'Factory Reset';

  @override
  String get settingsFactoryResetMsg =>
      'This will erase all settings. Are you sure?';

  @override
  String get settingsDevice => 'Device';

  @override
  String get settingsConnection => 'Connection';

  @override
  String get settingsUrl => 'URL';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsPushNotifications => 'Push Notifications';

  @override
  String get settingsPushComingSoon => 'Coming soon';

  @override
  String get settingsRestartIntervalTitle => 'Restart Interval';

  @override
  String get settingsApp => 'App';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsLanguageUk => 'Ukrainian';

  @override
  String get btnCancelPause => 'Cancel Pause';
}
