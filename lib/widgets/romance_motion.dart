import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/romantic_tokens.dart';

/// Slow-drifting romantic gradient blobs behind a glassy card — the app's
/// signature background on every screen.
class AnimatedMeshBackground extends StatefulWidget {
  const AnimatedMeshBackground({
    super.key,
    required this.child,
    this.seed = 0,
  });

  final Widget child;
  final int seed;

  @override
  State<AnimatedMeshBackground> createState() => _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends State<AnimatedMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  )..repeat();

  static const List<List<Color>> _palettes = <List<Color>>[
    <Color>[Color(0xFFFFE3EC), Color(0xFFFFF3E6), Color(0xFFEDE6FF)],
    <Color>[Color(0xFFFFF0E4), Color(0xFFFFE0EC), Color(0xFFE6F4FF)],
    <Color>[Color(0xFFEDE6FF), Color(0xFFFFE3EC), Color(0xFFFFF6E0)],
  ];

  /// Blobs are built ONCE and only transformed afterwards, so the ambient
  /// animation never triggers a relayout (paint-only per frame).
  late final List<Widget> _blobs = <Widget>[
    _blob(Rom.rose, 260, 0.30),
    _blob(Rom.lilac, 230, 0.26),
    _blob(Rom.mint, 240, 0.20),
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = _palettes[widget.seed % _palettes.length];
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) {
        final t = _c.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: base,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Transform.translate(
                      offset: Offset(-70 + 26 * math.cos(t * 2 * math.pi),
                          -90 + 30 * math.sin(t * 2 * math.pi)),
                      child: Align(
                          alignment: Alignment.topLeft, child: _blobs[0]),
                    ),
                    Transform.translate(
                      offset: Offset(22 * math.cos(t * 2 * math.pi),
                          120 + 34 * math.sin(t * 2 * math.pi + 1.4)),
                      child: Align(
                          alignment: Alignment.topRight, child: _blobs[1]),
                    ),
                    Transform.translate(
                      offset: Offset(-40 + 28 * math.sin(t * 2 * math.pi + 2.1),
                          110 + 30 * math.cos(t * 2 * math.pi + 0.7)),
                      child: Align(
                          alignment: Alignment.bottomLeft, child: _blobs[2]),
                    ),
                  ],
                ),
              ),
              child ?? const SizedBox.shrink(),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }

  Widget _blob(Color color, double size, double opacity) => RepaintBoundary(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0)
              ],
            ),
          ),
        ),
      );
}

/// Tiny floating hearts/hearts-in-the-air ambience.
class FloatingHearts extends StatefulWidget {
  const FloatingHearts({
    super.key,
    this.count = 12,
    this.speckOpacity = 0.5,
    this.child,
  });

  final int count;
  final double speckOpacity;
  final Widget? child;

  @override
  State<FloatingHearts> createState() => _FloatingHeartsState();
}

class _FloatingHeartsState extends State<FloatingHearts>
    with SingleTickerProviderStateMixin {
  static const List<String> _glyphs = <String>['💗', '💛', '🤍', '✨', '💕'];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  final math.Random _rng = math.Random(7);

  late final List<_Heart> _hearts = List<_Heart>.generate(widget.count, (int i) {
    return _Heart(
      glyph: _glyphs[_rng.nextInt(_glyphs.length)],
      x: _rng.nextDouble(),
      startY: 1.1 + _rng.nextDouble() * 0.4,
      speed: 0.25 + _rng.nextDouble() * 0.45,
      drift: (_rng.nextDouble() - 0.5) * 0.18,
      scale: 0.55 + _rng.nextDouble() * 0.6,
      phase: _rng.nextDouble(),
    );
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The floating hearts are ambience only and must NEVER block input:
    // IgnorePointer wraps ONLY the hearts, never [child].
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _c,
            builder: (BuildContext context, _) => LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ..._hearts.map((_Heart h) {
                      final t = (h.startY - _c.value * h.speed) % 1.2;
                      final y = 1.15 - t;
                      final x =
                          h.x + math.sin((h.phase + _c.value) * 6.28) * h.drift;
                      return Positioned(
                        left: x * constraints.maxWidth,
                        top: y * constraints.maxHeight,
                        child: Opacity(
                          // fade in at the bottom, out at the top
                          opacity: (y < 0.02 || y > 1.02)
                              ? 0
                              : (widget.speckOpacity *
                                      (y > 0.92 ? (1.05 - y) / 0.13 : 1))
                                  .clamp(0.0, 1.0),
                          child: Text(h.glyph,
                              style: TextStyle(fontSize: 18 * h.scale)),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _Heart {
  _Heart({
    required this.glyph,
    required this.x,
    required this.startY,
    required this.speed,
    required this.drift,
    required this.scale,
    required this.phase,
  });

  final String glyph;
  final double x;
  final double startY;
  final double speed;
  final double drift;
  final double scale;
  final double phase;
}

/// Playful entrance wrapper: fade + slide + slight scale, staggered.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.offsetY = 18,
  });

  final Widget child;
  final int delayMs;
  final double offsetY;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void initState() {
    super.initState();
    if (widget.delayMs == 0) {
      _c.forward();
    } else {
      Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curve,
      builder: (BuildContext context, Widget? child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
          offset: Offset(0, widget.offsetY * (1 - curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Soft pulsing "heartbeat" scale animation used on the logo and CTA.
class Heartbeat extends StatefulWidget {
  const Heartbeat({super.key, required this.child, this.active = true});

  final Widget child;
  final bool active;

  @override
  State<Heartbeat> createState() => _HeartbeatState();
}

class _HeartbeatState extends State<Heartbeat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(Heartbeat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) {
        final t = Curves.easeInOut.transform(
          _c.value < 0.5 ? _c.value * 2 : (1 - _c.value) * 2,
        );
        final scale = 1 + 0.045 * t;
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}
