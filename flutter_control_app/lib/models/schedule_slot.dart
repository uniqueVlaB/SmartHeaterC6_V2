const int dayMon = 1 << 0;
const int dayTue = 1 << 1;
const int dayWed = 1 << 2;
const int dayThu = 1 << 3;
const int dayFri = 1 << 4;
const int daySat = 1 << 5;
const int daySun = 1 << 6;
const int dayWorkdays = dayMon | dayTue | dayWed | dayThu | dayFri;
const int dayWeekend = daySat | daySun;
const int dayAll = 0x7F;

class ScheduleSlot {
  final int id;
  final int dayMask;
  final int fromMin;
  final int toMin;
  final double target;
  final bool enabled;

  const ScheduleSlot({
    required this.id,
    required this.dayMask,
    required this.fromMin,
    required this.toMin,
    required this.target,
    required this.enabled,
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ScheduleSlot(
      id: (json['id'] as num).toInt(),
      dayMask: (json['dayMask'] as num).toInt(),
      fromMin: _parseHHMM(json['from'] as String),
      toMin: _parseHHMM(json['to'] as String),
      target: (json['target'] as num?)?.toDouble() ?? 0.0,
      enabled: json['enabled'] as bool,
    );
  }

  static int _parseHHMM(String s) {
    final parts = s.split(':');
    if (parts.length != 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String get fromStr {
    final h = fromMin ~/ 60;
    final m = fromMin % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String get toStr {
    final h = toMin ~/ 60;
    final m = toMin % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String get daysLabel {
    if (dayMask == dayAll) return 'Every day';
    if (dayMask == dayWorkdays) return 'Workdays';
    if (dayMask == dayWeekend) return 'Weekend';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final bits = [dayMon, dayTue, dayWed, dayThu, dayFri, daySat, daySun];
    return [
      for (int i = 0; i < 7; i++)
        if (dayMask & bits[i] != 0) names[i]
    ].join(', ');
  }

  ScheduleSlot copyWith({
    int? id,
    int? dayMask,
    int? fromMin,
    int? toMin,
    double? target,
    bool? enabled,
  }) {
    return ScheduleSlot(
      id: id ?? this.id,
      dayMask: dayMask ?? this.dayMask,
      fromMin: fromMin ?? this.fromMin,
      toMin: toMin ?? this.toMin,
      target: target ?? this.target,
      enabled: enabled ?? this.enabled,
    );
  }
}
