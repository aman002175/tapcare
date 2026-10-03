import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/strings.dart';
import '../data/romance_content.dart';
import '../design/romantic_tokens.dart';
import '../models/nudge.dart';
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
                      const SizedBox(height: 4),
                      Text(stats.meterHint(state.locale), style: Rom.body),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Row(
                          children: <Widget>[
                            // Proportional to the real counts — the old code
                            // used `(stats.mine * 100).clamp(1, 100)`, which
                            // saturated at 100 for both sides and rendered
                            // every ratio as an identical 50/50 bar.
                            Expanded(
                              flex: stats.mineFlex,
                              child: Container(height: 14, color: Rom.coral),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              flex: stats.theirsFlex,
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

              // love-meter breakdown — shows exactly what the % is made of
              FadeSlideIn(
                delayMs: 180,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: Rom.glass(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('🔍 ${s.t('meterBreakdown')}', style: Rom.title),
                      const SizedBox(height: 4),
                      Text(
                        '${stats.loveMeter.round()}% · '
                        '${stats.mine} ${s.t('nudgesSent')} / '
                        '${stats.theirs} ${s.t('nudgesGot')}',
                        style: Rom.body,
                      ),
                      const SizedBox(height: 14),
                      _ScoreBar(
                        emoji: '💛',
                        label: s.t('careGiven'),
                        value: stats.careScore,
                        weight: '30%',
                      ),
                      _ScoreBar(
                        emoji: '⚖️',
                        label: s.t('balance'),
                        value: stats.balanceScore,
                        weight: '30%',
                      ),
                      _ScoreBar(
                        emoji: '🔥',
                        label: s.t('rhythm'),
                        value: stats.rhythmScore,
                        weight: '20%',
                      ),
                      _ScoreBar(
                        emoji: '👀',
                        label: s.t('acknowledged'),
                        value: stats.ackScore,
                        weight: '20%',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // weekly recap
              FadeSlideIn(
                delayMs: 220,
                child: _WeeklyRecap(state: state, s: s),
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

/// One row of the love-meter breakdown: label, weight and an animated bar.
class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.emoji,
    required this.label,
    required this.value,
    required this.weight,
  });

  final String emoji;
  final String label;
  final double value;
  final String weight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(label, style: Rom.body),
              const Spacer(),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Rom.rose,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                weight,
                style: const TextStyle(fontSize: 10.5, color: Rom.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double v, Widget? _) =>
                  LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: const Color(0xFFFFE4EC),
                valueColor: const AlwaysStoppedAnimation<Color>(Rom.rose),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "This week in love" — a rolling 7-day look at who showed up.
class _WeeklyRecap extends StatelessWidget {
  const _WeeklyRecap({required this.state, required this.s});

  final AppState state;
  final Strings s;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final mineByDay = <int, int>{};
    final theirsByDay = <int, int>{};

    for (final Nudge n in state.nudges) {
      final day = DateTime(
        n.createdAt.year,
        n.createdAt.month,
        n.createdAt.day,
      );
      final back = today.difference(day).inDays;
      if (back < 0 || back > 6) continue;
      final slot = 6 - back; // 0 = six days ago … 6 = today
      if (n.senderId == (state.profile?.id ?? '')) {
        mineByDay[slot] = (mineByDay[slot] ?? 0) + 1;
      } else {
        theirsByDay[slot] = (theirsByDay[slot] ?? 0) + 1;
      }
    }

    var weekMine = 0;
    var weekTheirs = 0;
    mineByDay.forEach((int _, int v) => weekMine += v);
    theirsByDay.forEach((int _, int v) => weekTheirs += v);

    const dayLetters = <String>['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final maxCount = <int>{
      ...mineByDay.values,
      ...theirsByDay.values,
      1,
    }.reduce((int a, int b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: Rom.glass(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('📅 ${s.t('weekInLove')}', style: Rom.title),
          const SizedBox(height: 4),
          Text(
            '$weekMine ${s.t('nudgesSent')} · $weekTheirs ${s.t('nudgesGot')}',
            style: Rom.body,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(7, (int slot) {
              final m = mineByDay[slot] ?? 0;
              final t = theirsByDay[slot] ?? 0;
              // slot 6 == today; align the letters to real weekdays.
              final letter = dayLetters[(today.subtract(Duration(days: 6 - slot)).weekday - 1) % 7];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        height: 84,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Expanded(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0,
                                  end: m == 0 ? 0 : 16 + 68 * (m / maxCount),
                                ),
                                duration: const Duration(milliseconds: 650),
                                curve: Curves.easeOutCubic,
                                builder: (BuildContext context, double v, _) =>
                                    Container(
                                  height: v,
                                  decoration: BoxDecoration(
                                    color: Rom.coral,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0,
                                  end: t == 0 ? 0 : 16 + 68 * (t / maxCount),
                                ),
                                duration: const Duration(milliseconds: 650),
                                curve: Curves.easeOutCubic,
                                builder: (BuildContext context, double v, _) =>
                                    Container(
                                  height: v,
                                  decoration: BoxDecoration(
                                    color: Rom.rose,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        letter,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Rom.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              _LegendDot(color: Rom.coral, label: s.t('mineLabel')),
              const SizedBox(width: 14),
              _LegendDot(color: Rom.rose, label: s.t('partnerDefault')),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11.5, color: Rom.inkSoft)),
      ],
    );
  }
}
