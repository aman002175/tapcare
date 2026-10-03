import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcare/main.dart';
import 'package:tapcare/widgets/splash_screen.dart';

/// Regression tests for the launch crash:
///
/// `No Directionality widget found. Scaffold widgets require a Directionality
/// widget ancestor.`
///
/// The splash renders from [TapCareBootstrap] *before* any MaterialApp exists,
/// so it must supply its own Directionality. These pump the real bootstrap
/// (not SplashScreen in isolation) so the whole pre-MaterialApp path runs.
///
/// The splash runs perpetual animations (mesh background, floating hearts,
/// glow ring, bouncing dots), so these tests must use `pump` —
/// `pumpAndSettle` would never settle by design.
void main() {
  /// Fails with the real error attached, instead of a bare null mismatch.
  void expectNoException(WidgetTester tester) {
    final Object? err = tester.takeException();
    expect(err, isNull, reason: 'launch threw: $err');
  }

  testWidgets('TapCare boots through the splash without throwing',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const TapCareBootstrap());
    await tester.pump();

    expectNoException(tester);
    expect(find.byType(SplashScreen), findsOneWidget);
  });

  testWidgets('Splash shows the wordmark and tagline',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const TapCareBootstrap());
    // Mid-intro: the splash is still up and the staged animation is running,
    // but the 1500ms handoff timer has not fired yet.
    await tester.pump(const Duration(milliseconds: 900));

    expectNoException(tester);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('TapCare'), findsOneWidget);
    expect(find.text('बिना बोले, ख्याल 💛'), findsOneWidget);
    expect(find.text('Care without words'), findsOneWidget);
  });

  testWidgets('The splash hands off to the real app and cleans up',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'profile_json':
          '{"id":"u1","display_name":"Aarav","avatar_emoji":"🐼","premium_unlocked":false,"created_at":"2026-01-01T00:00:00.000"}',
    });

    await tester.pumpWidget(const TapCareBootstrap());
    // Cross the 1500ms minimum-splash timer, then the 550ms switcher fade.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 700));

    expectNoException(tester);
    expect(find.byType(TapCareApp), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });
}