import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pair_screen.dart';
import 'screens/send_nudge_screen.dart';
import 'screens/settings_screen.dart';
import 'services/storage_service.dart';
import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = LocalStorage(prefs);

  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
      ],
      child: const NudgeBuddyApp(),
    ),
  );
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
  ],
);

class NudgeBuddyApp extends ConsumerWidget {
  const NudgeBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final firstRun = state.profile == null;

    return MaterialApp.router(
      title: 'NudgeBuddy',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8A5B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF6EE),
        fontFamily: 'Roboto',
      ),
      // Onboarding before the router stack on first launch.
      builder: (BuildContext context, Widget? child) => firstRun
          ? const OnboardingScreen()
          : (child ?? const SizedBox.shrink()),
    );
  }
}
