import 'package:flutter/material.dart';

import '../config/strings.dart';
import '../themes/widget_themes.dart';

/// Card used in Settings → theme picker. Premium themes show a lock badge
/// (no payment flow in this build — Razorpay comes later).
class ThemeCard extends StatelessWidget {
  const ThemeCard({
    super.key,
    required this.theme,
    required this.selected,
    required this.locale,
    required this.onTap,
  });

  final WidgetTheme theme;
  final bool selected;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Strings(locale);
    final locked = theme.locked;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? theme.accent : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(theme.emoji, style: const TextStyle(fontSize: 22)),
                if (locked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, size: 11, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          s.t('locked'),
                          style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.black54),
                        ),
                      ],
                    ),
                  )
                else if (selected)
                  Icon(Icons.check_circle, color: theme.accent, size: 18),
              ],
            ),
            const Spacer(),
            Text(
              theme.name,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            if (locked)
              Text(
                s.t('comingSoon'),
                style: TextStyle(
                  fontSize: 11,
                  color: theme.accent.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
