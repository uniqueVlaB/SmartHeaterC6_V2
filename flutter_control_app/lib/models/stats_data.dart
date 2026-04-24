class HeatingSessionEntry {
  final String? start; // ISO datetime string or null
  final int durationSec;
  final double? startTemp;
  final double? endTemp;
  final double energyKWh;
  final double cost;

  const HeatingSessionEntry({
    required this.start,
    required this.durationSec,
    required this.startTemp,
    required this.endTemp,
    required this.energyKWh,
    required this.cost,
  });

  factory HeatingSessionEntry.fromJson(Map<String, dynamic> json) {
    return HeatingSessionEntry(
      start: json['start'] as String?,
      durationSec: (json['durationSec'] as num).toInt(),
      startTemp: (json['startTemp'] as num?)?.toDouble(),
      endTemp: (json['endTemp'] as num?)?.toDouble(),
      energyKWh: (json['energyKWh'] as num? ?? 0).toDouble(),
      cost: (json['cost'] as num? ?? 0).toDouble(),
    );
  }

  String get durationFormatted {
    final h = durationSec ~/ 3600;
    final m = (durationSec % 3600) ~/ 60;
    final s = durationSec % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  /// Formats the ISO start string as "YYYY-MM-DD HH:MM" or returns null.
  String? get startFormatted {
    if (start == null) return null;
    try {
      final dt = DateTime.parse(start!).toLocal();
      final d = '${dt.year.toString().padLeft(4, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')}';
      final t =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$d $t';
    } catch (_) {
      return start;
    }
  }
}

class StatsData {
  final String todayDate;
  final int todayHeatingSec;
  final int todaySessions;
  final double todayEnergyKWh;
  final double todayCost;
  final double monthEnergyKWh;
  final double monthCost;
  final double yearEnergyKWh;
  final double yearCost;
  final int allTimeHeatingSec;
  final int allTimeSessions;
  final double allTimeEnergyKWh;
  final double allTimeCost;
  final double pricePerKWh;
  final List<HeatingSessionEntry> log;

  const StatsData({
    required this.todayDate,
    required this.todayHeatingSec,
    required this.todaySessions,
    required this.todayEnergyKWh,
    required this.todayCost,
    required this.monthEnergyKWh,
    required this.monthCost,
    required this.yearEnergyKWh,
    required this.yearCost,
    required this.allTimeHeatingSec,
    required this.allTimeSessions,
    required this.allTimeEnergyKWh,
    required this.allTimeCost,
    required this.pricePerKWh,
    required this.log,
  });

  factory StatsData.fromJson(Map<String, dynamic> json) {
    final today = json['today'] as Map<String, dynamic>? ?? {};
    final month = json['month'] as Map<String, dynamic>? ?? {};
    final year  = json['year']  as Map<String, dynamic>? ?? {};
    final all   = json['allTime'] as Map<String, dynamic>? ?? {};
    final price = (json['pricePerKWh'] as num? ?? 0).toDouble();
    final logRaw = json['log'] as List<dynamic>? ?? [];
    return StatsData(
      todayDate:          today['date']           as String? ?? '',
      todayHeatingSec:    (today['heatingTimeSec'] as num? ?? 0).toInt(),
      todaySessions:      (today['sessions']       as num? ?? 0).toInt(),
      todayEnergyKWh:     (today['energyKWh']      as num? ?? 0).toDouble(),
      todayCost:          (today['cost']            as num? ?? 0).toDouble(),
      monthEnergyKWh:     (month['energyKWh']      as num? ?? 0).toDouble(),
      monthCost:          (month['cost']            as num? ?? 0).toDouble(),
      yearEnergyKWh:      (year['energyKWh']       as num? ?? 0).toDouble(),
      yearCost:           (year['cost']            as num? ?? 0).toDouble(),
      allTimeHeatingSec:  (all['heatingTimeSec']   as num? ?? 0).toInt(),
      allTimeSessions:    (all['sessions']         as num? ?? 0).toInt(),
      allTimeEnergyKWh:   (all['energyKWh']        as num? ?? 0).toDouble(),
      allTimeCost:        (all['cost']             as num? ?? 0).toDouble(),
      pricePerKWh:        price,
      log:               logRaw.map((e) => HeatingSessionEntry.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  String get todayHeatingFormatted {
    final h = todayHeatingSec ~/ 3600;
    final m = (todayHeatingSec % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String get allTimeHeatingFormatted {
    final h = allTimeHeatingSec ~/ 3600;
    final m = (allTimeHeatingSec % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
