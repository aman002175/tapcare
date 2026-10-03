import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/bear_mood.dart';
import 'bear_art.dart';

/// One frame of a cartoon character's body language.
///
/// Produced by [RigAnimator] (pure maths, unit-tested) and consumed by
/// [BearStage] (which only decides where the pieces go). Keeping the maths out
/// of the widget is what makes "does the blink actually close / does the head
/// actually turn" a testable claim instead of a vibe.
class RigPose {
  const RigPose({
    required this.walkT,
    required this.facingRight,
    required this.bob,
    required this.bodyAngle,
    required this.headAngle,
    required this.headDx,
    required this.headDy,
    required this.scale,
    required this.opacity,
    required this.eyesClosed,
    required this.mouthOpen,
  });

  /// 0..1 progress along the current walk, 0 → 1 → 0 (there and back).
  final double walkT;

  /// Which way the character is walking — drives the lean and the eye shift.
  final bool facingRight;

  /// Vertical hop, in logical pixels.
  final double bob;

  /// Body sway while walking.
  final double bodyAngle;

  /// Neck tilt of the head.
  final double headAngle;

  /// Head glance, in logical pixels (positive = towards the partner).
  final double headDx;

  final double headDy;
  final double scale;
  final double opacity;

  /// True during a blink.
  final bool eyesClosed;

  /// True when the mouth is open (talking / smiling).
  final bool mouthOpen;
}

/// Turns a looping clock into believable cartoon motion.
///
/// No widgets, no painting — just numbers, so the behaviour is testable and the
/// same for both characters.
class RigAnimator {
  RigAnimator._();

  /// How many times the character walks out *and back* during one clock loop.
  ///
  /// Must be a whole number, otherwise the walk jumps when the clock wraps.
  static int traversesPerLoop(BearEmotion emotion) {
    switch (emotion) {
      case BearEmotion.sad:
        return 1;
      case BearEmotion.sulky:
        return 1;
      case BearEmotion.calm:
        return 1;
      case BearEmotion.happy:
        return 2;
      case BearEmotion.loving:
        return 1;
      case BearEmotion.angry:
        return 2;
    }
  }

  /// A blink, twice per beat — the classic cartoon double-blink.
  static bool isBlinking(double t) {
    final double beat = (t * 6) % 1.0;
    return beat < 0.06 || (beat > 0.15 && beat < 0.21);
  }

  /// How open the mouth is, 0..1.
  static double mouthOpenness({
    required double t,
    required BearEmotion emotion,
    required bool speaking,
    required double talk,
  }) {
    if (speaking) {
      // Fast chatter while the character "talks" back at you.
      return math.sin(talk * math.pi * 3).clamp(0.0, 1.0);
    }
    if (emotion == BearEmotion.happy || emotion == BearEmotion.loving) {
      // A small, slow "so happy" mouth.
      final double beat = (t * 3) % 1.0;
      return beat < 0.22 ? 1 - (beat / 0.22) : 0.0;
    }
    return 0.0;
  }

  /// Full body language for one moment in time.
  ///
  /// [t] is a 0..1 looping clock, [partnerSide] is +1 when the other character
  /// is to the right of this one (the head glances that way).
  static RigPose pose({
    required double t,
    required BearEmotion emotion,
    bool speaking = false,
    double talk = 0,
    int partnerSide = 1,
  }) {
    // ---- walk: out and back, direction from which half we are on ----
    //
    // The triangle below is periodic with period 2, so the clock is scaled by
    // 2: one loop is exactly `traversesPerLoop` complete out-and-backs and
    // `t = 1` lands back on `t = 0`. Anything else makes the character
    // teleport back to its start mid-loop.
    final double phase = (t * traversesPerLoop(emotion) * 2) % 2.0;
    final bool facingRight = phase <= 1.0;
    final double walkT = facingRight ? phase : 2.0 - phase;

    // ---- legs: two steps per traverse, so the bob matches the walk ----
    final double steps = math.sin(walkT * math.pi * 4);
    final double sway = math.sin(t * math.pi * 2) * 0.02;
    final double angryShake =
        emotion == BearEmotion.angry ? math.sin(t * math.pi * 16) * 0.05 : 0.0;

    double bobAmp = 3.0;
    double bodyAngle = steps * 0.035 + sway + angryShake;
    double headAngle = math.sin(t * math.pi * 2 + 0.7) * 0.06;
    double headDy = 0;
    double headDx = partnerSide * 5.0;
    double scale = 1.0;
    double opacity = 1.0;

    switch (emotion) {
      case BearEmotion.sad:
        // Head down, shoulders low, barely any bounce.
        bobAmp = 1.2;
        headAngle -= 0.10;
        headDy += 7;
        scale = 0.97;
        opacity = 0.86;
      case BearEmotion.sulky:
        bobAmp = 1.8;
        headAngle -= 0.08;
        headDy += 3;
      case BearEmotion.calm:
        bobAmp = 2.4;
      case BearEmotion.happy:
        bobAmp = 5.0;
        headAngle += 0.03;
        scale = 1.02;
      case BearEmotion.loving:
        bobAmp = 4.0;
        // Lean towards the partner.
        headAngle += 0.06 * partnerSide;
        headDx = partnerSide * 9.0;
        scale = 1.03;
      case BearEmotion.angry:
        bobAmp = 2.0;
        headAngle += math.sin(t * math.pi * 14) * 0.05;
        headDx = partnerSide * 2.0;
    }

    // Looking where you walk, on top of the partner glance.
    headDx += facingRight ? 3.0 : -3.0;

    return RigPose(
      walkT: walkT,
      facingRight: facingRight,
      bob: steps * bobAmp,
      bodyAngle: bodyAngle,
      headAngle: headAngle,
      headDx: headDx,
      headDy: headDy,
      scale: scale,
      opacity: opacity,
      eyesClosed: isBlinking(t),
      mouthOpen: mouthOpenness(
        t: t,
        emotion: emotion,
        speaking: speaking,
        talk: talk,
      ) > 0.15,
    );
  }
}

