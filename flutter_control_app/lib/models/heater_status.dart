class HeaterStatus {
  final bool fault;
  final String? faultCode;
  final String? faultDetails;
  final String time;
  final bool timeSynced;
  final bool heater;
  final bool enabled;
  final bool defaultMode;
  final String reason;
  final bool scheduleActive;
  final double target;
  final double effectiveTarget;
  final double maxTarget;
  final double hysteresis;
  final int pauseRemaining;
  final double? boostTarget;
  final bool cycleMode;
  final int cycleOnMinutes;
  final int cycleOffMinutes;
  final int cyclePauseRemaining;
  final double? scheduleTarget;
  final String? scheduleFrom;
  final String? scheduleTo;
  final int? scheduleSlotId;
  final double? waterTemp;
  final double? bodyTemp;
  final double voltage;
  final double current;
  final double power;
  final double energy;
  final double frequency;
  final double pf;
  final double cpuTemp;
  final double cpuLoad;

  const HeaterStatus({
    required this.fault,
    this.faultCode,
    this.faultDetails,
    required this.time,
    required this.timeSynced,
    required this.heater,
    required this.enabled,
    required this.defaultMode,
    required this.reason,
    required this.scheduleActive,
    required this.target,
    required this.effectiveTarget,
    required this.maxTarget,
    required this.hysteresis,
    required this.pauseRemaining,
    this.boostTarget,
    required this.cycleMode,
    required this.cycleOnMinutes,
    required this.cycleOffMinutes,
    required this.cyclePauseRemaining,
    this.scheduleTarget,
    this.scheduleFrom,
    this.scheduleTo,
    this.scheduleSlotId,
    this.waterTemp,
    this.bodyTemp,
    required this.voltage,
    required this.current,
    required this.power,
    required this.energy,
    required this.frequency,
    required this.pf,
    required this.cpuTemp,
    required this.cpuLoad,
  });

  factory HeaterStatus.fromJson(Map<String, dynamic> json) {
    return HeaterStatus(
      fault: json['fault'] as bool,
      faultCode: json['faultCode'] as String?,
      faultDetails: json['faultDetails'] as String?,
      time: json['time'] as String,
      timeSynced: json['timeSynced'] as bool,
      heater: json['heater'] as bool,
      enabled: json['enabled'] as bool,
      defaultMode: json['defaultMode'] as bool,
      reason: json['reason'] as String,
      scheduleActive: json['scheduleActive'] as bool,
      target: (json['target'] as num).toDouble(),
      effectiveTarget: (json['effectiveTarget'] as num).toDouble(),
      maxTarget: (json['maxTarget'] as num).toDouble(),
      hysteresis: (json['hysteresis'] as num).toDouble(),
      pauseRemaining: (json['pauseRemaining'] as num).toInt(),
      boostTarget: json['boostTarget'] == null ? null : (json['boostTarget'] as num).toDouble(),
      cycleMode: json['cycleMode'] as bool,
      cycleOnMinutes: (json['cycleOnMinutes'] as num).toInt(),
      cycleOffMinutes: (json['cycleOffMinutes'] as num).toInt(),
      cyclePauseRemaining: (json['cyclePauseRemaining'] as num).toInt(),
      scheduleTarget: json['scheduleTarget'] == null ? null : (json['scheduleTarget'] as num).toDouble(),
      scheduleFrom: json['scheduleFrom'] as String?,
      scheduleTo: json['scheduleTo'] as String?,
      scheduleSlotId: json['scheduleSlotId'] == null ? null : (json['scheduleSlotId'] as num).toInt(),
      waterTemp: json['waterTemp'] == null ? null : (json['waterTemp'] as num).toDouble(),
      bodyTemp: json['bodyTemp'] == null ? null : (json['bodyTemp'] as num).toDouble(),
      voltage: (json['voltage'] as num).toDouble(),
      current: (json['current'] as num).toDouble(),
      power: (json['power'] as num).toDouble(),
      energy: (json['energy'] as num).toDouble(),
      frequency: (json['frequency'] as num).toDouble(),
      pf: (json['pf'] as num).toDouble(),
      cpuTemp: (json['cpuTemp'] as num).toDouble(),
      cpuLoad: (json['cpuLoad'] as num).toDouble(),
    );
  }
}
