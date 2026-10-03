import 'package:flutter/material.dart';

/// Widget themes — 3 free + 3 premium (locked until Razorpay is wired).
class WidgetTheme {
  const WidgetTheme({
    required this.id,
    required this.name,
    required this.background,
    required this.accent,
    required this.premium,
    required this.emoji,
  });

  final String id;
  final String name;
  final Color background;
  final Color accent;
  final bool premium;
  final String emoji;

  bool get locked => premium;
}

const List<WidgetTheme> kThemes = <WidgetTheme>[
  WidgetTheme(
    id: 'peach',
    name: 'Peach Glow',
    background: Color(0xFFFFF3EC),
    accent: Color(0xFFFF8A5B),
    premium: false,
    emoji: '🍑',
  ),
  WidgetTheme(
    id: 'mint',
    name: 'Mint Hug',
    background: Color(0xFFEAF9F1),
    accent: Color(0xFF38B88C),
    premium: false,
    emoji: '🌿',
  ),
  WidgetTheme(
    id: 'sky',
    name: 'Sky Squeeze',
    background: Color(0xFFEAF4FF),
    accent: Color(0xFF4A90E2),
    premium: false,
    emoji: '🌤️',
  ),
  WidgetTheme(
    id: 'rose',
    name: 'Rose Gold',
    background: Color(0xFFFFEDF1),
    accent: Color(0xFFE26D8E),
    premium: true,
    emoji: '🌹',
  ),
  WidgetTheme(
    id: 'night',
    name: 'Midnight Care',
    background: Color(0xFF1B1B2F),
    accent: Color(0xFF9B7BFF),
    premium: true,
    emoji: '🌙',
  ),
  WidgetTheme(
    id: 'festival',
    name: 'Festival Sparkle',
    background: Color(0xFFFFF8DC),
    accent: Color(0xFFF5A623),
    premium: true,
    emoji: '✨',
  ),
];

WidgetTheme themeById(String id) =>
    kThemes.firstWhere((WidgetTheme t) => t.id == id,
        orElse: () => kThemes.first);
