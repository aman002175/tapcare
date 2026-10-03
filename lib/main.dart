import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pair_screen.dart';
import 'screens/send_nudge_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/widget_mode_screen.dart';
import 'services/home_widget_service.dart';
import 'services/storage_service.dart';
import 'state/app_state.dart';
import 'widgets/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // NOTE: storage is intentionally *not* awaited here. Awaiting
  // SharedPreferences before runApp() left the window showing the bare
  // NormalTheme background (white) until the first Flutter frame — the
  // "white screen on open". Boot into the splash instead and load in the
  // background.
  runApp(const TapCareBootstrap());
}

/// Loads storage behind the splash, then hands off to the real app.
class TapCareBootstrap extends StatefulWidget {
  const TapCareBootstrap({super.key});

  @override
  State<TapCareBootstrap> createState() => _TapCareBootstrapState();
}

class _TapCareBootstrapState extends State<TapCareBootstrap> {
  late final Future<LocalStorage> _storage = _openStorage();

  static Future<LocalStorage> _openStorage() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorage(prefs);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LocalStorage>(
      future: _storage,
      builder: (BuildContext context, AsyncSnapshot<LocalStorage> snap) {
        final storage = snap.data;
        if (storage == null) return const SplashScreen();
        return ProviderScope(
          overrides: [storageProvider.overrideWithValue(storage)],
          child: const TapCareApp(),
        );
      },
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) =>
          const HomeScreen(),
    ),
    GoRoute(
      path: '/pair',
      builder: (BuildContext context, GoRouterState state) =>
          const PairScreen(),
    ),
    GoRoute(
      path: '/send',
      builder: (BuildContext context, GoRouterState state) =>
          const SendNudgeScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) =>
          const SettingsScreen(),
    ),
    GoRoute(
      path: '/stats',
      builder: (BuildContext context, GoRouterState state) =>
          const StatsScreen(),
    ),
    GoRoute(
      path: '/widget',
      builder: (BuildContext context, GoRouterState state) =>
          const WidgetModeScreen(),
    ),
  ],
);

class TapCareApp extends ConsumerWidget {
  const TapCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final firstRun = state.profile == null;

    // Keep the home-screen widget in sync with the latest care data. Done in
    // a listener (not in build) so it runs once per real state change rather
    // than on every unrelated rebuild.
    ref.listen<AppState>(appProvider, (AppState? _, AppState next) {
      HomeWidgetService.syncFrom(next);
    }, fireImmediately: true);

    return MaterialApp.router(
      title: 'TapCare',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8A5B),
          brightness: Brightness.light,
        ),
        // Must match the native window background, otherwise Android shows a
        // white frame between the launch theme and the first Flutter frame.
        scaffoldBackgroundColor: const Color(0xFFFFF4F0),
        fontFamily: 'Roboto',
      ),
      // Onboarding before the router stack on first launch.
      builder: (BuildContext context, Widget? child) => firstRun
          ? const OnboardingScreen()
          : (child ?? const SizedBox.shrink()),
    );
  }
}
