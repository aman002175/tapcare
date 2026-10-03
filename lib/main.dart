import 'dart:async';

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

  /// How long the branded splash stays up at minimum.
  ///
  /// Storage usually resolves in a few milliseconds, so without this the
  /// splash appeared for a single frame and looked like nothing at all —
  /// the only thing the user ever saw was the Android system splash.
  static const Duration minSplash = Duration(milliseconds: 1500);

  bool _minElapsed = false;

  /// Held so it can be cancelled on dispose. A bare `Future.delayed` cannot
  /// be cancelled and keeps ticking after the widget is gone, which both
  /// leaks and trips "A Timer is still pending even after the widget tree
  /// was disposed" in widget tests.
  Timer? _minSplashTimer;

  static Future<LocalStorage> _openStorage() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorage(prefs);
  }

  @override
  void initState() {
    super.initState();
    _minSplashTimer = Timer(minSplash, () {
      if (mounted) setState(() => _minElapsed = true);
    });
  }

  @override
  void dispose() {
    _minSplashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LocalStorage>(
      future: _storage,
      builder: (BuildContext context, AsyncSnapshot<LocalStorage> snap) {
        final storage = snap.data;
        final ready = storage != null && _minElapsed;
        // The splash renders before any MaterialApp exists, so it has no
        // Directionality ancestor and Scaffold/Text would throw
        // "No Directionality widget found". MaterialApp supplies its own
        // Directionality once it takes over, so only the splash needs this.
        return Directionality(
          textDirection: TextDirection.ltr,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 550),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: ready
                ? ProviderScope(
                    key: const ValueKey<String>('app'),
                    overrides: [storageProvider.overrideWithValue(storage)],
                    child: const TapCareApp(),
                  )
                : const SplashScreen(key: ValueKey<String>('splash')),
          ),
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
      //
      // The swap used to be instantaneous, so filling in the name made the
      // onboarding page blink out. AnimatedSwitcher cross-fades: onboarding
      // fades out while the router stack fades in. The two children carry
      // different keys (onboarding has one, the Navigator does not), which is
      // what makes the switcher treat them as different children.
      builder: (BuildContext context, Widget? child) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 520),
        reverseDuration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget animated, Animation<double> anim) =>
            FadeTransition(opacity: anim, child: animated),
        child: firstRun
            ? const OnboardingScreen(key: ValueKey<String>('onboarding'))
            : (child ?? const SizedBox.shrink()),
      ),
    );
  }
}
