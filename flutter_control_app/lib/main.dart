import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'notifications/notification_service.dart';
import 'providers/heater_provider.dart' show HeaterProvider, DeviceConnectionState;
import 'providers/locale_provider.dart';
import 'providers/tariff_provider.dart';
import 'screens/connect_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()..init()),
        ChangeNotifierProvider(create: (_) => TariffProvider()..init()),
        ChangeNotifierProvider(create: (ctx) {
          final hp = HeaterProvider()..init();
          hp.attachTariff(ctx.read<TariffProvider>());
          return hp;
        }),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorSchemeSeed: Colors.deepOrange,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.deepOrange,
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          home: const _RootNavigator(),
        ),
      ),
    );
  }
}

class _RootNavigator extends StatelessWidget {
  const _RootNavigator();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HeaterProvider>();
    final state = provider.connectionState;

    // Show a neutral splash while loading prefs / attempting auto-connect.
    if (state == DeviceConnectionState.initializing) {
      return const _SplashScreen();
    }

    // Stay on HomeScreen during transient errors — only go back when
    // explicitly disconnected or the initial connect never succeeded.
    if (state == DeviceConnectionState.connected ||
        state == DeviceConnectionState.error) {
      return const HomeScreen();
    }
    return const ConnectScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
