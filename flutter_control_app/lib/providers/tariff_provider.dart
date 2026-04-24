import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/heater_api.dart';

/// Manages day/night electricity tariff configuration.
///
/// Source of truth is the ESP32 device (GET /stats/tariff).
/// SharedPreferences is used only as an offline cache so the last-known
/// values are shown before the device responds.
///
/// Zone switching is performed automatically on the ESP32 — this provider
/// just periodically reads the current state back from the device so the
/// UI reflects the active zone.
class TariffProvider extends ChangeNotifier {
  static const _kEnabled    = 'tariff_enabled';
  static const _kDayPrice   = 'tariff_day_price';
  static const _kNightPrice = 'tariff_night_price';
  static const _kDayStart   = 'tariff_day_start';
  static const _kNightStart = 'tariff_night_start';

  bool   _enabled    = false;
  double _dayPrice   = 0.0;
  double _nightPrice = 0.0;
  int    _dayStart   = 7;
  int    _nightStart = 23;
  String _activeZone  = 'day';  // 'day' | 'night', reported by device
  double _activePrice = 0.0;

  DateTime? _lastDeviceSync;

  // ── Getters ──────────────────────────────────────────────────────────────────

  bool   get tariffModeEnabled => _enabled;
  double get dayPrice          => _dayPrice;
  double get nightPrice        => _nightPrice;
  int    get dayStartHour      => _dayStart;
  int    get nightStartHour    => _nightStart;
  bool   get isDayZone         => _activeZone == 'day';
  double get activePrice       => _activePrice > 0
      ? _activePrice
      : (isDayZone ? _dayPrice : _nightPrice);

  // ── Init ─────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled    = prefs.getBool(_kEnabled)       ?? false;
    _dayPrice   = prefs.getDouble(_kDayPrice)    ?? 0.0;
    _nightPrice = prefs.getDouble(_kNightPrice)  ?? 0.0;
    _dayStart   = prefs.getInt(_kDayStart)       ?? 7;
    _nightStart = prefs.getInt(_kNightStart)     ?? 23;
    // Approximate active zone offline using local clock
    _activeZone  = _localZone();
    _activePrice = isDayZone ? _dayPrice : _nightPrice;
    notifyListeners();
  }

  // ── Device sync ───────────────────────────────────────────────────────────────

  /// Called by [HeaterProvider] on each status poll (every ~3 s).
  /// Throttled to once per 60 s to avoid extra traffic.
  Future<void> syncIfNeeded(HeaterApi api) async {
    final now = DateTime.now();
    if (_lastDeviceSync != null &&
        now.difference(_lastDeviceSync!).inSeconds < 60) {
      return;
    }
    await loadFromDevice(api);
  }

  Future<void> loadFromDevice(HeaterApi api) async {
    try {
      final json = await api.getTariff();
      _applyDeviceJson(json);
      _lastDeviceSync = DateTime.now();
    } catch (_) {
      // Ignore — will retry on next poll.
    }
  }

  void _applyDeviceJson(Map<String, dynamic> json) {
    _enabled    = json['enabled']      as bool?   ?? _enabled;
    _dayPrice   = (json['dayPrice']    as num?)?.toDouble() ?? _dayPrice;
    _nightPrice = (json['nightPrice']  as num?)?.toDouble() ?? _nightPrice;
    _dayStart   = (json['dayStartHour']   as num?)?.toInt() ?? _dayStart;
    _nightStart = (json['nightStartHour'] as num?)?.toInt() ?? _nightStart;
    _activeZone  = json['activeZone']  as String? ?? _activeZone;
    _activePrice = (json['activePrice'] as num?)?.toDouble() ?? _activePrice;
    notifyListeners();
    _saveToPrefs();
  }

  // ── Setters ──────────────────────────────────────────────────────────────────

  Future<void> setEnabled(bool value, {HeaterApi? api}) async {
    if (api == null) { _enabled = value; notifyListeners(); return; }
    try {
      final json = await (value ? api.tariffOn() : api.tariffOff());
      _applyDeviceJson(json);
    } catch (_) {
      _enabled = value;
      notifyListeners();
    }
  }

  Future<void> setDayPrice(double price, {HeaterApi? api}) async {
    if (api == null) { _dayPrice = price; notifyListeners(); return; }
    try {
      final json = await api.setTariffConfig(dayPrice: price);
      _applyDeviceJson(json);
    } catch (_) {
      _dayPrice = price;
      notifyListeners();
    }
  }

  Future<void> setNightPrice(double price, {HeaterApi? api}) async {
    if (api == null) { _nightPrice = price; notifyListeners(); return; }
    try {
      final json = await api.setTariffConfig(nightPrice: price);
      _applyDeviceJson(json);
    } catch (_) {
      _nightPrice = price;
      notifyListeners();
    }
  }

  Future<void> setDayStartHour(int hour, {HeaterApi? api}) async {
    if (api == null) { _dayStart = hour; notifyListeners(); return; }
    try {
      final json = await api.setTariffConfig(dayStart: hour);
      _applyDeviceJson(json);
    } catch (_) {
      _dayStart = hour;
      notifyListeners();
    }
  }

  Future<void> setNightStartHour(int hour, {HeaterApi? api}) async {
    if (api == null) { _nightStart = hour; notifyListeners(); return; }
    try {
      final json = await api.setTariffConfig(nightStart: hour);
      _applyDeviceJson(json);
    } catch (_) {
      _nightStart = hour;
      notifyListeners();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _localZone() {
    final h = DateTime.now().hour;
    if (_dayStart < _nightStart) {
      return (h >= _dayStart && h < _nightStart) ? 'day' : 'night';
    } else {
      return (h >= _dayStart || h < _nightStart) ? 'day' : 'night';
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled,       _enabled);
    await prefs.setDouble(_kDayPrice,    _dayPrice);
    await prefs.setDouble(_kNightPrice,  _nightPrice);
    await prefs.setInt(_kDayStart,       _dayStart);
    await prefs.setInt(_kNightStart,     _nightStart);
  }
}

