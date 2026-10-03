import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/romantic_tokens.dart';

/// Slow-drifting romantic gradient blobs behind a glassy card.
///
/// Performance: the gradient + 3 radial blobs are painted by a single
/// [CustomPainter] that listens to the controller (`repaint:`), so each frame
/// is a paint-only pass — no widget rebuild, no layout, no relayout.
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

  late _MeshPainter _painter;

  @override
  void initState() {
    super.initState();
    _painter = _MeshPainter(
      animation: _c,
      colors: _colorsForSeed(widget.seed),
    );
  }

  static const List<List<Color>> _palettes = <List<Color>>[
    <Color>[Color(0xFFFFE3EC), Color(0xFFFFF3E6), Color(0xFFEDE6FF)],
    <Color>[Color(0xFFFFF0E4), Color(0xFFFFE0EC), Color(0xFFE6F4FF)],
    <Color>[Color(0xFFEDE6FF), Color(0xFFFFE3EC), Color(0xFFFFF6E0)],
  ];

  static List<Color> _colorsForSeed(int seed) =>
      _palettes[seed.abs() % _palettes.length];

  @override
  void didUpdateWidget(AnimatedMeshBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) {
      // a NEW painter instance so the render object repaints with the new
      // palette (mutating the field alone would not trigger shouldRepaint)
      _painter = _MeshPainter(
        animation: _c,
        colors: _colorsForSeed(widget.seed),
      );
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _painter, child: widget.child);
}

class _MeshPainter extends CustomPainter {
  _MeshPainter({required this.animation, required this.colors})
      : super(repaint: animation);

  final Animation<double> animation;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = animation.value;
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(rect),
    );

    _blob(canvas, size, Rom.rose, 0.30,
        offset: Offset(-70 + 26 * math.cos(t * 2 * math.pi),
            -90 + 30 * math.sin(t * 2 * math.pi)),
        radiusFactor: 0.66);
    _blob(canvas, size, Rom.lilac, 0.26,
        offset: Offset(22 * math.cos(t * 2 * math.pi),
            120 + 34 * math.sin(t * 2 * math.pi + 1.4)),
        radiusFactor: 0.58);
    _blob(canvas, size, Rom.mint, 0.20,
        offset: Offset(-40 + 28 * math.sin(t * 2 * math.pi + 2.1),
            110 + 30 * math.cos(t * 2 * math.pi + 0.7)),
        radiusFactor: 0.61);
  }

  void _blob(
    Canvas canvas,
    Size size,
    Color color,
    double opacity, {
    required Offset offset,
    required double radiusFactor,
  }) {
    final radius = size.shortestSide * radiusFactor * 1.6;
    final center = Offset(size.width / 2 + offset.dx, size.height / 2 + offset.dy);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

/// Tiny floating hearts/hearts-in-the-air ambience.
///
/// Paint-only: glyphs are laid out once into [TextPainter]s and repositioned
/// by the painter, never rebuilt as widgets.
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

  late final _HeartsPainter _painter;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(7);
    final hearts = List<_Heart>.generate(widget.count, (int i) {
      return _Heart(
        glyphIndex: rng.nextInt(_glyphs.length),
        x: rng.nextDouble(),
        startY: 1.1 + rng.nextDouble() * 0.4,
        speed: 0.25 + rng.nextDouble() * 0.45,
        drift: (rng.nextDouble() - 0.5) * 0.18,
        scale: 0.55 + rng.nextDouble() * 0.6,
        phase: rng.nextDouble(),
      );
    });
    _painter = _HeartsPainter(
      animation: _c,
      hearts: hearts,
      speckOpacity: widget.speckOpacity,
    );
  }

  @override
  void didUpdateWidget(FloatingHearts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speckOpacity != widget.speckOpacity) {
      _painter.speckOpacity = widget.speckOpacity;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The hearts are ambience only and must NEVER block input:
    // IgnorePointer wraps ONLY the painter, never [child].
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        IgnorePointer(child: CustomPaint(painter: _painter)),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _Heart {
  _Heart({
    required this.glyphIndex,
    required this.x,
    required this.startY,
    required this.speed,
    required this.drift,
    required this.scale,
    required this.phase,
  });

  final int glyphIndex;
  final double x;
  final double startY;
  final double speed;
  final double drift;
  final double scale;
  final double phase;
}

class _HeartsPainter extends CustomPainter {
  _HeartsPainter({
    required this.animation,
    required this.hearts,
    required this.speckOpacity,
  })  : glyphs = FloatingHeartsGlyphs.all,
        _textPainters = _buildTextPainters(),
        super(repaint: animation);

  final Animation<double> animation;
  final List<_Heart> hearts;
  double speckOpacity;
  final List<String> glyphs;
  final Map<int, TextPainter> _textPainters;

  static Map<int, TextPainter> _buildTextPainters() {
    return <int, TextPainter>{
      for (int i = 0; i < FloatingHeartsGlyphs.all.length; i++)
        i: (TextPainter(
          text: TextSpan(
            text: FloatingHeartsGlyphs.all[i],
            style: const TextStyle(fontSize: 18),
          ),
          textDirection: TextDirection.ltr,
        )..layout()),
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = animation.value;
    for (final _Heart h in hearts) {
      final raw = (h.startY - t * h.speed) % 1.2;
      final y = 1.15 - raw;
      if (y < 0.02 || y > 1.02) continue;
      final x = h.x + math.sin((h.phase + t) * 6.28) * h.drift;
      final opacity = y > 0.92
          ? speckOpacity * (1.05 - y) / 0.13
          : speckOpacity;
      final painter = _textPainters[h.glyphIndex];
      if (painter == null) continue;
      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.scale(h.scale);
      // paint centred on the origin
      canvas.translate(-painter.width / 2, -painter.height / 2);
      canvas.saveLayer(
        null,
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, opacity.clamp(0.0, 1.0)),
      );
      painter.paint(canvas, Offset.zero);
      canvas.restore();
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _HeartsPainter oldDelegate) =>
      oldDelegate.speckOpacity != speckOpacity;
}

/// Shared glyph list (kept public-ish for the painter).
class FloatingHeartsGlyphs {
  FloatingHeartsGlyphs._();

  static const List<String> all = <String>['💗', '💛', '🤍', '✨', '💕'];
}

/// Playful entrance wrapper: fade + slide, staggered.
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
      child: RepaintBoundary(child: widget.child),
    );
  }
}

/// Soft pulsing "heartbeat" scale animation used on the logo and CTA.
/// Repaint-boundary isolated so the pulse never repaints the screen.
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
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? child) {
          final t = Curves.easeInOut.transform(
            _c.value < 0.5 ? _c.value * 2 : (1 - _c.value) * 2,
          );
          return Transform.scale(scale: 1 + 0.045 * t, child: child);
        },
        child: widget.child,
      ),
    );
  }
}