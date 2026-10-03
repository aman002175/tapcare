import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/strings.dart';
import '../design/romantic_tokens.dart';
import '../state/app_state.dart';
import '../widgets/heart_burst.dart';
import '../widgets/romance_motion.dart';

/// A pretty "our love" card you can copy and share anywhere (Instagram,
/// WhatsApp, story). Rendering stays local — no backend needed.
class ShareCardScreen extends ConsumerWidget {
  const ShareCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final s = Strings(state.locale);
    final stats = state.stats;
    final me = state.profile?.displayName ?? 'Me';
    final you = state.pair?.partnerName ?? s.t('partnerDefault');
    final accent = Rom.gradientByName(state.accentName);

    final cardText = state.locale == 'hi'
        ? '$me 💗 $you\n${stats.totalNudges} नज़ · ${stats.streakDays} दिन की लय\nबिना बोले, ख्याल 💛\n— TapCare'
        : '$me 💗 $you\n${stats.totalNudges} nudges · ${stats.streakDays}-day streak\nCare without words 💛\n— TapCare';

    return AnimatedMeshBackground(
      seed: (state.profile?.id.hashCode ?? 5) + 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(s.t('shareCard'), style: Rom.title),
          iconTheme: const IconThemeData(color: Rom.ink),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          gradient: accent,
                          borderRadius: BorderRadius.circular(Rom.rXl),
                          boxShadow: Rom.glowShadow(Rom.rose),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Heartbeat(
                              child: Text('💗',
                                  style: TextStyle(fontSize: 52)),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              '${state.profile?.avatarEmoji ?? '💗'}  $me',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            const Text('&',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 18)),
                            const SizedBox(height: 6),
                            Text(
                              '${state.pair?.partnerEmoji ?? '💛'}  $you',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 26),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  _Mini(
                                      '${stats.totalNudges}',
                                      state.locale == 'hi' ? 'नज़' : 'nudges'),
                                  _Mini('${stats.streakDays}',
                                      state.locale == 'hi' ? 'दिन' : 'days'),
                                  _Mini('${stats.loveMeter.round()}%',
                                      state.locale == 'hi' ? 'प्यार' : 'love'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              state.locale == 'hi'
                                  ? 'बिना बोले, ख्याल'
                                  : 'Care without words',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            const Text('TapCare',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ShineButton(
                  label: '📋 ${s.t('copiedToClipboard')}',
                  icon: Icons.copy_rounded,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: cardText));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(s.t('copiedToClipboard')),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  state.locale == 'hi'
                      ? 'कार्ड का टेक्स्ट कॉपी हो गया — कहीं भी शेयर करो।'
                      : 'Card text copied — paste it anywhere you like.',
                  textAlign: TextAlign.center,
                  style: Rom.body,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
