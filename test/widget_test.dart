import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapcare/main.dart';
import 'package:tapcare/screens/home_screen.dart';
import 'package:tapcare/screens/onboarding_screen.dart';
import 'package:tapcare/services/storage_service.dart';
import 'package:tapcare/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // The app runs perpetual ambient animations (mesh background, floating
  // hearts, heartbeat), so tests must use `pump` — `pumpAndSettle` would
  // never settle by design.
  testWidgets('First launch shows onboarding', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(
            LocalStorage(await SharedPreferences.getInstance()),
          ),
        ],
        child: const TapCareApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(TextButton), findsWidgets); // locale switch
  });

  testWidgets('Existing profile opens home', (WidgetTester tester) async {
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
        child: const TapCareApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Aarav'), findsOneWidget);
    // love-meter card (visible above the fold)
    expect(find.textContaining('💗'), findsWidgets);
    // streak chip with fire
    expect(find.textContaining('🔥'), findsWidgets);
  });
}
