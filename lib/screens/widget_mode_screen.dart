import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/strings.dart';
import '../design/romantic_tokens.dart';
import '../state/app_state.dart';
import '../widgets/heart_burst.dart';
import '../widgets/romance_motion.dart';
import '../widgets/romantic_scaffold.dart';
import 'overlay_screen.dart';

/// "Widget mode" — the in-app preview of the TapCare card plus instructions
/// for dropping the real, resizable widget onto the Android home screen.
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

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  /// Opens the overlay for a nudge that *arrived* from the partner.
  ///
  /// The old code took `state.nudges.first` regardless of who sent it, so
  /// tapping the mini card could mark one of **your own outgoing** nudges as
  /// seen — which both corrupted the acknowledgement score and made the love
  /// meter jump around for no reason. Only received nudges can be acknowledged.
  void _openLatestReceived(AppState state) {
    final myId = state.profile?.id ?? 'u_local';
    final received =
        state.nudges.where((n) => n.senderId != myId).toList(growable: false);
    if (received.isEmpty) {
      _toast(state.locale == 'hi'
          ? 'अभी कोई आने वाला नज़ नहीं 💛'
          : 'No incoming nudge yet 💛');
      return;
    }
    final unseen =
        received.where((n) => !n.seen).toList(growable: false);
    final n = unseen.isNotEmpty ? unseen.first : received.first;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OverlayScreen(
          nudge: n,
          senderName: state.pair?.partnerName ?? 'Buddy',
          senderEmoji: state.pair?.partnerEmoji ?? '💗',
          locale: state.locale,
          onSeen: () => ref.read(appProvider.notifier).markSeen(n.id),
        ),
      ),
    );
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
        appBar: romAppBar(title: s.t('widgetMode')),
        body: Stack(
          children: <Widget>[
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                children: <Widget>[
                  FadeSlideIn(child: Text(s.t('widgetModeHint'), style: Rom.body)),
                  const SizedBox(height: 20),

                  // ---- mini widget (small) ----
                  FadeSlideIn(
                    delayMs: 70,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _openLatestReceived(state),
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
                                        style: TextStyle(fontSize: 18)),
                                  ),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    '${state.profile?.displayName ?? ''} 💗 '
                                    '${state.pair?.partnerName ?? s.t('partnerDefault')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${stats.loveMeter.round()}%',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800),
                                ),
                              ],
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
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    flex: stats.mineFlex,
                                    child: Container(
                                        height: 10, color: Colors.white),
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    flex: stats.theirsFlex,
                                    child: Container(
                                        height: 10,
                                        color: Colors.white.withValues(alpha: 0.55)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${stats.mine} ${s.t('nudgesSent')} · '
                              '${stats.theirs} ${s.t('nudgesGot')}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11),
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
                        await ref
                            .read(appProvider.notifier)
                            .sendNudge(
                                message: 'मुझे याद आ रहा है 💛', emoji: '💌');
                        _burst.forward(from: 0);
                        _toast(s.t('sentToast'));
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ---- add the real widget to the home screen ----
                  FadeSlideIn(
                    delayMs: 220,
                    child: _AddWidgetCard(s: s, locale: state.locale),
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

/// Instructions + feature list for placing the real widget on the launcher.
class _AddWidgetCard extends StatelessWidget {
  const _AddWidgetCard({required this.s, required this.locale});

  final Strings s;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final steps = locale == 'hi'
        ? <String>[
            'होम स्क्रीन पर उँगली दबाकर रखो',
            'Widgets → TapCare चुनो',
            'कोने खींचकर आकार बदलो',
          ]
        : <String>[
            'Long-press an empty spot on the home screen',
            'Swipe to Widgets → tap TapCare',
            'Drag the corners to resize it',
          ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: Rom.dreamGradient,
        borderRadius: BorderRadius.circular(Rom.rXl),
        boxShadow: Rom.glowShadow(Rom.lilac),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text('🏠', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s.t('addHomeWidget'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            s.t('addHomeWidgetHint'),
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(Rom.rMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '✨ ${s.t('widgetPreview')}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  locale == 'hi'
                      ? 'जो कार्ड सामने वाला भेजेगा, वही आपकी होम स्क्रीन पर उछलकर दिखेगा — प्यार का प्रतिशत, स्ट्रीक, और उसका आख़िरी नज़।'
                      : 'Whatever card your partner sends appears right here on your home screen — love meter, streak and their latest nudge.',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
