import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/strings.dart';
import '../data/romance_content.dart';
import '../design/romantic_tokens.dart';
import '../state/app_state.dart';
import '../widgets/romance_motion.dart';

/// "Your story" — everything your love looks like so far.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final s = Strings(state.locale);
    final stats = state.stats;
    final accent = Rom.gradientByName(state.accentName);

    return AnimatedMeshBackground(
      seed: (state.profile?.id.hashCode ?? 3) + 1,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(s.t('yourStats'), style: Rom.title),
          iconTheme: const IconThemeData(color: Rom.ink),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: <Widget>[
              // hero card
              FadeSlideIn(
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: accent,
                    borderRadius: BorderRadius.circular(Rom.rXl),
                    boxShadow: Rom.glowShadow(Rom.rose),
                  ),
                  child: Column(
                    children: <Widget>[
                      const Heartbeat(
                        child: Text('💗', style: TextStyle(fontSize: 46)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stats.togetherLabel(state.locale),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(stats.meterLabel(state.locale),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (stats.loveMeter / 100).clamp(0.02, 1.0),
                          minHeight: 10,
                          backgroundColor: Colors.white24,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // stat grid
              FadeSlideIn(
                delayMs: 80,
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.12,
                  children: <Widget>[
                    _StatTile(
                      emoji: '💌',
                      value: '${stats.totalNudges}',
                      label: s.t('recentTitle'),
                    ),
                    _StatTile(
                      emoji: '🔥',
                      value: '${stats.streakDays}',
                      label: '${s.t('streak')} · ${s.t('dayStreak')}',
                    ),
                    _StatTile(
                      emoji: '💛',
                      value: '${stats.mine}',
                      label: s.t('nudgesSent'),
                    ),
                    _StatTile(
                      emoji: '💗',
                      value: '${stats.theirs}',
                      label: s.t('nudgesGot'),
                    ),
                    _StatTile(
                      emoji: '👀',
                      value: '${stats.seenCount}',
                      label: s.t('seenOnes'),
                    ),
                    _StatTile(
                      emoji: state.stats.lastMoodEmoji ?? '🙂',
                      value: '${state.moods.length}',
                      label: s.t('moodCheckIn'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // balance
              FadeSlideIn(
                delayMs: 140,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: Rom.glass(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('⚖️ ${s.t('loveMeter')}', style: Rom.title),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              flex: (stats.mine * 100).clamp(1, 100),
                              child: Container(height: 14, color: Rom.coral),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              flex: (stats.theirs * 100).clamp(1, 100),
                              child: Container(height: 14, color: Rom.rose),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text('🧡 ${state.profile?.displayName ?? ''}',
                              style: Rom.body),
                          Text(
                            '💗 ${state.pair?.partnerName ?? s.t('partnerDefault')}',
                            style: Rom.body,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // quote + tips
              FadeSlideIn(
                delayMs: 200,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: Rom.calmGradient,
                    borderRadius: BorderRadius.circular(Rom.rLg),
                    boxShadow: Rom.glowShadow(Rom.mint),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('💡 CARE GUIDE',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1)),
                      const SizedBox(height: 10),
                      for (final Map<String, String> tip
                          in RomanceContent.careTips.take(4))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            tip[state.locale] ?? tip['en']!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                height: 1.4,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // celebrations
              FadeSlideIn(
                delayMs: 260,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: Rom.glass(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('🎉 ${s.t('premium') == '' ? '' : 'Milestones'}',
                          style: Rom.title),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: RomanceContent.celebrations.map((
                          Map<String, String> c,
                        ) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE9F0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              c[state.locale] ?? c['en']!,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Rom.rose),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: Rom.glass(radius: Rom.rLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(emoji, style: const TextStyle(fontSize: 20)),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Rom.ink),
            ),
          ),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 10.5,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Rom.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}
