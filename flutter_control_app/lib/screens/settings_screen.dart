import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/heater_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/tariff_provider.dart';
import '../widgets/info_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<HeaterProvider>();
      provider.loadLed();
      provider.loadPeriodicRestart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HeaterProvider>();
    final tariff = context.watch<TariffProvider>();
    final status = provider.status;
    final l = AppLocalizations.of(context)!;
    final currentLocale = context.watch<LocaleProvider>().locale;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── App ──────────────────────────────────────────────────────────────
        _SectionHeader(l.settingsApp),
        Card(
          child: ListTile(
            leading: const Icon(Icons.language),
            title: Text(l.settingsLanguage),
            subtitle: Text(_localeName(l, currentLocale)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context),
          ),
        ),
        const SizedBox(height: 12),

        // ── Heater config ─────────────────────────────────────────────────────
        if (status != null) ...[
          _SectionHeader(l.settingsHeater),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l.settingsDefaultMode),
                  subtitle: Text(l.settingsDefaultModeDesc),
                  value: status.defaultMode,
                  onChanged: (v) async {
                    try {
                      if (v) {
                        await provider.defaultModeOn();
                      } else {
                        await provider.defaultModeOff();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                ),
                ListTile(
                  title: Text(l.settingsMaxTarget),
                  subtitle: Text('${status.maxTarget.toStringAsFixed(1)}°C'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSetMaxTargetDialog(context, provider, status.maxTarget),
                ),
                ListTile(
                  title: Text(l.settingsHysteresis),
                  subtitle: Text('${status.hysteresis.toStringAsFixed(1)}°C'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      _showHysteresisDialog(context, provider, status.hysteresis),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Duty-cycle ───────────────────────────────────────────────────
          _SectionHeader(l.settingsDutyCycle),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l.settingsCycleMode),
                  subtitle: Text(l.settingsCycleModeDesc),
                  value: status.cycleMode,
                  onChanged: (v) async {
                    try {
                      if (v) {
                        await provider.cycleOn();
                      } else {
                        await provider.cycleOff();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                ),
                if (status.cycleMode)
                  ListTile(
                    title: Text(l.settingsCycleConfig),
                    subtitle: Text(l.settingsCycleConfigDesc(
                        status.cycleOnMinutes, status.cycleOffMinutes)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showCycleConfigDialog(
                        context, provider, status.cycleOnMinutes, status.cycleOffMinutes),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── LED ──────────────────────────────────────────────────────────────
        _SectionHeader(l.settingsLed),
        Card(
          child: SwitchListTile(
            title: Text(l.settingsStatusLed),
            subtitle: Text(l.settingsStatusLedDesc),
            value: provider.ledEnabled ?? false,
            onChanged: provider.ledEnabled == null
                ? null
                : (v) async {
                    try {
                      await provider.setLed(v);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
          ),
        ),
        const SizedBox(height: 12),

        // ── System ───────────────────────────────────────────────────────────
        _SectionHeader(l.settingsSystem),
        Card(
          child: Column(
            children: [
              // Periodic restart
              SwitchListTile(
                title: Text(l.settingsPeriodicRestart),
                subtitle: Text(provider.periodicRestartEnabled == true
                    ? l.settingsPeriodicRestartDesc(
                        provider.periodicRestartIntervalH ?? 24)
                    : l.settingsPeriodicRestartDisabled),
                value: provider.periodicRestartEnabled ?? false,
                onChanged: provider.periodicRestartEnabled == null
                    ? null
                    : (v) async {
                        try {
                          await provider.setPeriodicRestart(enabled: v);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())));
                          }
                        }
                      },
              ),
              if (provider.periodicRestartEnabled == true)
                ListTile(
                  title: Text(l.settingsRestartInterval),
                  subtitle: Text(l.settingsRestartIntervalDesc(
                      provider.periodicRestartIntervalH ?? 24)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPeriodicRestartIntervalDialog(
                      context, provider, provider.periodicRestartIntervalH ?? 24),
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: Text(l.settingsRestartDevice),
                onTap: () => _confirmAction(context, l.settingsRestartDevice,
                    l.settingsRestartDeviceMsg, provider.restart),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.factory_outlined,
                    color: Theme.of(context).colorScheme.error),
                title: Text(l.settingsFactoryReset,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () => _confirmAction(context, l.settingsFactoryReset,
                    l.settingsFactoryResetMsg, provider.factoryReset,
                    danger: true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Device info ──────────────────────────────────────────────────────
        _SectionHeader(l.settingsDevice),
        InfoCard(
          title: l.settingsConnection,
          icon: Icons.wifi,
          children: [
            InfoRow(label: l.settingsUrl, value: provider.deviceUrl),
          ],
        ),

        // ── Electricity Tariff ────────────────────────────────────────────────
        const SizedBox(height: 12),
        _SectionHeader(l.tariffSectionTitle),
        _TariffCard(tariff: tariff, provider: provider, l: l),

        // ── Notifications placeholder ────────────────────────────────────────
        const SizedBox(height: 12),
        _SectionHeader(l.settingsNotifications),
        Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(l.settingsPushNotifications),
            subtitle: Text(l.settingsPushComingSoon),
            trailing:
                const Icon(Icons.lock_outline, color: Colors.grey, size: 18),
            enabled: false,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────────

  String _localeName(AppLocalizations l, Locale? locale) {
    if (locale == null) return l.settingsLanguageSystem;
    if (locale.languageCode == 'en') return l.settingsLanguageEn;
    if (locale.languageCode == 'uk') return l.settingsLanguageUk;
    return locale.languageCode;
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final localeProvider = context.read<LocaleProvider>();
    final l = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _LanguageDialog(
        current: localeProvider.locale,
        l: l,
        onSelected: localeProvider.setLocale,
      ),
    );
  }

  Future<void> _showSetMaxTargetDialog(
      BuildContext context, HeaterProvider provider, double current) async {
    double value = current;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _SimpleSliderDialog(
        title: AppLocalizations.of(context)!.settingsMaxTarget,
        value: current,
        min: 40,
        max: 95,
        divisions: 110,
        unit: '°C',
        onChanged: (v) => value = v,
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await provider.setMaxTarget(value);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  Future<void> _showHysteresisDialog(
      BuildContext context, HeaterProvider provider, double current) async {
    double value = current;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _SimpleSliderDialog(
        title: AppLocalizations.of(context)!.settingsHysteresis,
        value: current,
        min: 0.5,
        max: 5.0,
        divisions: 9,
        unit: '°C',
        onChanged: (v) => value = v,
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await provider.setHysteresis(value);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  Future<void> _showCycleConfigDialog(BuildContext context,
      HeaterProvider provider, int onMin, int offMin) async {
    int on = onMin;
    int off = offMin;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _CycleConfigDialog(
        onMin: onMin,
        offMin: offMin,
        onOnChanged: (v) => on = v,
        onOffChanged: (v) => off = v,
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await provider.setCycleConfig(onMinutes: on, offMinutes: off);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  Future<void> _showPeriodicRestartIntervalDialog(
      BuildContext context, HeaterProvider provider, int current) async {
    int value = current;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _SimpleSliderDialog(
        title: AppLocalizations.of(context)!.settingsRestartIntervalTitle,
        value: current.toDouble(),
        min: 1,
        max: 168,
        divisions: 167,
        unit: 'h',
        onChanged: (v) => value = v.round(),
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await provider.setPeriodicRestart(
            enabled: provider.periodicRestartEnabled ?? true,
            intervalHours: value);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  Future<void> _confirmAction(
      BuildContext context, String title, String message, Future<void> Function() action,
      {bool danger = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(ctx)!.dialogCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: danger
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error)
                : null,
            child: Text(AppLocalizations.of(ctx)!.dialogConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await action();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _SimpleSliderDialog extends StatefulWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String unit;
  final void Function(double) onChanged;

  const _SimpleSliderDialog({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.unit,
    required this.onChanged,
  });

  @override
  State<_SimpleSliderDialog> createState() => _SimpleSliderDialogState();
}

class _SimpleSliderDialogState extends State<_SimpleSliderDialog> {
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

class _CycleConfigDialog extends StatefulWidget {
  final int onMin;
  final int offMin;
  final void Function(int) onOnChanged;
  final void Function(int) onOffChanged;

  const _CycleConfigDialog({
    required this.onMin,
    required this.offMin,
    required this.onOnChanged,
    required this.onOffChanged,
  });

  @override
  State<_CycleConfigDialog> createState() => _CycleConfigDialogState();
}

class _CycleConfigDialogState extends State<_CycleConfigDialog> {  late double _on;
  late double _off;

  @override
  void initState() {
    super.initState();
    _on = widget.onMin.toDouble();
    _off = widget.offMin.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.settingsCycleConfigTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.settingsCycleOn(_on.round()),
              style: Theme.of(context).textTheme.labelLarge),
          Slider(
            value: _on,
            min: 1,
            max: 120,
            divisions: 119,
            label: '${_on.round()} min',
            onChanged: (v) {
              setState(() => _on = v);
              widget.onOnChanged(v.round());
            },
          ),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.settingsCycleOff(_off.round()),
              style: Theme.of(context).textTheme.labelLarge),
          Slider(
            value: _off,
            min: 1,
            max: 120,
            divisions: 119,
            label: '${_off.round()} min',
            onChanged: (v) {
              setState(() => _off = v);
              widget.onOffChanged(v.round());
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

// ── Language dialog ───────────────────────────────────────────────────────────

class _LanguageDialog extends StatelessWidget {
  final Locale? current;
  final AppLocalizations l;
  final void Function(Locale?) onSelected;

  const _LanguageDialog({
    required this.current,
    required this.l,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = <(Locale?, String)>[
      (null, l.settingsLanguageSystem),
      (const Locale('en'), l.settingsLanguageEn),
      (const Locale('uk'), l.settingsLanguageUk),
    ];
    return AlertDialog(
      title: Text(l.settingsLanguage),
      content: RadioGroup<String?>(
        groupValue: current?.languageCode,
        onChanged: (code) {
          final locale = (code == null) ? null : Locale(code);
          onSelected(locale);
          Navigator.pop(context);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            return RadioListTile<String?>(
              value: opt.$1?.languageCode,
              title: Text(opt.$2),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Tariff Card ───────────────────────────────────────────────────────────────

class _TariffCard extends StatelessWidget {
  final TariffProvider tariff;
  final HeaterProvider provider;
  final AppLocalizations l;

  const _TariffCard({
    required this.tariff,
    required this.provider,
    required this.l,
  });

  String _priceLabel(double price) =>
      '${price.toStringAsFixed(4)} ${l.currencyPerKWh}';

  Future<void> _editPrice(
    BuildContext context,
    String title,
    double current,
    void Function(double) onSave,
  ) async {
    double value = current;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _PriceInputDialog(
        title: title,
        initial: current,
        suffix: l.currencyPerKWh,
        onChanged: (v) => value = v,
      ),
    );
    if (confirmed == true && context.mounted) onSave(value);
  }

  Future<void> _editHour(
    BuildContext context,
    String title,
    int current,
    void Function(int) onSave,
  ) async {
    int value = current;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _HourPickerDialog(
        title: title,
        initial: current,
        onChanged: (v) => value = v,
      ),
    );
    if (confirmed == true && context.mounted) onSave(value);
  }

  @override
  Widget build(BuildContext context) {
    final api = provider.api;
    final zoneLabel = tariff.isDayZone ? l.tariffDayZone : l.tariffNightZone;

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.bolt),
            title: Text(l.tariffModeLabel),
            subtitle: Text(tariff.tariffModeEnabled
                ? l.tariffActiveZone(zoneLabel)
                : l.tariffModeDesc),
            value: tariff.tariffModeEnabled,
            onChanged: (v) => tariff.setEnabled(v, api: api),
          ),
          if (tariff.tariffModeEnabled) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.wb_sunny_outlined),
              title: Text(l.tariffDayPrice(
                  tariff.dayStartHour.toString().padLeft(2, '0'))),
              subtitle: Text(_priceLabel(tariff.dayPrice)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editPrice(
                context,
                l.tariffSetDayPrice,
                tariff.dayPrice,
                (v) => tariff.setDayPrice(v, api: api),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.nights_stay_outlined),
              title: Text(l.tariffNightPrice(
                  tariff.nightStartHour.toString().padLeft(2, '0'))),
              subtitle: Text(_priceLabel(tariff.nightPrice)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editPrice(
                context,
                l.tariffSetNightPrice,
                tariff.nightPrice,
                (v) => tariff.setNightPrice(v, api: api),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(l.tariffDayStart),
              subtitle: Text(
                  '${tariff.dayStartHour.toString().padLeft(2, '0')}:00'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editHour(
                context,
                l.tariffSetDayStart,
                tariff.dayStartHour,
                (v) => tariff.setDayStartHour(v, api: api),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: Text(l.tariffNightStart),
              subtitle: Text(
                  '${tariff.nightStartHour.toString().padLeft(2, '0')}:00'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editHour(
                context,
                l.tariffSetNightStart,
                tariff.nightStartHour,
                (v) => tariff.setNightStartHour(v, api: api),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    tariff.isDayZone ? Icons.wb_sunny : Icons.nights_stay,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${l.tariffCurrentPrice}: ${_priceLabel(tariff.activePrice)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceInputDialog extends StatefulWidget {
  final String title;
  final double initial;
  final String suffix;
  final void Function(double) onChanged;

  const _PriceInputDialog({
    required this.title,
    required this.initial,
    required this.suffix,
    required this.onChanged,
  });

  @override
  State<_PriceInputDialog> createState() => _PriceInputDialogState();
}

class _PriceInputDialogState extends State<_PriceInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.initial.toStringAsFixed(4));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: false),
        decoration: InputDecoration(
          suffixText: widget.suffix,
          border: const OutlineInputBorder(),
        ),
        onChanged: (v) {
          final parsed = double.tryParse(v.replaceAll(',', '.'));
          if (parsed != null) widget.onChanged(parsed);
        },
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.dialogCancel)),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.dialogSet)),
      ],
    );
  }
}

class _HourPickerDialog extends StatefulWidget {
  final String title;
  final int initial;
  final void Function(int) onChanged;

  const _HourPickerDialog({
    required this.title,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<_HourPickerDialog> createState() => _HourPickerDialogState();
}

class _HourPickerDialogState extends State<_HourPickerDialog> {
  late int _hour;

  @override
  void initState() {
    super.initState();
    _hour = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_hour.toString().padLeft(2, '0')}:00',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Slider(
            value: _hour.toDouble(),
            min: 0,
            max: 23,
            divisions: 23,
            label: '${_hour.toString().padLeft(2, '0')}:00',
            onChanged: (v) {
              setState(() => _hour = v.round());
              widget.onChanged(_hour);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.dialogCancel)),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.dialogSet)),
      ],
    );
  }
}
