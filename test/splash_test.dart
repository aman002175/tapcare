import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcare/main.dart';
import 'package:tapcare/widgets/splash_screen.dart';

/// Regression test for the launch crash:
///
/// `No Directionality widget found. Scaffold widgets require a Directionality
/// widget ancestor.`
///
/// The splash renders from [TapCareBootstrap] *before* any MaterialApp exists,
/// so it must supply its own Directionality. This pumps the real bootstrap
/// (not SplashScreen in isolation) so the whole pre-MaterialApp path is
/// exercised.
void main() {
  // The splash runs perpetual animations (mesh background, floating hearts,
  // glow ring, bouncing dots), so these tests must use `pump` —
  // `pumpAndSettle` would never settle by design.
  testWidgets('TapCare boots through the splash without throwing',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const TapCareBootstrap());
    await tester.pump();

    // Nothing threw — this is the assertion that matters.
    expect(tester.takeException(), isNull);
    expect(find.byType(SplashScreen), findsOneWidget);
  });

  testWidgets('Splash shows the wordmark and tagline',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const TapCareBootstrap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));

    expect(tester.takeException(), isNull);
    expect(find.text('TapCare'), findsOneWidget);
    expect(find.text('बिना बोले, ख्याल 💛'), findsOneWidget);
    expect(find.text('Care without words'), findsOneWidget);
  });

  testWidgets('A returning user is handed off to the real app',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'profile_json':
          '{"id":"u1","display_name":"Aarav","avatar_emoji":"🐼","premium_unlocked":false,"created_at":"2026-01-01T00:00:00.000"}',
    });

    await tester.pumpWidget(const TapCareBootstrap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    // let the AnimatedSwitcher finish its 550ms fade
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.byType(TapCareApp), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });
}