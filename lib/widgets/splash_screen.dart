import 'package:flutter/material.dart';

import '../design/romantic_tokens.dart';
import 'romance_motion.dart';

/// Branded animated splash shown while the app boots.
///
/// Before this existed the window sat on a plain white `NormalTheme`
/// background until Flutter drew its first frame, which is what the user saw
/// as a "white screen". The native launch theme now paints the same blush
/// background, so this widget continues that colour instead of flashing.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  late final AnimationController _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Matches the native window background so there is no colour jump
      // between the Android launch theme and the first Flutter frame.
      backgroundColor: Rom.blush,
      body: Stack(
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
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // pulsing heart ring
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (BuildContext context, Widget? child) {
                    final t = Curves.easeInOut.transform(_pulse.value);
                    return Container(
                      width: 132 + 16 * t,
                      height: 132 + 16 * t,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: <Color>[
                            Rom.loveGradient.colors.first
                                .withValues(alpha: 0.34 - 0.14 * t),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(child: child),
                    );
                  },
                  child: const Heartbeat(
                    child: Text('💗', style: TextStyle(fontSize: 64)),
                  ),
                ),
                const SizedBox(height: 22),
                // wordmark
                ShaderMask(
                  shaderCallback: (Rect bounds) => Rom.loveGradient
                      .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                  child: const Text(
                    'TapCare',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'बिना बोले, ख्याल 💛',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Rom.inkSoft,
                  ),
                ),
                const SizedBox(height: 34),
                _LoadingDots(controller: _dots),
                const SizedBox(height: 18),
                const Text(
                  'loading your love story…',
                  style: TextStyle(fontSize: 11.5, color: Rom.inkSoft),
                ),
              ],
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

  static const List<Color> _dots = <Color>[Rom.rose, Rom.coral, Rom.lilac];

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
                offset: Offset(0, -10 * lift),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _dots[i].withValues(alpha: 0.45 + 0.55 * lift),
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