/// Where the cut-out pieces sit, as a fraction of the character's box.
///
/// These defaults suit the current artwork; nudging them is a one-line change
/// per piece if a re-cut needs it.
class RigLayout {
  RigLayout._();

  /// How wide one character is, relative to the stage.
  static const double charWidth = 0.46;

  /// Horizontal centre of the head.
  static const double headCentre = 0.5;

  /// Top of the head inside the character box.
  static const double headTop = 0.04;

  /// Head size relative to the character box.
  static const double headWidth = 0.62;
  static const double headHeight = 0.52;

  /// Eyes, relative to the character box.
  static const double eyeWidth = 0.085;
  static const double eyeTop = 0.24;
  static const double eyeLeftCentre = 0.40;
  static const double eyeRightCentre = 0.60;

  /// Mouth, relative to the character box.
  static const double mouthWidth = 0.11;
  static const double mouthCentre = 0.50;
  static const double mouthTop = 0.40;

  /// Arm, relative to the character box.
  static const double armWidth = 0.22;
  static const double armCentre = 0.70;
  static const double armTop = 0.42;
}

/// One living cartoon character on the stage.
///
/// Draws the flat artwork plus whichever cut-out parts exist: a head that turns
/// on the neck, eyes that blink, a mouth that opens, an arm that swings.
class BearStage extends StatefulWidget {
  const BearStage({
    super.key,
    required this.emotion,
    required this.art,
    required this.who,
    this.speaking = false,
    this.phaseOffset = 0,
    this.partnerSide = 1,
    this.laneStart = 0.22,
    this.laneEnd = 0.78,
    this.onTap,
    this.height = 150,
  });

  /// Current shared mood.
  final BearEmotion emotion;

  /// Flat artwork for this pose (kiss / hearts / gift / peek).
  final String art;

  /// Which character's cut-out parts to use: `milk` or `mocha`.
  final String who;

  /// True while the character is "talking back" after a tap.
  final bool speaking;

  /// Offsets the walk + blink so the two characters never march in lockstep.
  final double phaseOffset;

  /// +1 when the other character is to the right.
  final int partnerSide;

  /// Lane the character walks between, as a fraction of the stage width.
  final double laneStart;
  final double laneEnd;

  final VoidCallback? onTap;
  final double height;

  @override
  State<BearStage> createState() => _BearStageState();
}

