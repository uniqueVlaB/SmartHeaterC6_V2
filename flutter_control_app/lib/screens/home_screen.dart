import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/heater_provider.dart'
    show HeaterProvider, DeviceConnectionState;
import 'dashboard_screen.dart';
import 'schedule_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _screens = [
    DashboardScreen(),
    ScheduleScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HeaterProvider>();
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.local_fire_department),
            const SizedBox(width: 8),
            Text(l.appTitle),
            const Spacer(),
            _ConnectionBadge(state: provider.connectionState),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi_off),
            tooltip: l.disconnect,
            onPressed: () => provider.disconnect(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (provider.connectionState == DeviceConnectionState.error &&
              provider.lastError != null)
            MaterialBanner(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              content: Text(
                provider.lastError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              leading: Icon(
                Icons.wifi_off,
                color: Theme.of(context).colorScheme.onErrorContainer,
                size: 20,
              ),
              actions: [
                TextButton(
                  onPressed: () => provider.connect(provider.deviceUrl),
                  child: Text(
                    l.retry,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, overflow: TextOverflow.ellipsis),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          onDestinationSelected: (i) {
            setState(() => _currentIndex = i);
            provider.setPollingActive(i == 0); // only poll when Dashboard is active
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: l.navDashboard,
            ),
            NavigationDestination(
              icon: const Icon(Icons.schedule_outlined),
              selectedIcon: const Icon(Icons.schedule),
              label: l.navSchedule,
            ),
            NavigationDestination(
              icon: const Icon(Icons.bar_chart_outlined),
              selectedIcon: const Icon(Icons.bar_chart),
              label: l.navStats,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  final DeviceConnectionState state;

  const _ConnectionBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (state) {
      DeviceConnectionState.connected => (
        Colors.green,
        AppLocalizations.of(context)!.connectionOnline,
      ),
      DeviceConnectionState.connecting || DeviceConnectionState.initializing =>
        (Colors.orange, AppLocalizations.of(context)!.connectionConnecting),
      DeviceConnectionState.error => (
        Colors.red,
        AppLocalizations.of(context)!.connectionError,
      ),
      DeviceConnectionState.disconnected => (
        Colors.grey,
        AppLocalizations.of(context)!.connectionOffline,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
