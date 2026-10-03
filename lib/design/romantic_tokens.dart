import 'package:flutter/material.dart';

/// NudgeBuddy romantic design tokens — soft blush palette, glass cards,
/// glowy hearts. Used across every screen so the feel stays consistent.
class Rom {
  Rom._();

  // Base palette
  static const Color blush = Color(0xFFFFF4F0);
  static const Color cream = Color(0xFFFFFBF7);
  static const Color rose = Color(0xFFFF6E91);
  static const Color coral = Color(0xFFFF8A5B);
  static const Color peach = Color(0xFFFFB199);
  static const Color lilac = Color(0xFFC39BFF);
  static const Color mint = Color(0xFF5BC9B0);
  static const Color sky = Color(0xFF6FA8FF);
  static const Color ink = Color(0xFF4A2F3A);
  static const Color inkSoft = Color(0xFF9A7B86);
  static const Color white70 = Color(0xB3FFFFFF);

  // Gradients
  static const LinearGradient loveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9EBB), Color(0xFFFF6E91)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFC1A6), Color(0xFFFF8A5B)],
  );

  static const LinearGradient dreamGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD8B4FF), Color(0xFF9B7BFF)],
  );

  static const LinearGradient calmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9BE8D4), Color(0xFF4FC3A8)],
  );

  static const LinearGradient nightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A2A4D), Color(0xFF7B4B8A)],
  );

  static const List<LinearGradient> palette = <LinearGradient>[
    loveGradient,
    warmGradient,
    dreamGradient,
    calmGradient,
    nightGradient,
  ];

  static const List<String> paletteNames = <String>[
    'Blush',
    'Sunset',
    'Lavender',
    'Mint',
    'Night',
  ];

  static LinearGradient gradientByName(String name) {
    final index = paletteNames.indexOf(name);
    return palette[index >= 0 ? index : 0];
  }

  // Radii
  static const double rSm = 14;
  static const double rMd = 20;
  static const double rLg = 28;
  static const double rXl = 36;

  // Shadows
  static List<BoxShadow> softShadow({double opacity = 0.16}) => <BoxShadow>[
        BoxShadow(
          color: rose.withValues(alpha: opacity),
          blurRadius: 26,
          spreadRadius: -6,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> glowShadow(Color color) => <BoxShadow>[
        BoxShadow(
          color: color.withValues(alpha: 0.42),
          blurRadius: 22,
          spreadRadius: -4,
          offset: const Offset(0, 8),
        ),
      ];

  static BoxDecoration glass({
    Color tint = white70,
    double radius = rLg,
    bool border = true,
  }) =>
      BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(radius),
        border: border
            ? Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1.2)
            : null,
        boxShadow: softShadow(),
      );

  // Text
  static const TextStyle display = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: ink,
    height: 1.2,
    letterSpacing: -0.4,
  );

  static const TextStyle title = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    color: ink,
    height: 1.25,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14.5,
    color: inkSoft,
    height: 1.45,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.1,
    color: inkSoft,
  );
}
