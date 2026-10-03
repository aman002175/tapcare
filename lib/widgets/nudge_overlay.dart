import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/strings.dart';
import '../data/romance_content.dart';
import '../design/romantic_tokens.dart';
import '../models/nudge.dart';
import '../themes/widget_themes.dart';
import 'heart_burst.dart';
import 'romance_motion.dart';

/// Full-screen animated overlay shown when a nudge arrives — the signature
/// "one tap and care" moment of TapCare.
class NudgeOverlay extends StatefulWidget {
  const NudgeOverlay({
    super.key,
    required this.nudge,
    required this.senderName,
    required this.senderEmoji,
    required this.locale,
    required this.onSeen,
  });

  final Nudge nudge;
  final String senderName;
  final String senderEmoji;
  final String locale;
  final VoidCallback onSeen;

  @override
  State<NudgeOverlay> createState() => _NudgeOverlayState();
}

class _NudgeOverlayState extends State<NudgeOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  late final Animation<double> _float = Tween<double>(begin: -12, end: 12)
      .animate(CurvedAnimation(parent: _drift, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) HapticFeedback.heavyImpact();
    });
  }

  @override
  void dispose() {
    _drift.dispose();
    _burst.dispose();
    super.dispose();
  }

  void _seen() {
    HapticFeedback.lightImpact();
    _burst.forward(from: 0);
    widget.onSeen();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings(widget.locale);
    final theme = themeById(widget.nudge.theme);
    final onDark = theme.background.computeLuminance() < 0.4;
    final textColor = onDark ? Colors.white : Rom.ink;
    final celebration = RomanceContent.celebrations[
        DateTime.now().millisecondsSinceEpoch %
            RomanceContent.celebrations.length];

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.background,
        body: Stack(
          children: <Widget>[
            // soft radial glow
            Positioned(
              top: -140,
              right: -80,
              child: IgnorePointer(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: <Color>[
                      theme.accent.withValues(alpha: 0.35),
                      theme.accent.withValues(alpha: 0),
                    ]),
                  ),
                ),
              ),
            ),
            FloatingHearts(count: 10, speckOpacity: 0.35, child: const SizedBox.expand()),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // sender chip
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeOutBack,
                      builder: (BuildContext context, double v, Widget? child) =>
                          Opacity(
                        opacity: v.clamp(0.0, 1.0),
                        child: Transform.scale(scale: v, child: child),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: onDark ? Colors.white12 : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: Rom.softShadow(opacity: 0.12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(widget.senderEmoji,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.senderName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // floating message card
                    AnimatedBuilder(
                      animation: _float,
                      builder: (BuildContext context, Widget? child) =>
                          Transform.translate(
                              offset: Offset(0, _float.value), child: child),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.7, end: 1),
                        duration: const Duration(milliseconds: 620),
                        curve: Curves.easeOutBack,
                        builder: (BuildContext context, double v, Widget? child) =>
                            Transform.scale(scale: v, child: child),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 34),
                          decoration: BoxDecoration(
                            gradient: Rom.loveGradient,
                            borderRadius: BorderRadius.circular(34),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Rom.rose.withValues(alpha: 0.38),
                                blurRadius: 40,
                                spreadRadius: -4,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Column(
                            children: <Widget>[
                              const Heartbeat(
                                child:
                                    Text('💗', style: TextStyle(fontSize: 46)),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                widget.nudge.message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 27,
                                  height: 1.3,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '💌 ${celebration[widget.locale] ?? celebration['en']}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // seen CTA
                    ShineButton(
                      label: s.t('overlaySeenBtn'),
                      icon: Icons.favorite_rounded,
                      gradient: Rom.loveGradient,
                      onPressed: _seen,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.locale == 'hi'
                          ? 'देखते ही ख़ुशी लगेगी ❤️'
                          : 'Seeing it is the whole point ❤️',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.55),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // hearts burst when seen
            Positioned.fill(child: HeartBurst(controller: _burst)),
          ],
        ),
      ),
    );
  }
}

/// Small helper used by the overlay route to know when the exit animation
/// should play.
class OverlayExitCurve {
  static double t(double v) => Curves.easeOutBack.transform(math.min(v, 1.0));
}
