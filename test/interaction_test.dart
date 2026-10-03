import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapcare/screens/home_screen.dart';
import 'package:tapcare/screens/settings_screen.dart';
import 'package:tapcare/services/storage_service.dart';
import 'package:tapcare/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guards the "nothing responds / won't scroll" class of bug: ambient
/// decoration must never swallow input.
void main() {
  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

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
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    for (int i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  testWidgets('tapping a mood registers (input reaches the app)',
      (WidgetTester tester) async {
    await pumpHome(tester);

    expect(find.text('🥰'), findsOneWidget);
    await tester.tap(find.text('🥰'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('मूड सेव'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('header button opens settings', (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.tap(find.byIcon(Icons.tune_rounded));
    for (int i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sending a preset nudge works', (WidgetTester tester) async {
    await pumpHome(tester);

    // scroll the preset grid into view, then tap the first preset
    await tester.drag(find.byType(ListView).first, const Offset(0, -420));
    await tester.pump(const Duration(milliseconds: 400));

    final preset = find.text('पानी पी लो').first;
    expect(preset, findsOneWidget);
    await tester.tap(preset);
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('नज़ भेजा गया'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home list actually scrolls', (WidgetTester tester) async {
    await pumpHome(tester);

    // care-tip card sits far below the fold and is built lazily
    expect(find.textContaining('आज की देखभाल'), findsNothing);

    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    for (int i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.textContaining('आज की देखभाल'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}