import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/heater_status.dart';
import '../models/schedule_slot.dart';
import '../models/stats_data.dart';

class HeaterApi {
  final String baseUrl;
  final Duration timeout;

  HeaterApi({required this.baseUrl, this.timeout = const Duration(seconds: 5)});

  Uri _uri(String path, [Map<String, String>? params]) {
    final uri = Uri.parse('$baseUrl$path');
    return params != null ? uri.replace(queryParameters: params) : uri;
  }

  Future<Map<String, dynamic>> _get(String path, [Map<String, String>? params]) async {
    final response = await http.get(_uri(path, params)).timeout(timeout);
    _checkStatus(response);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint('[HeaterApi] GET $path → ${response.body}');
    return decoded;
  }

  Future<Map<String, dynamic>> _post(String path, [Map<String, String>? params]) async {
    final response = await http.post(_uri(path, params)).timeout(timeout);
    _checkStatus(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      Map<String, dynamic>? body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
      throw ApiException(
        response.statusCode,
        body?['error'] as String? ?? response.body,
      );
    }
  }

  // ── Status ──────────────────────────────────────────────────────────────────

  Future<HeaterStatus> getStatus() async {
    final json = await _get('/status');
    return HeaterStatus.fromJson(json);
  }

  // ── Heater control ──────────────────────────────────────────────────────────

  Future<void> heaterOn() => _post('/heater/on');
  Future<void> heaterOff() => _post('/heater/off');
  Future<void> defaultModeOn() => _post('/heater/default/on');
  Future<void> defaultModeOff() => _post('/heater/default/off');

  Future<void> pause(int minutes) =>
      _post('/heater/pause', {'minutes': minutes.toString()});

  Future<void> boost(double temp) =>
      _post('/heater/boost', {'temp': temp.toStringAsFixed(1)});

  Future<void> setTarget(double temp) =>
      _post('/heater/target', {'value': temp.toStringAsFixed(1)});

  Future<void> setMaxTarget(double temp) =>
      _post('/heater/maxTarget', {'value': temp.toStringAsFixed(1)});

  Future<void> setHysteresis(double value) =>
      _post('/heater/hysteresis', {'value': value.toStringAsFixed(1)});

  Future<double> getHysteresis() async {
    final json = await _get('/heater/hysteresis');
    return (json['hysteresis'] as num).toDouble();
  }

  // ── Duty-cycle ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCycle() => _get('/heater/cycle');
  Future<void> cycleOn() => _post('/heater/cycle/on');
  Future<void> cycleOff() => _post('/heater/cycle/off');

  Future<void> setCycleConfig({required int onMinutes, required int offMinutes}) =>
      _post('/heater/cycle/config', {
        'on': onMinutes.toString(),
        'off': offMinutes.toString(),
      });

  // ── Power ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getPower() => _get('/power');
  Future<void> resetEnergy() => _post('/power/reset');

  // ── Schedule ────────────────────────────────────────────────────────────────

  Future<List<ScheduleSlot>> getSchedule() async {
    final response = await http.get(_uri('/schedule')).timeout(timeout);
    _checkStatus(response);
    debugPrint('[HeaterApi] GET /schedule → ${response.body}');
    final decoded = jsonDecode(response.body);
    // ESP32 returns a raw JSON array (not wrapped in an object)
    final slots = decoded as List<dynamic>;
    return slots.map((s) => ScheduleSlot.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<List<ScheduleSlot>> _postSchedule(String path, [Map<String, String>? params]) async {
    final response = await http.post(_uri(path, params)).timeout(timeout);
    _checkStatus(response);
    final decoded = jsonDecode(response.body);
    final slots = decoded as List<dynamic>;
    return slots.map((s) => ScheduleSlot.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<List<ScheduleSlot>> addScheduleSlot({
    required int dayMask,
    required int fromMin,
    required int toMin,
    double target = 0,
  }) =>
      _postSchedule('/schedule/add', {
        'days': dayMask.toString(),
        'from': _minToHHMM(fromMin),
        'to': _minToHHMM(toMin),
        'target': target.toStringAsFixed(1),
      });

  Future<List<ScheduleSlot>> editScheduleSlot({
    required int id,
    int? dayMask,
    int? fromMin,
    int? toMin,
    double? target,
  }) {
    final params = <String, String>{'id': id.toString()};
    if (dayMask != null) params['days'] = dayMask.toString();
    if (fromMin != null) params['from'] = _minToHHMM(fromMin);
    if (toMin != null) params['to'] = _minToHHMM(toMin);
    if (target != null) params['target'] = target.toStringAsFixed(1);
    return _postSchedule('/schedule/edit', params);
  }

  Future<List<ScheduleSlot>> removeScheduleSlot(int id) =>
      _postSchedule('/schedule/remove', {'id': id.toString()});

  Future<List<ScheduleSlot>> enableScheduleSlot(int id) =>
      _postSchedule('/schedule/enable', {'id': id.toString()});

  Future<List<ScheduleSlot>> disableScheduleSlot(int id) =>
      _postSchedule('/schedule/disable', {'id': id.toString()});

  Future<void> clearSchedule() => _post('/schedule/clear');

  // ── LED ─────────────────────────────────────────────────────────────────────

  Future<bool> getLed() async {
    final json = await _get('/led');
    return json['enabled'] as bool;
  }

  Future<void> ledOn() => _post('/led/on');
  Future<void> ledOff() => _post('/led/off');

  // ── Time ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTime() => _get('/time');

  // ── Fault ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getFault() => _get('/fault');

  // ── Stats ───────────────────────────────────────────────────────────────────

  Future<StatsData> getStats() async {
    final json = await _get('/stats');
    return StatsData.fromJson(json);
  }

  Future<void> setPrice(double pricePerKWh) =>
      _post('/stats/price', {'value': pricePerKWh.toStringAsFixed(4)});

  Future<void> resetStats() => _post('/stats/reset');

  // ── Tariff ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTariff() => _get('/stats/tariff');
  Future<Map<String, dynamic>> tariffOn() => _post('/stats/tariff/on');
  Future<Map<String, dynamic>> tariffOff() => _post('/stats/tariff/off');

  Future<Map<String, dynamic>> setTariffConfig({
    double? dayPrice,
    double? nightPrice,
    int? dayStart,
    int? nightStart,
  }) {
    final params = <String, String>{};
    if (dayPrice != null) params['dayPrice'] = dayPrice.toStringAsFixed(4);
    if (nightPrice != null) params['nightPrice'] = nightPrice.toStringAsFixed(4);
    if (dayStart != null) params['dayStart'] = dayStart.toString();
    if (nightStart != null) params['nightStart'] = nightStart.toString();
    return _post('/stats/tariff/config', params);
  }

  // ── System ──────────────────────────────────────────────────────────────────

  Future<void> restart() => _post('/system/restart');
  Future<void> factoryReset() => _post('/system/factory-reset');

  Future<Map<String, dynamic>> getPeriodicRestart() =>
      _get('/system/periodic-restart');

  Future<void> periodicRestartOn() => _post('/system/periodic-restart/on');
  Future<void> periodicRestartOff() => _post('/system/periodic-restart/off');

  Future<void> setPeriodicRestartInterval(int hours) =>
      _post('/system/periodic-restart/config', {'hours': hours.toString()});

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String _minToHHMM(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
