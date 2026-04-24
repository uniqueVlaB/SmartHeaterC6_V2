import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/heater_provider.dart';
import '../models/heater_status.dart';
import '../widgets/info_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HeaterProvider>();
    final status = provider.status;

    if (status == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => provider.connect(provider.deviceUrl),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (status.fault) _FaultBanner(code: status.faultCode, details: status.faultDetails),
          _HeaterCard(status: status),
          const SizedBox(height: 12),
          _TemperaturesCard(status: status),
          const SizedBox(height: 12),
          _PowerCard(status: status),
          const SizedBox(height: 12),
          _QuickControlCard(status: status),
          const SizedBox(height: 12),
          if (status.scheduleActive) _ScheduleActiveCard(status: status),
          const SizedBox(height: 8),
          _SystemInfoCard(status: status),
        ],
      ),
    );
  }
}

// ── Fault banner ─────────────────────────────────────────────────────────────

class _FaultBanner extends StatelessWidget {
  final String? code;
  final String? details;

  const _FaultBanner({this.code, this.details});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.faultPrefix(code ?? 'unknown'),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onErrorContainer)),
                  if (details != null && details!.isNotEmpty)
                    Text(details!,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onErrorContainer)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main heater card ─────────────────────────────────────────────────────────

class _HeaterCard extends StatelessWidget {
  final HeaterStatus status;

  const _HeaterCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<HeaterProvider>();
    final isOn = status.heater;
    final isEnabled = status.enabled;
    final color = isOn ? Colors.orange : Theme.of(context).colorScheme.outline;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOn ? AppLocalizations.of(context)!.statusHeating : AppLocalizations.of(context)!.statusIdle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                      ),
                      if (status.reason == 'PAUSED')
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _reasonLabel(context, status.reason, status),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                try {
                                  await provider.heaterOn();
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString())));
                                  }
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.btnCancelPause,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          _reasonLabel(context, status.reason, status),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: (v) async {
                    try {
                      if (v) {
                        await provider.heaterOn();
                      } else {
                        await provider.heaterOff();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            Builder(builder: (context) {
              final l = AppLocalizations.of(context)!;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _TempDisplay(label: l.labelTarget, value: status.effectiveTarget, unit: '°C'),
                  _TempDisplay(label: l.labelWater, value: status.waterTemp, unit: '°C'),
                  _TempDisplay(label: l.labelBody, value: status.bodyTemp, unit: '°C'),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _reasonLabel(BuildContext context, String reason, HeaterStatus s) {
    final l = AppLocalizations.of(context)!;
    switch (reason) {
      case 'BOOST':
        return l.reasonBoost(s.boostTarget?.toStringAsFixed(1) ?? '--');
      case 'PAUSED':
        final remaining = s.pauseRemaining;
        return l.reasonPaused(remaining ~/ 60, remaining % 60);
      case 'SCHEDULE':
        return l.reasonSchedule(s.scheduleFrom ?? '', s.scheduleTo ?? '');
      case 'CYCLE_PAUSE':
        return l.reasonCyclePause(s.cyclePauseRemaining ~/ 60);
      case 'WAITING':
        return l.reasonWaiting;
      case 'DISABLED':
        return l.reasonDisabled;
      default:
        return reason;
    }
  }
}

class _TempDisplay extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;

  const _TempDisplay({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value != null ? '${value!.toStringAsFixed(1)}$unit' : '--',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
      ],
    );
  }
}

// ── Temperatures card ────────────────────────────────────────────────────────

class _TemperaturesCard extends StatelessWidget {
  final HeaterStatus status;

  const _TemperaturesCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return InfoCard(
      title: l.sectionTemperatures,
      icon: Icons.thermostat,
      children: [
        InfoRow(label: l.labelWater, value: _fmt(status.waterTemp, '°C')),
        InfoRow(label: l.labelBody, value: _fmt(status.bodyTemp, '°C')),
        InfoRow(label: l.labelTarget, value: '${status.effectiveTarget.toStringAsFixed(1)}°C'),
        InfoRow(label: l.labelMaxTarget, value: '${status.maxTarget.toStringAsFixed(1)}°C'),
        InfoRow(label: l.labelHysteresis, value: '${status.hysteresis.toStringAsFixed(1)}°C'),
        InfoRow(label: l.labelCpuTemp, value: '${status.cpuTemp.toStringAsFixed(1)}°C'),
      ],
    );
  }

  String _fmt(double? v, String unit) =>
      v != null ? '${v.toStringAsFixed(1)}$unit' : '--';
}

// ── Power card ───────────────────────────────────────────────────────────────

class _PowerCard extends StatelessWidget {
  final HeaterStatus status;

  const _PowerCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return InfoCard(
      title: l.sectionPower,
      icon: Icons.bolt,
      children: [
        InfoRow(label: l.labelPower, value: '${status.power.toStringAsFixed(1)} W'),
        InfoRow(label: l.labelVoltage, value: '${status.voltage.toStringAsFixed(1)} V'),
        InfoRow(label: l.labelCurrent, value: '${status.current.toStringAsFixed(3)} A'),
        InfoRow(label: l.labelEnergy, value: '${status.energy.toStringAsFixed(3)} kWh'),
        InfoRow(label: l.labelFrequency, value: '${status.frequency.toStringAsFixed(1)} Hz'),
        InfoRow(label: l.labelPowerFactor, value: status.pf.toStringAsFixed(2)),
      ],
    );
  }
}

