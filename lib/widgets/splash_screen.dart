import 'package:flutter/material.dart';

import '../design/romantic_tokens.dart';
import 'romance_motion.dart';

/// Branded launch screen for TapCare.
///
/// The animation is staged so the eye is led rather than shown everything at
/// once:
///   0.00 – 0.45  heart fades in and scales up from 65%
///   0.28 – 0.70  "TapCare" wordmark fades in and rises
///   0.50 – 0.86  tagline fades in and rises
///   0.62 – 1.00  loading dots fade in, then keep bouncing
///
/// A slower glow ring breathes behind the heart throughout, so the screen
/// still feels alive once the intro has settled.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// Drives the one-shot intro choreography.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  /// Slow breathing glow behind the logo.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  /// Bouncing dots.
  late final AnimationController _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    _dots.dispose();
    super.dispose();
  }

  /// Progress of a sub-range of the intro timeline, clamped to 0..1.
  double _seg(double from, double to) {
    final v = _intro.value;
    if (v <= from) return 0;
    if (v >= to) return 1;
    return (v - from) / (to - from);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      // Matches the native window background so there is no colour jump
      // between the Android launch theme and the first Flutter frame.
      color: Rom.blush,
      child: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: AnimatedMeshBackground(
              seed: 11,
              child: FloatingHearts(
                count: 10,
                child: SizedBox.shrink(),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[_intro, _pulse]),
              builder: (BuildContext context, Widget? _) {
                final heart = Curves.easeOutCubic.transform(_seg(0.00, 0.45));
                final name = Curves.easeOutCubic.transform(_seg(0.28, 0.70));
                final tagline = Curves.easeOutCubic.transform(_seg(0.50, 0.86));
                final loading = _seg(0.62, 1.00);
                final breathe = Curves.easeInOut.transform(_pulse.value);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // ---- logo mark ----
                    SizedBox(
                      width: 190,
                      height: 190,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          // breathing glow ring
                          Container(
                            width: 150 + 26 * breathe,
                            height: 150 + 26 * breathe,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: <Color>[
                                  Rom.rose.withValues(alpha: 0.26 - 0.12 * breathe),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          // the mark itself
                          Opacity(
                            opacity: heart,
                            child: Transform.scale(
                              scale: 0.65 + 0.35 * heart,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: Rom.loveGradient,
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: Rom.rose.withValues(alpha: 0.35),
                                      blurRadius: 28,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const SizedBox(
                                  width: 112,
                                  height: 112,
                                  child: Icon(
                                    Icons.favorite_rounded,
                                    size: 58,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),

                    // ---- wordmark ----
                    Opacity(
                      opacity: name,
                      child: Transform.translate(
                        offset: Offset(0, 18 * (1 - name)),
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) => Rom.loveGradient
                              .createShader(
                                Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                              ),
                          child: const Text(
                            'TapCare',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ---- tagline ----
                    Opacity(
                      opacity: tagline,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - tagline)),
                        child: const Text(
                          'बिना बोले, ख्याल 💛',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: Rom.inkSoft,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: tagline,
                      child: const Text(
                        'Care without words',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          letterSpacing: 2.4,
                          fontWeight: FontWeight.w700,
                          color: Rom.inkSoft,
                        ),
                      ),
                    ),

                    // ---- loading ----
                    const SizedBox(height: 44),
                    Opacity(
                      opacity: loading,
                      child: _LoadingDots(controller: _dots),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Three bouncing dots — replaces the default circular progress indicator.
class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.controller});

  final AnimationController controller;

  static const List<Color> _colors = <Color>[Rom.rose, Rom.coral, Rom.lilac];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (int i) {
            final phase = (controller.value + i * 0.22) % 1.0;
            final lift = (phase < 0.5 ? phase : 1 - phase) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.translate(
                offset: Offset(0, -9 * lift),
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: _colors[i].withValues(alpha: 0.40 + 0.60 * lift),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}