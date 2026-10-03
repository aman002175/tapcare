import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/strings.dart';
import '../design/romantic_tokens.dart';
import '../models/bear_mood.dart';
import 'heart_burst.dart';

/// Where the Milk & Mocha artwork lives.
///
/// The four illustrations are **not** re-drawn with Flutter shapes on purpose:
/// hand-built bears look rough, and the point of these characters is that they
/// look exactly like the artwork the user designed. The app therefore renders
/// the real PNG the moment the files are present in `assets/characters/` (and
/// declared in `pubspec.yaml`), and a soft placeholder until then — see
/// `assets/characters/README.md`.
class BearArt {
  BearArt._();

  /// The couple hugging/kissing — used for the "loving" mood and the kiss
  /// reaction.
  static const String kiss = 'assets/characters/milk_mocha_kiss.png';

  /// The couple under a pile of hearts — happy / celebration.
  static const String hearts = 'assets/characters/milk_mocha_hearts.png';

  /// One bear offering a heart to the other — the gift reaction.
  static const String gift = 'assets/characters/milk_mocha_gift.png';

  /// The single bear peeking out — alone, waiting.
  static const String peek = 'assets/characters/mocha_peek.png';

  /// Artwork cycle played on every tap.
  static const List<String> reactions = <String>[kiss, hearts, gift, peek];

  /// Emoji that pops out with each tap reaction, same order as [reactions].
  static const List<String> reactionEmojis = <String>['💗', '💕', '🎁', '🥺'];

  /// Small face shown in the corner bubble for each emotion.
  static const Map<BearEmotion, String> moodEmojis = <BearEmotion, String>{
    BearEmotion.sad: '🥺',
    BearEmotion.sulky: '😕',
    BearEmotion.calm: '😌',
    BearEmotion.happy: '😊',
    BearEmotion.loving: '💗',
    BearEmotion.angry: '😤',
  };

  /// Artwork for a mood when nothing is being tapped.
  static String forEmotion(BearEmotion emotion) {
    switch (emotion) {
      case BearEmotion.loving:
        return kiss;
      case BearEmotion.happy:
        return hearts;
      case BearEmotion.calm:
        return gift;
      case BearEmotion.angry:
        return hearts;
      case BearEmotion.sulky:
        return gift;
      case BearEmotion.sad:
        // Waiting for the other one.
        return peek;
    }
  }

  /// Localised one-liner describing the mood between the two of you.
  static String caption(Strings s, BearMoodReport mood) {
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
}

/// Milk & Mocha — the couple's own little stage.
///
/// The pair is never static: it breathes, sways, sulks, shakes when care is
/// ignored, and reacts to taps. The emotion comes from
/// [BearMoodEngine], which reads the real nudge history — nothing is faked or
/// stored.
class BearPair extends StatefulWidget {
  const BearPair({
    super.key,
    required this.mood,
    required this.locale,
    this.artHeight = 148,
  });

  final BearMoodReport mood;
  final String locale;
  final double artHeight;

  @override
  State<BearPair> createState() => _BearPairState();
}

class _BearPairState extends State<BearPair> with TickerProviderStateMixin {
  /// Slow, looping "breathing" movement.
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )..repeat();

  /// Played on every tap: the little hop.
  late final AnimationController _tap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  /// Hearts that fly out on tap.
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// One listener for both loops so the art rebuilds once per frame.
  late final Listenable _motion = Listenable.merge(<Listenable>[_idle, _tap]);

  int _reaction = 0;
  bool _reacting = false;
  Timer? _reactTimer;

  @override
  void dispose() {
    _reactTimer?.cancel();
    _idle.dispose();
    _tap.dispose();
    _burst.dispose();
    super.dispose();
  }

  void _onTap() {
    _reactTimer?.cancel();
    setState(() {
      _reacting = true;
      _reaction = (_reaction + 1) % BearArt.reactions.length;
    });
    _tap.forward(from: 0);
    _burst.forward(from: 0);
    _reactTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _reacting = false);
    });
  }

  String get _asset => _reacting
      ? BearArt.reactions[_reaction]
      : BearArt.forEmotion(widget.mood.pair);

  String get _bubbleEmoji => _reacting
      ? BearArt.reactionEmojis[_reaction]
      : BearArt.moodEmojis[widget.mood.pair] ?? '💗';

  @override
  Widget build(BuildContext context) {
    final s = Strings(widget.locale);
    final mood = widget.mood;

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
              alignment: Alignment.center,
              children: <Widget>[
                Positioned.fill(
                  child: HeartBurst(
                    controller: _burst,
                    pieces: 14,
                    emojis: const <String>['💗', '💛', '💕', '✨'],
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onTap,
                    child: AnimatedBuilder(
                      animation: _motion,
                      builder: (BuildContext context, Widget? child) =>
                          _MovingArt(
                        emotion: mood.pair,
                        tap: _tap.value,
                        idle: _idle.value,
                        child: child,
                      ),
                      child: _BearImage(
                        asset: _asset,
                        height: widget.artHeight,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 6,
                  child: _Bubble(emoji: _bubbleEmoji, animation: _tap),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            BearArt.caption(s, mood),
            textAlign: TextAlign.center,
            style: Rom.body,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _MoodChip(
                label: s.t('mineLabel'),
                emoji: BearArt.moodEmojis[mood.mine] ?? '💗',
              ),
              const SizedBox(width: 8),
              _MoodChip(
                label: s.t('partnerDefault'),
                emoji: BearArt.moodEmojis[mood.theirs] ?? '💗',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Applies the idle breathing + the tap hop. Pure transform, no repaint cost
/// beyond this subtree.
class _MovingArt extends StatelessWidget {
  const _MovingArt({
    required this.emotion,
    required this.tap,
    required this.idle,
    required this.child,
  });

  final BearEmotion emotion;
  final double tap;
  final double idle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final wave = math.sin(idle * math.pi * 2);

    // Resting pose per emotion; the tap hop is layered on top of it.
    double dy = 4 * wave;
    double angle = 0.02 * wave;
    double scale = 1;
    double opacity = 1;

    if (emotion == BearEmotion.sad) {
      dy += 8;
      angle = -0.05 + 0.03 * wave;
      opacity = 0.82;
    } else if (emotion == BearEmotion.sulky) {
      dy += 5;
      angle = -0.045 + 0.02 * wave;
    } else if (emotion == BearEmotion.happy) {
      dy -= 3;
      scale = 1.02;
    } else if (emotion == BearEmotion.loving) {
      dy -= 5;
      scale = 1.03;
    } else if (emotion == BearEmotion.angry) {
      // Nervous, angry little shake.
      final shake = math.sin(idle * math.pi * 8);
      dy = shake * 5;
      angle = 0.07 * shake;
    }

    // Tap hop: 0 -> peak -> 0 over the tap controller.
    final hop = math.sin(tap * math.pi);
    dy -= 14 * hop;
    scale += 0.06 * hop;

    return Transform.translate(
      offset: Offset(0, dy),
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(
          scale: scale,
          child: Opacity(opacity: opacity, child: child),
        ),
      ),
    );
  }
}

class _BearImage extends StatelessWidget {
  const _BearImage({required this.asset, required this.height});

  final String asset;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
          _ArtPlaceholder(height: height),
    );
  }
}

/// Shown only while the artwork files are missing from `assets/characters/`.
/// Never used once the PNGs are added.
class _ArtPlaceholder extends StatelessWidget {
  const _ArtPlaceholder({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(Rom.rLg),
          ),
          child: const Text('🐻  🐻', style: TextStyle(fontSize: 40)),
        ),
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