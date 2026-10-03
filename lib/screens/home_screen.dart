import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/presets.dart';
import '../config/strings.dart';
import '../data/romance_content.dart';
import '../design/romantic_tokens.dart';
import '../models/bear_mood.dart';
import '../models/nudge.dart';
import '../state/app_state.dart';
import '../widgets/bear_pair.dart';
import '../widgets/heart_burst.dart';
import '../widgets/romance_motion.dart';
import 'overlay_screen.dart';
import 'pair_screen.dart';
import 'send_nudge_screen.dart';
import 'settings_screen.dart';
import 'share_card_screen.dart';
import 'stats_screen.dart';
import 'widget_mode_screen.dart';

/// Home — the daily ritual: see love meter, feel a quote, send a nudge.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  Future<void> _sendPreset(PresetNudge p, String locale) async {
    await ref
        .read(appProvider.notifier)
        .sendNudge(message: p.message(locale), emoji: p.emoji);
    _burst.forward(from: 0);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${p.emoji} ${Strings(locale).t('sentToast')}'),
        duration: const Duration(milliseconds: 1100),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _simulateIncoming(String locale) async {
    final p = kPresets[DateTime.now().millisecondsSinceEpoch % kPresets.length];
    final state = ref.read(appProvider);
    final nudge = await ref
        .read(appProvider.notifier)
        .receiveDemoNudge(message: p.message(locale), emoji: p.emoji);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OverlayScreen(
          nudge: nudge,
          senderName: state.pair?.partnerName ?? Strings(locale).t('buddyDefault'),
          senderEmoji: state.pair?.partnerEmoji ?? '💗',
          locale: locale,
          onSeen: () => ref.read(appProvider.notifier).markSeen(nudge.id),
        ),
      ),
    );
  }

  void _replay(Nudge n, String locale) {
    final state = ref.read(appProvider);
    final mine = n.senderId == (state.profile?.id ?? '');
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OverlayScreen(
          nudge: n,
          senderName: mine
              ? (state.profile?.displayName ?? '')
              : (state.pair?.partnerName ?? Strings(locale).t('buddyDefault')),
          senderEmoji: mine
              ? (state.profile?.avatarEmoji ?? '💗')
              : (state.pair?.partnerEmoji ?? '💗'),
          locale: locale,
          onSeen: () => ref.read(appProvider.notifier).markSeen(n.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    final s = Strings(state.locale);
    final profile = state.profile;
    if (profile == null) return const SizedBox.shrink();

    final pair = state.pair;
    final stats = state.stats;
    // Milk & Mocha: what the bears are feeling, read from the real nudge
    // history plus the personal mood check-in.
    final bears = BearMoodEngine.analyze(
      nudges: state.nudges,
      myId: profile.id,
      paired: pair != null,
      moods: state.moods,
    );
    final accent = Rom.gradientByName(state.accentName);
    final favPresets = kPresets
        .where((PresetNudge p) => state.favorites.contains(p.id))
        .toList();
    final restPresets = kPresets
        .where((PresetNudge p) => !state.favorites.contains(p.id))
        .toList();

    return AnimatedMeshBackground(
      seed: profile.id.hashCode,
      child: FloatingHearts(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: <Widget>[
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView(
                    // build a bit ahead of the viewport → smoother scrolling
                    cacheExtent: 600,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                    children: <Widget>[
                      // ---- header ----
                      FadeSlideIn(
                        child: Row(
                          children: <Widget>[
                            Heartbeat(
                              child: Container(
                                width: 52,
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: accent,
                                  shape: BoxShape.circle,
                                  boxShadow: Rom.glowShadow(Rom.rose),
                                ),
                                child: Text(profile.avatarEmoji,
                                    style: const TextStyle(fontSize: 26)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(profile.displayName,
                                      style: Rom.title),
                                  const SizedBox(height: 2),
                                  Text(
                                    pair == null
                                        ? s.t('unpaired')
                                        : '${pair.partnerEmoji} ${pair.partnerName} · ${stats.togetherLabel(state.locale)}',
                                    style: Rom.body,
                                  ),
                                ],
                              ),
                            ),
                            _RoundIcon(
                              icon: Icons.auto_awesome_rounded,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) => const StatsScreen()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _RoundIcon(
                              icon: Icons.tune_rounded,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) => const SettingsScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ---- love meter ----
                      FadeSlideIn(
                        delayMs: 60,
                        child: _LoveMeterCard(
                          meter: stats.loveMeter,
                          label: stats.meterLabel(state.locale),
                          streak: stats.streakDays,
                          streakLabel: s.t('streak'),
                          accent: accent,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ---- quote of the day ----
                      FadeSlideIn(
                        delayMs: 120,
                        child: _QuoteCard(
                          title: s.t('quoteOfDay'),
                          text: RomanceContent.quoteOfTheDay(state.locale),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ---- pair prompt / anniversary ----
                      if (pair == null)
                        FadeSlideIn(
                          delayMs: 180,
                          child: _PairPrompt(onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => const PairScreen()),
                            );
                          }),
                        )
                      else if (stats.daysToAnniversary != null)
                        FadeSlideIn(
                          delayMs: 180,
                          child: _AnniversaryCard(
                            days: stats.daysToAnniversary!,
                            label: s.t('daysToGo'),
                            accent: accent,
                          ),
                        ),
                      const SizedBox(height: 16),

                      // ---- mood check-in ----
                      FadeSlideIn(
                        delayMs: 220,
                        child: _MoodCheckIn(
                          title: s.t('moodCheckIn'),
                          moods: RomanceContent.moods,
                          saved: stats.lastMoodEmoji,
                          onPick: (String emoji) async {
                            await ref.read(appProvider.notifier).logMood(emoji);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(s.t('moodDone')),
                                duration: const Duration(milliseconds: 1000),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ---- quick actions ----
                      FadeSlideIn(
                        delayMs: 260,
                        child: Row(
                          children: <Widget>[
                            _MiniAction(
                              emoji: '✍️',
                              label: s.t('writeOwn'),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) => const SendNudgeScreen()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _MiniAction(
                              emoji: '📲',
                              label: s.t('simBtn'),
                              onTap: () => _simulateIncoming(state.locale),
                            ),
                            const SizedBox(width: 10),
                            _MiniAction(
                              emoji: '💞',
                              label: s.t('widgetMode'),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) => const WidgetModeScreen()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _MiniAction(
                              emoji: '📸',
                              label: s.t('shareCard'),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) => const ShareCardScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ---- favorites ----
                      if (favPresets.isNotEmpty) ...<Widget>[
                        _SectionHeader(
                          title: '⭐ ${s.t('favorites')}',
                          trailing: '',
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 92,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: favPresets.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (BuildContext c, int i) =>
                                _PresetChip(
                              preset: favPresets[i],
                              locale: state.locale,
                              accent: accent,
                              onTap: () =>
                                  _sendPreset(favPresets[i], state.locale),
                              onLongPress: () => ref
                                  .read(appProvider.notifier)
                                  .toggleFavorite(favPresets[i].id),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // ---- right now: care that fits this hour ----
                      _SectionHeader(
                        title: '${currentSlot().emoji()} ${s.t('rightNow')}',
                        trailing: s.t(currentSlot().key()),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 92,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: suggestedPresets().length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (BuildContext c, int i) {
                            final p = suggestedPresets()[i];
                            return _PresetChip(
                              preset: p,
                              locale: state.locale,
                              accent: accent,
                              onTap: () => _sendPreset(p, state.locale),
                              onLongPress: () => ref
                                  .read(appProvider.notifier)
                                  .toggleFavorite(p.id),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ---- all presets ----
                      _SectionHeader(title: s.t('sendSection'), trailing: '💗'),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: restPresets.map((PresetNudge p) {
                          return _PresetTile(
                            preset: p,
                            locale: state.locale,
                            accent: accent,
                            onTap: () => _sendPreset(p, state.locale),
                            onLongPress: () => ref
                                .read(appProvider.notifier)
                                .toggleFavorite(p.id),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // ---- care tip ----
                      FadeSlideIn(
                        delayMs: 300,
                        child: _TipCard(
                          title: s.t('careTip'),
                          text: RomanceContent.tipOfTheDay(state.locale),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ---- Milk & Mocha ----
                      // Sits below the fold on purpose: it is a reward for
                      // scrolling, not something that pushes the daily ritual
                      // down the page.
                      FadeSlideIn(
                        delayMs: 340,
                        child: BearPair(
                          mood: bears,
                          locale: state.locale,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ---- recent ----
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(s.t('recentTitle'), style: Rom.title),
                          Text('${state.nudges.length}/20',
                              style: Rom.label),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(s.t('longPressHint'),
                          style: const TextStyle(
                              fontSize: 11.5, color: Rom.inkSoft)),
                      const SizedBox(height: 12),
                      if (state.nudges.isEmpty)
                        _EmptyHistory(label: s.t('emptyRecent'))
                      else
                        ...state.nudges.take(6).map((Nudge n) {
                          final mine =
                              n.senderId == (profile.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _NudgeRow(
                              nudge: n,
                              mine: mine,
                              emoji: mine
                                  ? profile.avatarEmoji
                                  : (pair?.partnerEmoji ?? '💗'),
                              name: mine
                                  ? s.t('mineLabel')
                                  : (pair?.partnerName ??
                                      s.t('partnerDefault')),
                              time: _ago(n.createdAt),
                              seenLabel: s.t('seenLabel'),
                              unseenLabel: s.t('unseenLabel'),
                              onTap: () => _replay(n, state.locale),
                            ),
                          );
                        }),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const StatsScreen()),
                          ),
                          icon: const Icon(Icons.favorite_border,
                              color: Rom.rose, size: 18),
                          label: Text(s.t('yourStats'),
                              style: const TextStyle(
                                  color: Rom.rose,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // heart burst on send
              Positioned.fill(
                child: HeartBurst(controller: _burst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          shape: BoxShape.circle,
          boxShadow: Rom.softShadow(opacity: 0.1),
        ),
        child: Icon(icon, size: 19, color: Rom.rose),
      ),
    );
  }
}

class _LoveMeterCard extends StatelessWidget {
  const _LoveMeterCard({
    required this.meter,
    required this.label,
    required this.streak,
    required this.streakLabel,
    required this.accent,
  });

  final double meter;
  final String label;
  final int streak;
  final String streakLabel;
  final Gradient accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: Rom.glass(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text(
                  '💗 $label',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Rom.title,
                ),
              ),
              const SizedBox(width: 8),
              Text('${meter.round()}%',
                  style: Rom.title.copyWith(color: Rom.rose)),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: meter / 100),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: <Widget>[
                  Container(height: 12, color: const Color(0xFFF3E6EC)),
                  FractionallySizedBox(
                    widthFactor: v.clamp(0.02, 1.0),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Icon(Icons.local_fire_department_rounded,
                  color: Rom.coral, size: 18),
              const SizedBox(width: 6),
              Text('$streak $streakLabel 🔥',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Rom.ink)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: Rom.dreamGradient,
        borderRadius: BorderRadius.circular(Rom.rLg),
        boxShadow: Rom.glowShadow(Rom.lilac),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('"$title" ✨',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1)),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PairPrompt extends StatelessWidget {
  const _PairPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: Rom.warmGradient,
          borderRadius: BorderRadius.circular(Rom.rLg),
          boxShadow: Rom.glowShadow(Rom.coral),
        ),
        child: const Row(
          children: <Widget>[
            Text('🤝', style: TextStyle(fontSize: 26)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'अपना इंसान जोड़ो — कोड भेजो\nPair up and start caring',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _AnniversaryCard extends StatelessWidget {
  const _AnniversaryCard({
    required this.days,
    required this.label,
    required this.accent,
  });

  final int days;
  final String label;
  final Gradient accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: accent,
        borderRadius: BorderRadius.circular(Rom.rLg),
        boxShadow: Rom.glowShadow(Rom.rose),
      ),
      child: Row(
        children: <Widget>[
          const Text('💐', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('$days $label',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17)),
                const Text('Anniversary countdown',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodCheckIn extends StatelessWidget {
  const _MoodCheckIn({
    required this.title,
    required this.moods,
    required this.saved,
    required this.onPick,
  });

  final String title;
  final List<Map<String, String>> moods;
  final String? saved;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: Rom.glass(radius: Rom.rLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(title, style: Rom.title),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: moods.map((Map<String, String> m) {
              final active = m['emoji'] == saved;
              return GestureDetector(
                onTap: () => onPick(m['emoji']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFFFE3EC) : const Color(0xFFFDF4F7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active ? Rom.rose : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(m['emoji']!,
                      style: const TextStyle(fontSize: 21)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(18),
            boxShadow: Rom.softShadow(opacity: 0.08),
          ),
          child: Column(
            children: <Widget>[
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Rom.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(title, style: Rom.title),
          Text(trailing, style: const TextStyle(fontSize: 16)),
        ],
      );
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.locale,
    required this.accent,
    required this.onTap,
    required this.onLongPress,
  });

  final PresetNudge preset;
  final String locale;
  final Gradient accent;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: accent,
          borderRadius: BorderRadius.circular(Rom.rLg),
          boxShadow: Rom.glowShadow(Rom.rose),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(preset.emoji, style: const TextStyle(fontSize: 26)),
            Text(
              preset.message(locale),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.preset,
    required this.locale,
    required this.accent,
    required this.onTap,
    required this.onLongPress,
  });

  final PresetNudge preset;
  final String locale;
  final Gradient accent;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Rom.rose.withValues(alpha: 0.25)),
          boxShadow: Rom.softShadow(opacity: 0.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(preset.emoji, style: const TextStyle(fontSize: 22)),
            Text(
              preset.message(locale),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                height: 1.2,
                color: Rom.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(Rom.rLg),
        border: Border.all(color: Rom.mint.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('💡 $title',
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Rom.mint)),
          const SizedBox(height: 8),
          Text(text,
              style: const TextStyle(
                  fontSize: 14, height: 1.45, color: Rom.ink)),
        ],
      ),
    );
  }
}

class _NudgeRow extends StatelessWidget {
  const _NudgeRow({
    required this.nudge,
    required this.mine,
    required this.emoji,
    required this.name,
    required this.time,
    required this.seenLabel,
    required this.unseenLabel,
    required this.onTap,
  });

  final Nudge nudge;
  final bool mine;
  final String emoji;
  final String name;
  final String time;
  final String seenLabel;
  final String unseenLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          boxShadow: Rom.softShadow(opacity: 0.07),
        ),
        child: Row(
          children: <Widget>[
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    nudge.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: Rom.ink),
                  ),
                  const SizedBox(height: 3),
                  Text('$name · $time', style: Rom.body),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: nudge.seen
                    ? const Color(0xFFE6F7F0)
                    : const Color(0xFFFFE3EC),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                nudge.seen ? '✓ $seenLabel' : '● $unseenLabel',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: nudge.seen ? Rom.mint : Rom.rose,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      alignment: Alignment.center,
      decoration: Rom.glass(radius: Rom.rLg),
      child: Column(
        children: <Widget>[
          const Text('💌', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 10),
          Text(label,
              textAlign: TextAlign.center, style: Rom.body),
        ],
      ),
    );
  }
}
