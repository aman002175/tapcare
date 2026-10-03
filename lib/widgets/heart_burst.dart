import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/romantic_tokens.dart';

/// Confetti/hearts burst — fires when a nudge is sent or seen.
///
/// Paint-only: particles are generated once and drawn by a [CustomPainter]
/// that listens to the controller, so the burst costs no widget rebuilds.
class HeartBurst extends StatefulWidget {
  const HeartBurst({
    super.key,
    required this.controller,
    this.emojis = const <String>['💗', '💛', '🤍', '✨', '💕', '🌸'],
    this.pieces = 22,
  });

  final AnimationController controller;
  final List<String> emojis;
  final int pieces;

  @override
  State<HeartBurst> createState() => _HeartBurstState();
}

class _HeartBurstState extends State<HeartBurst> {
  late final _BurstPainter _painter;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _painter = _BurstPainter(
      animation: widget.controller,
      emojis: widget.emojis,
      particles: List<_Particle>.generate(
        widget.pieces,
        (int i) => _Particle.random(rng, widget.emojis),
      ),
    );
  }

  @override
  void dispose() {
    _painter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(painter: _painter),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.glyphIndex,
    required this.r,
    required this.scale,
    required this.spin,
    required this.rise,
  });

  factory _Particle.random(math.Random rng, List<String> emojis) => _Particle(
        glyphIndex: rng.nextInt(emojis.length),
        r: Offset(
          0.5 + (rng.nextDouble() - 0.5) * 1.5,
          0.4 + (rng.nextDouble() - 0.5) * 0.7,
        ),
        scale: 0.7 + rng.nextDouble() * 0.9,
        spin: (rng.nextDouble() - 0.5) * 1.4,
        rise: 40 + rng.nextDouble() * 120,
      );

  final int glyphIndex;
  final Offset r;
  final double scale;
  final double spin;
  final double rise;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.animation,
    required this.emojis,
    required this.particles,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final List<String> emojis;
  final List<_Particle> particles;
  Map<int, TextPainter>? _textPainters;

  Map<int, TextPainter> _painters() {
    return _textPainters ??= <int, TextPainter>{
      for (int i = 0; i < emojis.length; i++)
        i: (TextPainter(
          text: TextSpan(text: emojis[i], style: const TextStyle(fontSize: 20)),
          textDirection: TextDirection.ltr,
        )..layout()),
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = animation.value;
    if (t == 0) return;
    final painters = _painters();
    final eased = Curves.easeOutCubic.transform(t);

    for (final _Particle p in particles) {
      final x = p.r.dx * size.width * eased;
      final y = (p.r.dy * size.height * eased) -
          120 * eased * eased +
          p.rise * eased;
      final opacity = t < 0.12 ? t / 0.12 : (1 - t).clamp(0.0, 1.0);
      final scale = p.scale * (0.6 + 0.6 * (1 - t));
      final painter = painters[p.glyphIndex];
      if (painter == null) continue;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t * 6.28);
      canvas.scale(scale);
      canvas.translate(-painter.width / 2, -painter.height / 2);
      final alpha = opacity.clamp(0.0, 1.0);
      canvas.saveLayer(
        null,
        Paint()..color = Color.fromRGBO(255, 255, 255, alpha),
      );
      painter.paint(canvas, Offset.zero);
      canvas.restore();
      canvas.restore();
    }
  }

  void dispose() {
    _textPainters = null;
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) => false;
}

/// Pulsing gradient "shine" wrapper for primary CTA buttons.
class ShineButton extends StatefulWidget {
  const ShineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient = Rom.loveGradient,
    this.expand = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient gradient;
  final bool expand;
  final bool compact;

  @override
  State<ShineButton> createState() => _ShineButtonState();
}

class _ShineButtonState extends State<ShineButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final child = RepaintBoundary(
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 130),
        child: AnimatedOpacity(
          opacity: widget.onPressed == null ? 0.5 : 1,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: widget.expand ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 16 : 22,
              vertical: widget.compact ? 11 : 15,
            ),
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(widget.compact ? 16 : 20),
              boxShadow: Rom.glowShadow(Rom.rose),
            ),
            child: Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (widget.icon != null) ...<Widget>[
                  Icon(widget.icon,
                      color: Colors.white, size: widget.compact ? 17 : 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: widget.compact ? 13.5 : 16.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onPressed,
      child: child,
    );
  }
}