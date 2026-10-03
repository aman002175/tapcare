import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapcare/models/nudge.dart';
import 'package:tapcare/screens/home_screen.dart';
import 'package:tapcare/screens/overlay_screen.dart';
import 'package:tapcare/screens/pair_screen.dart';
import 'package:tapcare/screens/send_nudge_screen.dart';
import 'package:tapcare/screens/settings_screen.dart';
import 'package:tapcare/screens/share_card_screen.dart';
import 'package:tapcare/screens/stats_screen.dart';
import 'package:tapcare/screens/widget_mode_screen.dart';
import 'package:tapcare/services/storage_service.dart';
import 'package:tapcare/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders every screen at phone size and fails on ANY Flutter error
/// (RenderFlex overflow, layout assertion, paint error) — this is what
/// catches "app is not responding / looks broken" regressions.
void main() {
  const phone = Size(360, 640);

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Map<String, Object> storage = const <String, Object>{},
  }) async {
    tester.view.physicalSize = phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{
      'profile_json':
          '{"id":"u1","display_name":"Aarav","avatar_emoji":"🐼","premium_unlocked":false,"created_at":"2026-01-01T00:00:00.000"}',
      'nudges_json':
          '[{"id":"n1","pair_id":"p1","sender_id":"u1","message":"पानी पी लो","theme":"peach","sound":"soft_chime","created_at":"2026-01-01T10:00:00.000","seen_at":null}]',
      ...storage,
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(
            LocalStorage(await SharedPreferences.getInstance()),
          ),
        ],
        child: MaterialApp(home: screen),
      ),
    );
    // a few frames so entrance animations and layout settle
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  final screens = <String, Widget>{
    'home': const HomeScreen(),
    'pair': const PairScreen(),
    'send': const SendNudgeScreen(),
    'settings': const SettingsScreen(),
    'stats': const StatsScreen(),
    'share_card': const ShareCardScreen(),
    'widget_mode': const WidgetModeScreen(),
  };

  screens.forEach((String name, Widget screen) {
    testWidgets('$name renders without layout errors',
        (WidgetTester tester) async {
      await pumpScreen(tester, screen);
      expect(tester.takeException(), isNull,
          reason: '$name produced a Flutter layout/paint error');
    });
  });

  testWidgets('overlay renders and "Seen" is tappable',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'profile_json':
          '{"id":"u1","display_name":"Aarav","avatar_emoji":"🐼","premium_unlocked":false,"created_at":"2026-01-01T00:00:00.000"}',
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(
            LocalStorage(await SharedPreferences.getInstance()),
          ),
        ],
        child: MaterialApp(
          home: OverlayScreen(
            nudge: Nudge(
              id: 'n_test',
              pairId: 'p1',
              senderId: 'demo_incoming',
              message: 'पानी पी लो',
              theme: 'peach',
              sound: 'soft_chime',
              createdAt: DateTime.now(),
            ),
            senderName: 'Meera',
            senderEmoji: '🦊',
            locale: 'hi',
            onSeen: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);

    expect(find.text('पानी पी लो'), findsOneWidget);
    await tester.tap(find.textContaining('देख लिया'));
    // the overlay plays a ~900ms celebration before popping
    await tester.pump(const Duration(milliseconds: 1200));
    expect(tester.takeException(), isNull);
  });
}
