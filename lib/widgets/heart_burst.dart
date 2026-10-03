import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/romantic_tokens.dart';

/// Confetti/hearts burst — fires when a nudge is sent or seen.
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
  final math.Random _rng = math.Random();

  late final List<_Particle> _particles = List<_Particle>.generate(
    widget.pieces,
    (int i) => _Particle.random(_rng),
  );

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (BuildContext context, _) {
          final t = widget.controller.value;
          if (t == 0) return const SizedBox.shrink();
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) => Stack(
              children: _particles.map((_Particle p) {
                final d = Curves.easeOutCubic.transform(t);
                final x = p.r.dx * c.maxWidth * d;
                final y = (p.r.dy * c.maxHeight * d) -
                    120 * d * d + p.rise * d;
                final opacity = t < 0.12 ? t / 0.12 : (1 - t).clamp(0.0, 1.0);
                final scale = p.scale * (0.6 + 0.6 * (1 - t));
                return Positioned(
                  left: x,
                  top: y,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.rotate(
                      angle: p.spin * t * 6.28,
                      child: Transform.scale(
                        scale: scale,
                        child: Text(p.glyph, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.glyph,
    required this.r,
    required this.scale,
    required this.spin,
    required this.rise,
  });

  factory _Particle.random(math.Random rng) => _Particle(
        glyph: const <String>['💗', '💛', '🤍', '✨', '💕', '🌸']
            [rng.nextInt(6)],
        r: Offset(
          0.5 + (rng.nextDouble() - 0.5) * 1.5,
          0.4 + (rng.nextDouble() - 0.5) * 0.7,
        ),
        scale: 0.7 + rng.nextDouble() * 0.9,
        spin: (rng.nextDouble() - 0.5) * 1.4,
        rise: 40 + rng.nextDouble() * 120,
      );

  final String glyph;
  final Offset r;
  final double scale;
  final double spin;
  final double rise;
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
    final child = AnimatedScale(
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
                Icon(widget.icon, color: Colors.white, size: widget.compact ? 17 : 20),
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
