import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/heater_status.dart';
import '../models/schedule_slot.dart';
import '../models/stats_data.dart';
import '../services/heater_api.dart';
import 'tariff_provider.dart';

enum DeviceConnectionState { initializing, disconnected, connecting, connected, error }

class HeaterProvider extends ChangeNotifier {
  HeaterApi? _api;
  Timer? _pollTimer;
  TariffProvider? _tariffProvider;

  /// Attach [TariffProvider] so polling can trigger tariff sync.
  void attachTariff(TariffProvider tp) {
    _tariffProvider = tp;
  }

  // ── Connection ──────────────────────────────────────────────────────────────

  String _deviceUrl = '';
  DeviceConnectionState _connectionState = DeviceConnectionState.initializing;
  String? _lastError;
  int _consecutiveFailures = 0;
  static const int _maxFailuresBeforeError = 3;

  // ── Connectivity ─────────────────────────────────────────────────────────────

  bool _isOnWifi = false;
  bool get isOnWifi => _isOnWifi;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  void _startConnectivityWatch() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final prev = _isOnWifi;
      _isOnWifi = results.contains(ConnectivityResult.wifi);
      if (prev != _isOnWifi) notifyListeners();
    });
  }

  Future<bool> _checkWifi() async {
    final results = await Connectivity().checkConnectivity();
    _isOnWifi = results.contains(ConnectivityResult.wifi);
    return _isOnWifi;
  }

  String get deviceUrl => _deviceUrl;
  DeviceConnectionState get connectionState => _connectionState;
  String? get lastError => _lastError;
  bool get isConnected => _connectionState == DeviceConnectionState.connected;

  // ── Status ──────────────────────────────────────────────────────────────────

  HeaterStatus? _status;
  HeaterStatus? get status => _status;

  // ── Schedule ────────────────────────────────────────────────────────────────

  List<ScheduleSlot>? _schedule;
  bool _scheduleLoadFailed = false;
  List<ScheduleSlot>? get schedule => _schedule;
  bool get scheduleLoadFailed => _scheduleLoadFailed;

  // ── Stats ───────────────────────────────────────────────────────────────────

  StatsData? _stats;
  bool _statsLoadFailed = false;
  StatsData? get stats => _stats;
  bool get statsLoadFailed => _statsLoadFailed;

  // ── LED ─────────────────────────────────────────────────────────────────────

  bool? _ledEnabled;
  bool? get ledEnabled => _ledEnabled;

  // ── Periodic restart ────────────────────────────────────────────────────────

  bool? _periodicRestartEnabled;
  int? _periodicRestartIntervalH;
  bool? get periodicRestartEnabled => _periodicRestartEnabled;
  int? get periodicRestartIntervalH => _periodicRestartIntervalH;

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _startConnectivityWatch();
    await _checkWifi();

    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('device_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _deviceUrl = savedUrl; // pre-fill URL field in case WiFi isn't available
      if (_isOnWifi) {
        await connect(savedUrl);
        return;
      }
    }
    _connectionState = DeviceConnectionState.disconnected;
    notifyListeners();
  }

  // ── Connection ──────────────────────────────────────────────────────────────

  Future<void> connect(String url) async {
    _deviceUrl = url.trimRight().replaceAll(RegExp(r'/$'), '');

    // Don't attempt connection without Wi-Fi — the ESP32 is only reachable
    // over the local network.
    if (!await _checkWifi()) {
      _connectionState = DeviceConnectionState.disconnected;
      notifyListeners();
      return;
    }

    _api = HeaterApi(baseUrl: _deviceUrl);
    _connectionState = DeviceConnectionState.connecting;
    _lastError = null;
    notifyListeners();

    try {
      _status = await _api!.getStatus();
      _connectionState = DeviceConnectionState.connected;
      _lastError = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_url', _deviceUrl);

      _startPolling();
    } catch (e) {
      _connectionState = DeviceConnectionState.error;
      _lastError = _errorMessage(e);
    }
    notifyListeners();
  }

  void disconnect() {
    _stopPolling();
    _api = null;
    _status = null;
    _schedule = null;
    _scheduleLoadFailed = false;
    _stats = null;
    _statsLoadFailed = false;
    _connectionState = DeviceConnectionState.disconnected;
    _lastError = null;
    notifyListeners();
  }

  // ── Polling ─────────────────────────────────────────────────────────────────

  bool _isPollingActive = true;
  void setPollingActive(bool active) {
    _isPollingActive = active;
  }

  void _startPolling({Duration interval = const Duration(seconds: 3)}) {
    _stopPolling();
    _pollTimer = Timer.periodic(interval, (_) => _refreshStatus());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _refreshStatus() async {
    if (_api == null || !_isPollingActive) return;
    try {
      _status = await _api!.getStatus();
      _consecutiveFailures = 0;
      if (_connectionState != DeviceConnectionState.connected) {
        _connectionState = DeviceConnectionState.connected;
        _lastError = null;
      }
      // Sync tariff whenever polling succeeds.
      if (_tariffProvider != null) {
        await _tariffProvider!.syncIfNeeded(_api!);
      }
    } catch (e) {
      _consecutiveFailures++;
      _lastError = _errorMessage(e);
      // Only surface error state after several consecutive failures —
      // keeps the user on HomeScreen during brief WiFi hiccups.
      if (_consecutiveFailures >= _maxFailuresBeforeError) {
        _connectionState = DeviceConnectionState.error;
      }
    }
    notifyListeners();
  }

  // ── Heater actions ──────────────────────────────────────────────────────────

  Future<void> heaterOn() => _run(_api!.heaterOn);
  Future<void> heaterOff() => _run(_api!.heaterOff);
  Future<void> defaultModeOn() => _run(_api!.defaultModeOn);
  Future<void> defaultModeOff() => _run(_api!.defaultModeOff);

  Future<void> pause(int minutes) => _run(() => _api!.pause(minutes));
  Future<void> boost(double temp) => _run(() => _api!.boost(temp));
  Future<void> setTarget(double temp) => _run(() => _api!.setTarget(temp));
  Future<void> setMaxTarget(double temp) => _run(() => _api!.setMaxTarget(temp));
  Future<void> setHysteresis(double value) => _run(() => _api!.setHysteresis(value));
  Future<void> cycleOn() => _run(_api!.cycleOn);
  Future<void> cycleOff() => _run(_api!.cycleOff);
  Future<void> setCycleConfig({required int onMinutes, required int offMinutes}) =>
      _run(() => _api!.setCycleConfig(onMinutes: onMinutes, offMinutes: offMinutes));
  Future<void> resetEnergy() => _run(_api!.resetEnergy);

  // ── Schedule actions ────────────────────────────────────────────────────────

  Future<void> loadSchedule() async {
    if (_api == null) return;
    _scheduleLoadFailed = false;
    try {
      _schedule = await _api!.getSchedule();
    } catch (e) {
      _scheduleLoadFailed = _schedule == null;
      _schedule ??= [];
    }
    notifyListeners();
  }

  Future<void> addScheduleSlot({
    required int dayMask,
    required int fromMin,
    required int toMin,
    double target = 0,
  }) async {
    if (_api == null) return;
    _schedule = await _api!.addScheduleSlot(
      dayMask: dayMask,
      fromMin: fromMin,
      toMin: toMin,
      target: target,
    );
    notifyListeners();
  }

  Future<void> editScheduleSlot({
    required int id,
    int? dayMask,
    int? fromMin,
    int? toMin,
    double? target,
  }) async {
    if (_api == null) return;
    _schedule = await _api!.editScheduleSlot(
      id: id,
      dayMask: dayMask,
      fromMin: fromMin,
      toMin: toMin,
      target: target,
    );
    notifyListeners();
  }

  Future<void> removeScheduleSlot(int id) async {
    if (_api == null) return;
    _schedule = await _api!.removeScheduleSlot(id);
    notifyListeners();
  }

  Future<void> toggleScheduleSlot(int id, {required bool enable}) async {
    if (_api == null) return;
    _schedule = enable
        ? await _api!.enableScheduleSlot(id)
        : await _api!.disableScheduleSlot(id);
    notifyListeners();
  }

  Future<void> clearSchedule() async {
    if (_api == null) return;
    await _api!.clearSchedule();
    _schedule = [];
    notifyListeners();
  }

  // ── Stats actions ───────────────────────────────────────────────────────────

  Future<void> loadStats() async {
    if (_api == null) return;
    _statsLoadFailed = false;
    try {
      _stats = await _api!.getStats();
    } catch (e) {
      _statsLoadFailed = _stats == null; // only flag error if no data yet
    }
    notifyListeners();
  }

  Future<void> setPrice(double pricePerKWh) async {
    if (_api == null) return;
    await _api!.setPrice(pricePerKWh);
    await loadStats();
  }

  /// Expose the internal API so [TariffProvider] can push prices directly.
  HeaterApi? get api => _api;

  Future<void> resetStats() async {
    if (_api == null) return;
    await _api!.resetStats();
    await loadStats();
  }

  // ── LED actions ─────────────────────────────────────────────────────────────

  Future<void> loadLed() async {
    if (_api == null) return;
    _ledEnabled = await _api!.getLed();
    notifyListeners();
  }

  Future<void> setLed(bool enabled) async {
    if (_api == null) return;
    if (enabled) {
      await _api!.ledOn();
    } else {
      await _api!.ledOff();
    }
    _ledEnabled = enabled;
    notifyListeners();
  }

  // ── System actions ──────────────────────────────────────────────────────────

  Future<void> loadPeriodicRestart() async {
    if (_api == null) return;
    final json = await _api!.getPeriodicRestart();
    _periodicRestartEnabled = json['enabled'] as bool;
    _periodicRestartIntervalH = (json['intervalHours'] as num).toInt();
    notifyListeners();
  }

  Future<void> setPeriodicRestart({required bool enabled, int? intervalHours}) async {
    if (_api == null) return;
    if (enabled) {
      await _api!.periodicRestartOn();
    } else {
      await _api!.periodicRestartOff();
    }
    if (intervalHours != null) {
      await _api!.setPeriodicRestartInterval(intervalHours);
    }
    await loadPeriodicRestart();
  }

  Future<void> restart() => _run(_api!.restart);
  Future<void> factoryReset() => _run(_api!.factoryReset);

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<void> _run(Future<void> Function() action) async {
    if (_api == null) return;
    try {
      await action();
      await _refreshStatus();
    } catch (e) {
      _lastError = _errorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  String _errorMessage(Object e) {
    if (e is ApiException) return 'Device error ${e.statusCode}: ${e.message}';
    return e.toString().replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _stopPolling();
    super.dispose();
  }
}
