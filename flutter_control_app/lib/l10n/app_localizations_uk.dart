// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'Heater control';

  @override
  String get connectToDevice => 'Підключіться до пристрою';

  @override
  String get deviceUrl => 'Адреса пристрою';

  @override
  String get deviceUrlHint => 'http://192.168.1.xxx';

  @override
  String get connecting => 'Підключення…';

  @override
  String get connect => 'Підключити';

  @override
  String get wifiRequired =>
      'Немає з\'єднання Wi-Fi. Підключіться до тієї ж мережі, що й пристрій.';

  @override
  String get navDashboard => 'Головна';

  @override
  String get navSchedule => 'Розклад';

  @override
  String get navStats => 'Статистика';

  @override
  String get navSettings => 'Налаштування';

  @override
  String get connectionOnline => 'Онлайн';

  @override
  String get connectionConnecting => 'Підключення';

  @override
  String get connectionError => 'Помилка';

  @override
  String get connectionOffline => 'Офлайн';

  @override
  String get disconnect => 'Відключити';

  @override
  String get retry => 'Повторити';

  @override
  String get statusHeating => 'Нагрівання';

  @override
  String get statusIdle => 'Очікування';

  @override
  String reasonBoost(String temp) {
    return 'Розігрів до $temp°C';
  }

  @override
  String reasonPaused(int h, int s) {
    return 'Призупинено – залишилось $hхв $sс';
  }

  @override
  String reasonSchedule(String from, String to) {
    return 'За розкладом ($from–$to)';
  }

  @override
  String reasonCyclePause(int m) {
    return 'Пауза циклу – залишилось $mхв';
  }

  @override
  String get reasonWaiting => 'Очікування температури';

  @override
  String get reasonDisabled => 'Бойлер вимкнено';

  @override
  String get labelTarget => 'Ціль';

  @override
  String get labelWater => 'Вода';

  @override
  String get labelBody => 'Корпус';

  @override
  String get labelMaxTarget => 'Макс. ціль';

  @override
  String get labelHysteresis => 'Гістерезис';

  @override
  String get labelCpuTemp => 'Темп. процесора';

  @override
  String get labelPower => 'Потужність';

  @override
  String get labelVoltage => 'Напруга';

  @override
  String get labelCurrent => 'Струм';

  @override
  String get labelEnergy => 'Енергія';

  @override
  String get labelFrequency => 'Частота';

  @override
  String get labelPowerFactor => 'Коефіцієнт потужності';

  @override
  String get labelCpuLoad => 'Завант. ЦП';

  @override
  String get labelDefaultMode => 'Стандартний режим';

  @override
  String get labelCycleMode => 'Циклічний режим';

  @override
  String labelCycleModeOn(int on, int off) {
    return 'Увімк. ($onхв / $offхв)';
  }

  @override
  String get labelTime => 'Час';

  @override
  String get labelTimeSynced => 'Час синхронізовано';

  @override
  String get labelYes => 'Так';

  @override
  String get labelNo => 'Ні';

  @override
  String get sectionTemperatures => 'Температури';

  @override
  String get sectionPower => 'Живлення';

  @override
  String get sectionSystem => 'Система';

  @override
  String get sectionQuickControls => 'Швидке керування';

  @override
  String get btnSetTarget => 'Встановити ціль';

  @override
  String get btnBoost => 'Розігріти';

  @override
  String get btnPause => 'Пауза';

  @override
  String get btnResume => 'Продовжити';

  @override
  String get dialogSetTarget => 'Встановити цільову температуру';

  @override
  String get dialogSetTargetDesc =>
      'Використовується в стандартному режимі нагріву';

  @override
  String get dialogBoost => 'Розігрів';

  @override
  String get dialogPause => 'Тривалість паузи';

  @override
  String get dialogCancel => 'Скасувати';

  @override
  String get dialogSet => 'Встановити';

  @override
  String get dialogSave => 'Зберегти';

  @override
  String get dialogConfirm => 'Підтвердити';

  @override
  String get dialogRemove => 'Видалити';

  @override
  String get dialogEdit => 'Редагувати';

  @override
  String scheduleActive(String from, String to, String temp) {
    return 'Розклад активний: $from–$to  $temp°C';
  }

  @override
  String faultPrefix(String code) {
    return 'Помилка: $code';
  }

  @override
  String get scheduleEmpty => 'Розклад порожній';

  @override
  String get scheduleHint => 'Натисніть + щоб додати розклад';

  @override
  String get scheduleAddTitle => 'Додати слот розкладу';

  @override
  String get scheduleEditTitle => 'Редагувати слот';

  @override
  String get scheduleDays => 'Дні';

  @override
  String scheduleFrom(String time) {
    return 'З: $time';
  }

  @override
  String scheduleTo(String time) {
    return 'До: $time';
  }

  @override
  String scheduleTargetLabel(String temp) {
    return 'Цільова температура: $temp°C';
  }

  @override
  String get scheduleRemoveConfirmTitle => 'Видалити слот?';

  @override
  String scheduleRemoveConfirmBody(String from, String to, String days) {
    return 'Видалити $from–$to для $days?';
  }

  @override
  String get dayMon => 'Пн';

  @override
  String get dayTue => 'Вт';

  @override
  String get dayWed => 'Ср';

  @override
  String get dayThu => 'Чт';

  @override
  String get dayFri => 'Пт';

  @override
  String get daySat => 'Сб';

  @override
  String get daySun => 'Нд';

  @override
  String get daysEveryDay => 'Щодня';

  @override
  String get daysWorkdays => 'Будні';

  @override
  String get daysWeekend => 'Вихідні';

  @override
  String statsTodayTitle(String date) {
    return 'Сьогодні ($date)';
  }

  @override
  String get statsMonthTitle => 'Цей місяць';

  @override
  String get statsYearTitle => 'Цей рік';

  @override
  String get statsAllTimeTitle => 'За весь час';

  @override
  String get statsHeatingTime => 'Час нагріву';

  @override
  String get statsSessions => 'Сесії';

  @override
  String get statsEnergy => 'Енергія';

  @override
  String get statsCost => 'Вартість';

  @override
  String get statsPrice => 'Ціна електроенергії';

  @override
  String get statsSetPrice => 'Встановити ціну';

  @override
  String get statsResetStats => 'Скинути статистику';

  @override
  String get statsResetConfirmTitle => 'Скинути статистику?';

  @override
  String get statsResetConfirmBody => 'Це очистить всі накопичені дані.';

  @override
  String get statsElectricityPriceLabel => 'Ціна за кВт·год';

  @override
  String get statsElectricityPriceSuffix => 'грн/кВт·год';

  @override
  String get statsSessionsLog => 'Журнал сесій';

  @override
  String get statsNoSessions => 'Сесій не записано';

  @override
  String get statsSessionUnknown => 'Невідомо';

  @override
  String get currencySymbol => 'грн';

  @override
  String get currencyPerKWh => 'грн/кВт·год';

  @override
  String get tariffSectionTitle => 'Тариф електроенергії';

  @override
  String get tariffModeLabel => 'Денночний тариф';

  @override
  String get tariffModeDesc => 'Різні ціни вдень і вночі';

  @override
  String get tariffDayZone => 'Денна зона';

  @override
  String get tariffNightZone => 'Нічна зона';

  @override
  String tariffActiveZone(String zone) {
    return 'Активна зона: $zone';
  }

  @override
  String tariffDayPrice(String h) {
    return 'Денна ціна ($h:00)';
  }

  @override
  String tariffNightPrice(String h) {
    return 'Нічна ціна ($h:00)';
  }

  @override
  String get tariffDayStart => 'Початок дня';

  @override
  String get tariffNightStart => 'Початок ночі';

  @override
  String get tariffSetDayPrice => 'Денна ціна';

  @override
  String get tariffSetNightPrice => 'Нічна ціна';

  @override
  String get tariffSetDayStart => 'Початок денної зони';

  @override
  String get tariffSetNightStart => 'Початок нічної зони';

  @override
  String tariffHour(String h) {
    return '$h:00';
  }

  @override
  String get tariffCurrentPrice => 'Поточна ціна';

  @override
  String get settingsHeater => 'Бойлер';

  @override
  String get settingsDefaultMode => 'Стандартний режим';

  @override
  String get settingsDefaultModeDesc =>
      'Дотримуватись цільової температури після запуску';

  @override
  String get settingsMaxTarget => 'Максимальна цільова температура';

  @override
  String get settingsHysteresis => 'Гістерезис';

  @override
  String get settingsDutyCycle => 'Циклічний режим';

  @override
  String get settingsCycleMode => 'Циклічний режим';

  @override
  String get settingsCycleModeDesc =>
      'Чергувати інтервали увімкнення/вимкнення';

  @override
  String get settingsCycleConfig => 'Конфігурація циклу';

  @override
  String settingsCycleConfigDesc(int on, int off) {
    return 'Увімк.: $onхв  ·  Вимк.: $offхв';
  }

  @override
  String get settingsCycleConfigTitle => 'Конфігурація циклу';

  @override
  String settingsCycleOn(int min) {
    return 'Увімк.: $min хв';
  }

  @override
  String settingsCycleOff(int min) {
    return 'Вимк.: $min хв';
  }

  @override
  String get settingsLed => 'Індикатор';

  @override
  String get settingsStatusLed => 'Індикатор статусу';

  @override
  String get settingsStatusLedDesc => 'Увімкнути індикатор на пристрої';

  @override
  String get settingsSystem => 'Система';

  @override
  String get settingsPeriodicRestart => 'Автоматичний перезапуск';

  @override
  String settingsPeriodicRestartDesc(int h) {
    return 'Кожні $hгод';
  }

  @override
  String get settingsPeriodicRestartDisabled => 'Вимкнено';

  @override
  String get settingsRestartInterval => 'Інтервал перезапуску';

  @override
  String settingsRestartIntervalDesc(int h) {
    return '$h годин';
  }

  @override
  String get settingsRestartDevice => 'Перезапустити пристрій';

  @override
  String get settingsRestartDeviceMsg => 'Перезапустити контролер бойлера?';

  @override
  String get settingsFactoryReset => 'Скидання до заводських';

  @override
  String get settingsFactoryResetMsg =>
      'Це видалить всі налаштування. Ви впевнені?';

  @override
  String get settingsDevice => 'Пристрій';

  @override
  String get settingsConnection => 'Підключення';

  @override
  String get settingsUrl => 'Адреса';

  @override
  String get settingsNotifications => 'Сповіщення';

  @override
  String get settingsPushNotifications => 'Push-сповіщення';

  @override
  String get settingsPushComingSoon => 'Незабаром';

  @override
  String get settingsRestartIntervalTitle => 'Інтервал перезапуску';

  @override
  String get settingsApp => 'Застосунок';

  @override
  String get settingsLanguage => 'Мова';

  @override
  String get settingsLanguageSystem => 'Системна';

  @override
  String get settingsLanguageEn => 'Англійська';

  @override
  String get settingsLanguageUk => 'Українська';

  @override
  String get btnCancelPause => 'Скасувати паузу';
}
