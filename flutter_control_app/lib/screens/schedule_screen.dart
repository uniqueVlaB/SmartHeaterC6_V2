import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/heater_provider.dart';
import '../models/schedule_slot.dart';

String _localizedDaysLabel(AppLocalizations l, int dayMask) {
  if (dayMask == dayAll) return l.daysEveryDay;
  if (dayMask == dayWorkdays) return l.daysWorkdays;
  if (dayMask == dayWeekend) return l.daysWeekend;
  final names = [l.dayMon, l.dayTue, l.dayWed, l.dayThu, l.dayFri, l.daySat, l.daySun];
  final bits = [dayMon, dayTue, dayWed, dayThu, dayFri, daySat, daySun];
  return [for (int i = 0; i < 7; i++) if (dayMask & bits[i] != 0) names[i]].join(', ');
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HeaterProvider>().loadSchedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HeaterProvider>();
    final slots = provider.schedule;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: slots == null
          ? (provider.scheduleLoadFailed
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(l.connectionError, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => provider.loadSchedule(),
                        icon: const Icon(Icons.refresh),
                        label: Text(l.retry),
                      ),
                    ],
                  ),
                )
              : const Center(child: CircularProgressIndicator()))
          : slots.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(l.scheduleEmpty,
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 4),
                      Text(l.scheduleHint,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: slots.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _SlotTile(slot: slots[i]),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, provider),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog(
      BuildContext context, HeaterProvider provider) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _SlotDialog(
        onSave: ({
          required int dayMask,
          required int fromMin,
          required int toMin,
          required double target,
        }) async {
          try {
            await provider.addScheduleSlot(
              dayMask: dayMask,
              fromMin: fromMin,
              toMin: toMin,
              target: target,
            );
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(e.toString())));
            }
          }
        },
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  final ScheduleSlot slot;

  const _SlotTile({required this.slot});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<HeaterProvider>();

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: slot.enabled
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.schedule,
            color: slot.enabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        title: Text('${slot.fromStr}\u00A0–\u00A0${slot.toStr}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${_localizedDaysLabel(AppLocalizations.of(context)!, slot.dayMask)}${slot.target > 0 ? ' \u00b7 ${slot.target.toStringAsFixed(1)}°C' : ''}',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: slot.enabled,
              onChanged: (v) async {
                try {
                  await provider.toggleScheduleSlot(slot.id, enable: v);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
            ),
            PopupMenuButton<String>(
              onSelected: (action) => _handleAction(context, action, provider),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context)!.dialogEdit)),
                PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)!.dialogRemove)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, String action, HeaterProvider provider) async {
    if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(ctx)!.scheduleRemoveConfirmTitle),
          content: Text(AppLocalizations.of(ctx)!.scheduleRemoveConfirmBody(
              slot.fromStr, slot.toStr,
              _localizedDaysLabel(AppLocalizations.of(ctx)!, slot.dayMask))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(ctx)!.dialogCancel)),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppLocalizations.of(ctx)!.dialogRemove)),
          ],
        ),
      );
      if (confirm == true && context.mounted) {
        try {
          await provider.removeScheduleSlot(slot.id);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(e.toString())));
          }
        }
      }
    } else if (action == 'edit') {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => _SlotDialog(
            existing: slot,
            onSave: ({
              required int dayMask,
              required int fromMin,
              required int toMin,
              required double target,
            }) async {
              try {
                await provider.editScheduleSlot(
                  id: slot.id,
                  dayMask: dayMask,
                  fromMin: fromMin,
                  toMin: toMin,
                  target: target,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
          ),
        );
      }
    }
  }
}

// ── Add / Edit dialog ────────────────────────────────────────────────────────

typedef _SaveCallback = Future<void> Function({
  required int dayMask,
  required int fromMin,
  required int toMin,
  required double target,
});

class _SlotDialog extends StatefulWidget {
  final ScheduleSlot? existing;
  final _SaveCallback onSave;

  const _SlotDialog({this.existing, required this.onSave});

  @override
  State<_SlotDialog> createState() => _SlotDialogState();
}

class _SlotDialogState extends State<_SlotDialog> {
  late int _dayMask;
  late int _fromMin;
  late int _toMin;
  late double _target;
  bool _saving = false;

  static const _dayBits = [dayMon, dayTue, dayWed, dayThu, dayFri, daySat, daySun];
  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _dayMask = widget.existing?.dayMask ?? dayAll;
    _fromMin = widget.existing?.fromMin ?? (7 * 60);
    _toMin = widget.existing?.toMin ?? (9 * 60);
    _target = widget.existing?.target ?? 60.0;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(
          dayMask: _dayMask,
          fromMin: _fromMin,
          toMin: _toMin,
          target: _target);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime(bool isFrom) async {
    final initial = TimeOfDay(
      hour: isFrom ? _fromMin ~/ 60 : _toMin ~/ 60,
      minute: isFrom ? _fromMin % 60 : _toMin % 60,
    );
    final picked =
        await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromMin = picked.hour * 60 + picked.minute;
        } else {
          _toMin = picked.hour * 60 + picked.minute;
        }
      });
    }
  }

  String _minLabel(int m) {
    final h = m ~/ 60;
    final min = m % 60;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? AppLocalizations.of(context)!.scheduleAddTitle : AppLocalizations.of(context)!.scheduleEditTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.scheduleDays,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                for (int i = 0; i < 7; i++)
                  FilterChip(
                    label: Text(_dayLabels[i]),
                    selected: _dayMask & _dayBits[i] != 0,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _dayMask |= _dayBits[i];
                        } else {
                          _dayMask &= ~_dayBits[i];
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(true),
                    icon: const Icon(Icons.access_time, size: 16),
                    label: Text(AppLocalizations.of(context)!.scheduleFrom(_minLabel(_fromMin))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(false),
                    icon: const Icon(Icons.access_time, size: 16),
                    label: Text(AppLocalizations.of(context)!.scheduleTo(_minLabel(_toMin))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.scheduleTargetLabel(_target.toStringAsFixed(1)),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            Slider(
              value: _target,
              min: 30,
              max: 90,
              divisions: 120,
              label: '${_target.toStringAsFixed(1)}°C',
              onChanged: (v) => setState(() => _target = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.dialogCancel)),
        FilledButton(
            onPressed: _saving || _dayMask == 0 ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(AppLocalizations.of(context)!.dialogSave)),
      ],
    );
  }
}
