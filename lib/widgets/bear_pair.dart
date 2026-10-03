import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/strings.dart';
import '../design/romantic_tokens.dart';
import '../models/bear_mood.dart';
import 'bear_art.dart';
import 'bear_rig.dart';

/// Small face shown in the corner bubble for each emotion.
const Map<BearEmotion, String> kBearMoodEmojis = <BearEmotion, String>{
  BearEmotion.sad: '🥺',
  BearEmotion.sulky: '😕',
  BearEmotion.calm: '😌',
  BearEmotion.happy: '😊',
  BearEmotion.loving: '💗',
  BearEmotion.angry: '😤',
};

/// Artwork for a mood when nothing is being tapped.
String bearArtFor(BearEmotion emotion) {
  switch (emotion) {
    case BearEmotion.loving:
      return BearArt.kiss;
    case BearEmotion.happy:
      return BearArt.hearts;
    case BearEmotion.calm:
      return BearArt.gift;
    case BearEmotion.angry:
      return BearArt.hearts;
    case BearEmotion.sulky:
      return BearArt.gift;
    case BearEmotion.sad:
      // Waiting for the other one.
      return BearArt.peek;
  }
}

/// Localised one-liner describing the mood between the two of you.
String bearCaption(Strings s, BearMoodReport mood) {
  if (!mood.paired) return s.t('bearSolo');
  final String key = switch (mood.pair) {
    BearEmotion.loving => 'bearMoodLoving',
    BearEmotion.happy => 'bearMoodHappy',
    BearEmotion.calm => 'bearMoodCalm',
    BearEmotion.sulky => 'bearMoodSulky',
    BearEmotion.sad => 'bearMoodSad',
    BearEmotion.angry => 'bearMoodAngry',
  };
  return s.t(key);
}

/// Milk & Mocha — the couple's own little stage.
///
/// The bears are not decoration and they do not burst: they walk their lane,
/// breathe, glance at each other, blink, and turn their heads on the neck. The
/// emotion comes from [BearMoodEngine] (real nudge history — nothing faked) and
/// changes how fast they walk and how they hold themselves. Tapping makes them
/// hop and "talk" back.
///
/// The characters themselves come from `assets/characters/` — see the README
/// there for the flat artwork and the optional cut-out parts (head, eyes, lids,
/// mouth, arm) that turn them into real puppets.
class BearPair extends StatefulWidget {
  const BearPair({
    super.key,
    required this.mood,
    required this.locale,
    this.artHeight = 156,
  });

  final BearMoodReport mood;
  final String locale;
  final double artHeight;

  @override
  State<BearPair> createState() => _BearPairState();
}

class _BearPairState extends State<BearPair> with TickerProviderStateMixin {
  /// The little hop when they are tapped.
  late final AnimationController _tap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  int _reaction = 0;
  bool _reacting = false;
  bool _speaking = false;
  Timer? _reactTimer;
  Timer? _speakTimer;

  @override
  void dispose() {
    _reactTimer?.cancel();
    _speakTimer?.cancel();
    _tap.dispose();
    super.dispose();
  }

  void _react() {
    _reactTimer?.cancel();
    _speakTimer?.cancel();
    setState(() {
      _reacting = true;
      _speaking = true;
      _reaction = (_reaction + 1) % BearArt.reactions.length;
    });
    _tap.forward(from: 0);
    _speakTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _speaking = false);
    });
    _reactTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _reacting = false);
    });
  }

  String get _art => _reacting
      ? BearArt.reactions[_reaction]
      : bearArtFor(widget.mood.pair);

  String get _bubbleEmoji => _reacting
      ? BearArt.reactionEmojis[_reaction]
      : kBearMoodEmojis[widget.mood.pair] ?? '💗';

  @override
  Widget build(BuildContext context) {
    final s = Strings(widget.locale);
    final mood = widget.mood;

    // Rebuild once the artwork probe has finished, so the characters swap
    // from the placeholder to the real artwork without waiting for a screen
    // change.
    return ValueListenableBuilder<bool>(
      valueListenable: BearArt.ready,
      builder: (BuildContext context, bool ready, Widget? child) =>
          _card(s, mood),
    );
  }

  Widget _card(Strings s, BearMoodReport mood) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: Rom.glass(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Milk & Mocha', style: Rom.title),
              Text(s.t('bearTapHint'), style: Rom.body),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: widget.artHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                // The hop is layered over both characters: the two walk
                // independently, but a tap lifts them together.
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _tap,
                    builder: (BuildContext context, Widget? child) =>
                        Transform.translate(
                      offset: Offset(0, -10 * math.sin(_tap.value * math.pi)),
                      child: child,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        // Mocha walks behind, with a different phase so the
                        // two never march in lockstep, and each looks at the
                        // other.
                        BearStage(
                          emotion: mood.pair,
                          art: _art,
                          who: 'mocha',
                          phaseOffset: 0.37,
                          partnerSide: -1,
                          laneStart: 0.30,
                          laneEnd: 0.84,
                          speaking: _speaking,
                          onTap: _react,
                          height: widget.artHeight,
                        ),
                        BearStage(
                          emotion: mood.pair,
                          art: _art,
                          who: 'milk',
                          phaseOffset: 0,
                          partnerSide: 1,
                          laneStart: 0.16,
                          laneEnd: 0.70,
                          speaking: _speaking,
                          onTap: _react,
                          height: widget.artHeight,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 6,
                  child: _Bubble(emoji: _bubbleEmoji, animation: _tap),
                ),
                if (!BearArt.layered)
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _ArtPlaceholder(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bearCaption(s, mood),
            textAlign: TextAlign.center,
            style: Rom.body,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _MoodChip(
                label: s.t('mineLabel'),
                emoji: kBearMoodEmojis[mood.mine] ?? '💗',
              ),
              const SizedBox(width: 8),
              _MoodChip(
                label: s.t('partnerDefault'),
                emoji: kBearMoodEmojis[mood.theirs] ?? '💗',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shown only while the artwork files are missing from `assets/characters/`.
/// Never used once the PNGs are added.
class _ArtPlaceholder extends StatelessWidget {
  const _ArtPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(Rom.rLg),
        ),
        child: const Text('🐻  🐻', style: TextStyle(fontSize: 40)),
      ),
    );
  }
}

/// Emoji that pops next to the bears.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.emoji, required this.animation});

  final String emoji;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final pop = math.sin(animation.value * math.pi);
        return Transform.scale(scale: 1 + 0.35 * pop, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Rom.rXl),
          boxShadow: Rom.softShadow(opacity: 0.1),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.label, required this.emoji});

  final String label;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Rom.blush,
        borderRadius: BorderRadius.circular(Rom.rXl),
        border: Border.all(color: Rom.rose.withValues(alpha: 0.18)),
      ),
      child: Text(
        '$emoji  $label',
        style: Rom.label.copyWith(color: Rom.ink, letterSpacing: 0.2),
      ),
    );
  }
}