import 'package:flutter/material.dart';

import '../design/romantic_tokens.dart';
import 'romance_motion.dart';

/// Scaffold with the TapCare romantic background (mesh + floating hearts),
/// so every screen shares the same warm, dreamy feel.
class RomanticScaffold extends StatelessWidget {
  const RomanticScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.seed = 0,
    this.hearts = 8,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final int seed;
  final int hearts;

  @override
  Widget build(BuildContext context) {
    return AnimatedMeshBackground(
      seed: seed,
      child: FloatingHearts(
        count: hearts,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          body: child,
        ),
      ),
    );
  }
}

/// AppBar with the transparent, mesh-friendly styling.
AppBar romAppBar({
  required String title,
  List<Widget>? actions,
}) =>
    AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Rom.ink),
      title: Text(title, style: Rom.title),
      actions: actions,
    );
