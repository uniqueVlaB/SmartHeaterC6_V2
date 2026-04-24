import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/stats_data.dart';
import '../providers/heater_provider.dart';
import '../widgets/info_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HeaterProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HeaterProvider>();
    final stats = provider.stats;
    final l = AppLocalizations.of(context)!;

    if (stats == null) {
      if (provider.statsLoadFailed) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                l.connectionError,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => provider.loadStats(),
                icon: const Icon(Icons.refresh),
                label: Text(l.retry),
              ),
            ],
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadStats(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoCard(
            title: l.statsTodayTitle(stats.todayDate),
            icon: Icons.today,
            children: [
              InfoRow(
                label: l.statsHeatingTime,
                value: stats.todayHeatingFormatted,
              ),
              InfoRow(
                label: l.statsSessions,
                value: stats.todaySessions.toString(),
              ),
              InfoRow(
                label: l.statsEnergy,
                value: '${stats.todayEnergyKWh.toStringAsFixed(3)} kWh',
              ),
              InfoRow(
                label: l.statsCost,
                value:
                    '${stats.todayCost.toStringAsFixed(2)} ${l.currencySymbol}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: l.statsMonthTitle,
            icon: Icons.calendar_month,
            children: [
              InfoRow(
                label: l.statsEnergy,
                value: '${stats.monthEnergyKWh.toStringAsFixed(3)} kWh',
              ),
              InfoRow(
                label: l.statsCost,
                value:
                    '${stats.monthCost.toStringAsFixed(2)} ${l.currencySymbol}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: l.statsYearTitle,
            icon: Icons.calendar_today,
            children: [
              InfoRow(
                label: l.statsEnergy,
                value: '${stats.yearEnergyKWh.toStringAsFixed(3)} kWh',
              ),
              InfoRow(
                label: l.statsCost,
                value:
                    '${stats.yearCost.toStringAsFixed(2)} ${l.currencySymbol}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: l.statsAllTimeTitle,
            icon: Icons.history,
            children: [
              InfoRow(
                label: l.statsHeatingTime,
                value: stats.allTimeHeatingFormatted,
              ),
              InfoRow(
                label: l.statsSessions,
                value: stats.allTimeSessions.toString(),
              ),
              InfoRow(
                label: l.statsEnergy,
                value: '${stats.allTimeEnergyKWh.toStringAsFixed(3)} kWh',
              ),
              InfoRow(
                label: l.statsCost,
                value:
                    '${stats.allTimeCost.toStringAsFixed(2)} ${l.currencySymbol}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attach_money, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l.statsPrice,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${stats.pricePerKWh.toStringAsFixed(4)} ${l.currencyPerKWh}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showSetPriceDialog(
                          context,
                          provider,
                          stats.pricePerKWh,
                        ),
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(l.statsSetPrice),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _confirmResetStats(context, provider),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: Text(l.statsResetStats),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SessionsLogCard(sessions: stats.log, l: l),
        ],
      ),
    );
  }

  Future<void> _showSetPriceDialog(
    BuildContext context,
    HeaterProvider provider,
    double current,
  ) async {
    double value = current;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          _PriceDialog(initial: current, onChanged: (v) => value = v),
    );
    if (confirmed == true && context.mounted) {
      try {
        await provider.setPrice(value);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  Future<void> _confirmResetStats(
    BuildContext context,
    HeaterProvider provider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.statsResetConfirmTitle),
        content: Text(AppLocalizations.of(ctx)!.statsResetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx)!.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(ctx)!.dialogConfirm),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        await provider.resetStats();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }
}

class _PriceDialog extends StatefulWidget {
  final double initial;
  final void Function(double) onChanged;

  const _PriceDialog({required this.initial, required this.onChanged});

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initial.toStringAsFixed(4),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.statsElectricityPriceLabel),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: false,
        ),
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.statsElectricityPriceLabel,
          suffixText: AppLocalizations.of(context)!.statsElectricityPriceSuffix,
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
          child: Text(AppLocalizations.of(context)!.dialogCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(AppLocalizations.of(context)!.dialogSet),
        ),
      ],
    );
  }
}

// ── Sessions Log Card ─────────────────────────────────────────────────────────

class _SessionsLogCard extends StatelessWidget {
  final List<HeatingSessionEntry> sessions;
  final AppLocalizations l;

  const _SessionsLogCard({required this.sessions, required this.l});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  l.statsSessionsLog,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                l.statsNoSessions,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            )
          else
            ...sessions.asMap().entries.map((entry) {
              final idx = entry.key;
              final s = entry.value;
              final startLabel = s.startFormatted ?? l.statsSessionUnknown;
              final tempStr = (s.startTemp != null && s.endTemp != null)
                  ? '  ${s.startTemp!.toStringAsFixed(1)}→${s.endTemp!.toStringAsFixed(1)}°C'
                  : '';
              return Column(
                children: [
                  if (idx > 0) const Divider(height: 1, indent: 16),
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.local_fire_department_outlined,
                      size: 20,
                    ),
                    title: Text(
                      startLabel,
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      '${s.durationFormatted}$tempStr  ·  ${s.energyKWh.toStringAsFixed(3)} kWh',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      '${s.cost.toStringAsFixed(3)} ${l.currencySymbol}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
