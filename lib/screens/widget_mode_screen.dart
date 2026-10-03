import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/strings.dart';
import '../design/romantic_tokens.dart';
import '../state/app_state.dart';
import '../widgets/heart_burst.dart';
import '../widgets/romance_motion.dart';
import 'overlay_screen.dart';

/// "Widget mode" — a live mini-card that lives on your phone screen,
/// the closest thing to a real home-screen widget without a native build.
/// It always has your couple's love meter and a one-tap nudge button.
class WidgetModeScreen extends ConsumerStatefulWidget {
  const WidgetModeScreen({super.key});

  @override
  ConsumerState<WidgetModeScreen> createState() => _WidgetModeScreenState();
}

class _WidgetModeScreenState extends ConsumerState<WidgetModeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  static const List<Map<String, String>> _coupleQuotes =
      <Map<String, String>>[
    <String, String>{
      'hi': 'प्यार छोटी बातों में है — बस याद रखो।',
      'en': 'Love lives in small things — just remember.',
    },
    <String, String>{
      'hi': 'आज का प्यार: एक नज़, बस इतना ही।',
      'en': "Today's love: one nudge, that's all.",
    },
    <String, String>{
      'hi': 'देखभाल करना ही सबसे बड़ा इश्क़ है।',
      'en': 'Taking care of someone is the biggest "I love you".',
    },
    <String, String>{
      'hi': 'तुम्हारा इंसान तुमसे बहुत प्यार करता है।',
      'en': 'Your person loves you a lot today.',
    },
  ];

  String _quote(String locale) {
    final d = DateTime.now();
    final i = (d.day + d.month) % _coupleQuotes.length;
    return _coupleQuotes[i][locale] ?? _coupleQuotes[i]['en']!;
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    final s = Strings(state.locale);
    final stats = state.stats;
    final accent = Rom.gradientByName(state.accentName);

    return AnimatedMeshBackground(
      seed: (state.profile?.id.hashCode ?? 7) + 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(s.t('widgetMode'), style: Rom.title),
          iconTheme: const IconThemeData(color: Rom.ink),
        ),
        body: Stack(
          children: <Widget>[
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                children: <Widget>[
                  FadeSlideIn(
                    child: Text(s.t('widgetModeHint'), style: Rom.body),
                  ),
                  const SizedBox(height: 20),

                  // ---- mini widget (small) ----
                  FadeSlideIn(
                    delayMs: 70,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          if (state.nudges.isNotEmpty) {
                            final n = state.nudges.first;
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => OverlayScreen(
                                  nudge: n,
                                  senderName: n.senderId ==
                                          (state.profile?.id ?? '')
                                      ? (state.profile?.displayName ?? '')
                                      : (state.pair?.partnerName ??
                                          s.t('buddyDefault')),
                                  senderEmoji: n.senderId ==
                                          (state.profile?.id ?? '')
                                      ? (state.profile?.avatarEmoji ?? '💗')
                                      : (state.pair?.partnerEmoji ?? '💗'),
                                  locale: state.locale,
                                  onSeen: () => ref
                                      .read(appProvider.notifier)
                                      .markSeen(n.id),
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 190,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: accent,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: Rom.glowShadow(Rom.rose),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Heartbeat(
                                      child: Text('💗',
                                          style: TextStyle(fontSize: 18))),
                                  const Spacer(),
                                  Text(
                                    '${stats.loveMeter.round()}%',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _quote(state.locale),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    height: 1.3,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${stats.streakDays} 🔥',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ---- large widget ----
                  FadeSlideIn(
                    delayMs: 130,
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: accent,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: Rom.glowShadow(Rom.rose),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '${state.profile?.displayName ?? ''} 💗 ${state.pair?.partnerName ?? s.t('partnerDefault')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _quote(state.locale),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        height: 1.35,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              children: <Widget>[
                                Text('${stats.loveMeter.round()}%',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800)),
                                const Text('love',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // ---- one-tap nudge ----
                  FadeSlideIn(
                    delayMs: 190,
                    child: ShineButton(
                      label: '💌 ${s.t('sendQuick')}',
                      onPressed: () async {
                        final n = state.nudges.isEmpty ? null : state.nudges.first;
                        await ref
                            .read(appProvider.notifier)
                            .sendNudge(message: 'मुझे याद आ रहा है 💛', emoji: '💌');
                        _burst.forward(from: 0);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(s.t('sentToast')),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        if (n != null) {
                          // no-op: keep last nudge context
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  FadeSlideIn(
                    delayMs: 250,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: Rom.glass(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('💡 ${s.t('careTip')}', style: Rom.title),
                          const SizedBox(height: 8),
                          Text(_quote(state.locale), style: Rom.body),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(child: HeartBurst(controller: _burst)),
          ],
        ),
      ),
    );
  }
}