class _BearStageState extends State<BearStage> with TickerProviderStateMixin {
  /// One slow loop for the whole "life" of the character.
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 16000),
  )..repeat();

  /// Mouth chatter, only running while the character is talking.
  late final AnimationController _talk = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void didUpdateWidget(BearStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.speaking && !oldWidget.speaking) {
      _talk.repeat();
    } else if (!widget.speaking && oldWidget.speaking) {
      _talk.stop();
      _talk.value = 0;
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    _talk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          final Size size = Size(box.maxWidth, widget.height);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AnimatedBuilder(
              animation: _clock,
              builder: (BuildContext context, Widget? child) {
                final RigPose pose = RigAnimator.pose(
                  t: (_clock.value + widget.phaseOffset) % 1.0,
                  emotion: widget.emotion,
                  speaking: widget.speaking,
                  talk: _talk.value,
                  partnerSide: widget.partnerSide,
                );
                return _Character(
                  pose: pose,
                  art: widget.art,
                  who: widget.who,
                  size: size,
                  laneStart: widget.laneStart,
                  laneEnd: widget.laneEnd,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Character extends StatelessWidget {
  const _Character({
    required this.pose,
    required this.art,
    required this.who,
    required this.size,
    required this.laneStart,
    required this.laneEnd,
  });

  final RigPose pose;
  final String art;
  final String who;
  final Size size;
  final double laneStart;
  final double laneEnd;

  String _part(String file) => BearArt.part(who, '${who}_$file');

  @override
  Widget build(BuildContext context) {
    final double boxW = size.width * RigLayout.charWidth;
    final double centre =
        size.width * (laneStart + pose.walkT * (laneEnd - laneStart));

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          left: centre - boxW / 2,
          top: 0,
          bottom: 0,
          width: boxW,
          child: Transform.translate(
            offset: Offset(0, pose.bob),
            child: Transform.rotate(
              angle: pose.bodyAngle,
              alignment: Alignment.bottomCenter,
              child: Transform.scale(
                scale: pose.scale,
                alignment: Alignment.bottomCenter,
                child: Opacity(
                  opacity: pose.opacity,
                  child: _parts(boxW, size.height),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The body, then the head group on top of it.
  Widget _parts(double boxW, double boxH) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        // arm (behind the body so the paw stays tucked in)
        _piece(
          file: _part('arm.png'),
          width: boxW * RigLayout.armWidth,
          height: boxH * 0.30,
          align: Alignment(
            (RigLayout.armCentre - 0.5) * 2,
            -1 + RigLayout.armTop * 2,
          ),
          swing: pose.facingRight ? -0.12 : 0.12,
        ),
        // body / whole character
        _piece(
          file: _part('body.png'),
          fallbackAsset: art,
          width: boxW,
          height: boxH,
        ),
        // head group — rotates about the neck
        _head(boxW, boxH),
      ],
    );
  }

  Widget _head(double boxW, double boxH) {
    final double headW = boxW * RigLayout.headWidth;
    final double headH = boxH * RigLayout.headHeight;

    return Positioned(
      left: boxW * (RigLayout.headCentre - RigLayout.headWidth / 2),
      top: boxH * RigLayout.headTop,
      width: headW,
      height: headH,
      child: Transform.translate(
        offset: Offset(pose.headDx, pose.headDy),
        child: Transform.rotate(
          angle: pose.headAngle,
          // The neck sits at the bottom of the head, so that is the pivot.
          alignment: const Alignment(0, 0.8),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              _piece(file: _part('head.png'), width: headW, height: headH),
              if (pose.eyesClosed || BearArt.has(_part('eye_l.png'))) ...<Widget>[
                _piece(
                  file: _part('eye_l.png'),
                  fallbackAsset: pose.eyesClosed ? _part('lid_l.png') : null,
                  width: boxW * RigLayout.eyeWidth,
                  height: boxW * RigLayout.eyeWidth,
                  align: Alignment(
                    (RigLayout.eyeLeftCentre - 0.5) * 2 / RigLayout.headWidth,
                    -1 + (RigLayout.eyeTop - RigLayout.headTop) * 2 /
                        RigLayout.headHeight,
                  ),
                ),
                _piece(
                  file: _part('eye_r.png'),
                  fallbackAsset: pose.eyesClosed ? _part('lid_r.png') : null,
                  width: boxW * RigLayout.eyeWidth,
                  height: boxW * RigLayout.eyeWidth,
                  align: Alignment(
                    (RigLayout.eyeRightCentre - 0.5) * 2 / RigLayout.headWidth,
                    -1 + (RigLayout.eyeTop - RigLayout.headTop) * 2 /
                        RigLayout.headHeight,
                  ),
                ),
              ],
              if (pose.mouthOpen || BearArt.has(_part('mouth.png')))
                _piece(
                  file: _part('mouth.png'),
                  fallbackAsset: pose.mouthOpen ? _part('mouth_open.png') : null,
                  width: boxW * RigLayout.mouthWidth,
                  height: boxW * RigLayout.mouthWidth * 0.7,
                  align: Alignment(
                    (RigLayout.mouthCentre - 0.5) * 2 / RigLayout.headWidth,
                    -1 + (RigLayout.mouthTop - RigLayout.headTop) * 2 /
                        RigLayout.headHeight,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// One cut-out piece.
  ///
  /// [fallbackAsset] is used when the piece itself was not cut; when that is
  /// missing too the piece simply is not drawn. Nothing here ever touches a
  /// file that is not in the bundle — [BearArt.has] checked first.
  Widget _piece({
    required String file,
    required double width,
    required double height,
    String? fallbackAsset,
    Alignment align = Alignment.center,
    double swing = 0,
  }) {
    final String? asset = BearArt.has(file)
        ? file
        : (fallbackAsset != null && BearArt.has(fallbackAsset)
            ? fallbackAsset
            : null);
    if (asset == null) return const SizedBox.shrink();

    Widget piece = Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
    if (swing != 0) {
      piece = Transform.rotate(
        angle: swing,
        alignment: Alignment.topCenter,
        child: piece,
      );
    }
    if (align != Alignment.center) {
      piece = Align(alignment: align, child: piece);
    }
    return piece;
  }
}