// ── Quick control card ───────────────────────────────────────────────────────

class _QuickControlCard extends StatelessWidget {
  final HeaterStatus status;

  const _QuickControlCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<HeaterProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.sectionQuickControls,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _showSetTargetDialog(context, provider, status),
                  icon: const Icon(Icons.thermostat, size: 16),
                  label: Text(AppLocalizations.of(context)!.btnSetTarget),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _showBoostDialog(context, provider, status),
                  icon: const Icon(Icons.rocket_launch, size: 16),
                  label: Text(AppLocalizations.of(context)!.btnBoost),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _showPauseDialog(context, provider),
                  icon: const Icon(Icons.pause_circle_outline, size: 16),
                  label: Text(AppLocalizations.of(context)!.btnPause),
                ),
                if (status.reason == 'PAUSED' || status.reason == 'BOOST')
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      try {
                        await provider.heaterOn();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
                    icon: const Icon(Icons.restore, size: 16),
                    label: Text(AppLocalizations.of(context)!.btnResume),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSetTargetDialog(
      BuildContext context, HeaterProvider provider, HeaterStatus status) async {
    double value = status.target;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _SliderDialog(
        title: AppLocalizations.of(context)!.dialogSetTarget,
        subtitle: AppLocalizations.of(context)!.dialogSetTargetDesc,
        value: value,
        min: 30,
        max: status.maxTarget,
        divisions: ((status.maxTarget - 30) * 2).round(),
        unit: '°C',
        onChanged: (v) => value = v,
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await provider.setTarget(value);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  Future<void> _showBoostDialog(
      BuildContext context, HeaterProvider provider, HeaterStatus status) async {
    double value = status.effectiveTarget;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _SliderDialog(
        title: AppLocalizations.of(context)!.dialogBoost,
        value: value,
        min: 30,
        max: status.maxTarget,
        divisions: ((status.maxTarget - 30) * 2).round(),
        unit: '°C',
        onChanged: (v) => value = v,
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await provider.boost(value);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  Future<void> _showPauseDialog(
      BuildContext context, HeaterProvider provider) async {
    int minutes = 30;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _SliderDialog(
        title: AppLocalizations.of(context)!.dialogPause,
        value: minutes.toDouble(),
        min: 5,
        max: 240,
        divisions: 47,
        unit: ' min',
        onChanged: (v) => minutes = v.round(),
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await provider.pause(minutes);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }
}

// ── Schedule active card ──────────────────────────────────────────────────────

class _ScheduleActiveCard extends StatelessWidget {
  final HeaterStatus status;

  const _ScheduleActiveCard({required this.status});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.schedule,
                color: Theme.of(context).colorScheme.onPrimaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.scheduleActive(
                  status.scheduleFrom ?? '',
                  status.scheduleTo ?? '',
                  status.scheduleTarget?.toStringAsFixed(1) ?? '--',
                ),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── System info card ─────────────────────────────────────────────────────────

class _SystemInfoCard extends StatelessWidget {
  final HeaterStatus status;

  const _SystemInfoCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return InfoCard(
      title: l.sectionSystem,
      icon: Icons.memory,
      children: [
        InfoRow(label: l.labelTime, value: status.time),
        InfoRow(label: l.labelTimeSynced, value: status.timeSynced ? l.labelYes : l.labelNo),
        InfoRow(label: l.labelCpuLoad, value: '${status.cpuLoad.toStringAsFixed(1)}%'),
        InfoRow(label: l.labelDefaultMode, value: status.defaultMode ? l.labelYes : l.labelNo),
        InfoRow(
            label: l.labelCycleMode,
            value: status.cycleMode
                ? l.labelCycleModeOn(status.cycleOnMinutes, status.cycleOffMinutes)
                : l.labelNo),
      ],
    );
  }
}

// ── Slider dialog ─────────────────────────────────────────────────────────────

class _SliderDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String unit;
  final void Function(double) onChanged;

  const _SliderDialog({
    required this.title,
    this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.unit,
    required this.onChanged,
  });

  @override
  State<_SliderDialog> createState() => _SliderDialogState();
}

class _SliderDialogState extends State<_SliderDialog> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value.clamp(widget.min, widget.max);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.subtitle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                widget.subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          Text(
            '${_value.toStringAsFixed(1)}${widget.unit}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Slider(
            value: _value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            label: '${_value.toStringAsFixed(1)}${widget.unit}',
            onChanged: (v) {
              setState(() => _value = v);
              widget.onChanged(v);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.dialogCancel)),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.dialogSet)),
      ],
    );
  }
}
