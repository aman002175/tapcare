import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/strings.dart';
import '../state/app_state.dart';
import '../widgets/romance_motion.dart';
import '../widgets/romantic_scaffold.dart';

/// First launch: display name + avatar emoji (stored locally).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  String _emoji = '🐼';
  String _locale = 'hi';

  static const List<String> _emojis = <String>[
    '🐼', '🦊', '🐱', '🐰', '🐻', '🦉', '🌻', '⚡',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final s = Strings(_locale);
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('nameRequired'))),
      );
      return;
    }
    ref
        .read(appProvider.notifier)
        .completeOnboarding(_nameController.text, _emoji);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    _locale = state.locale;
    final s = Strings(_locale);

    return RomanticScaffold(
      seed: _emoji.hashCode,
      hearts: 6,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 24),

              // Staggered fade-in: the page assembles itself instead of
              // snapping in. Fading *out* (when the name is submitted and the
              // app swaps to home) is handled by the AnimatedSwitcher that
              // wraps this screen in main.dart.
              FadeSlideIn(
                child: _Header(s: s),
              ),
              const SizedBox(height: 40),

              FadeSlideIn(
                delayMs: 70,
                child: _NameBlock(
                  s: s,
                  controller: _nameController,
                ),
              ),
              const SizedBox(height: 26),

              FadeSlideIn(
                delayMs: 140,
                child: _EmojiBlock(
                  s: s,
                  emojis: _emojis,
                  selected: _emoji,
                  onPick: (String e) => setState(() => _emoji = e),
                ),
              ),
              const SizedBox(height: 40),

              FadeSlideIn(
                delayMs: 210,
                child: Column(
                  children: <Widget>[
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A5B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: _submit,
                      child: Text(
                        s.t('startBtn'),
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // quick locale switch on onboarding
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        _LocaleButton(
                          code: 'hi',
                          label: 'हिंदी',
                          active: _locale == 'hi',
                          onTap: () =>
                              ref.read(appProvider.notifier).setLocale('hi'),
                        ),
                        _LocaleButton(
                          code: 'en',
                          label: 'English',
                          active: _locale == 'en',
                          onTap: () =>
                              ref.read(appProvider.notifier).setLocale('en'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.s});

  final Strings s;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Text(
          '💛',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 64),
        ),
        const SizedBox(height: 12),
        Text(
          s.t('appTitle'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Color(0xFF3B2F2F),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.t('tagline'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF8A7A72),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _NameBlock extends StatelessWidget {
  const _NameBlock({required this.s, required this.controller});

  final Strings s;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          s.t('onboardTitle'),
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: s.t('nameHint'),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmojiBlock extends StatelessWidget {
  const _EmojiBlock({
    required this.s,
    required this.emojis,
    required this.selected,
    required this.onPick,
  });

  final Strings s;
  final List<String> emojis;
  final String selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          s.t('chooseEmoji'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: emojis.map((String e) {
            final active = e == selected;
            return GestureDetector(
              onTap: () => onPick(e),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: active ? const Color(0xFFFF8A5B) : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: Text(e, style: const TextStyle(fontSize: 26)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LocaleButton extends StatelessWidget {
  const _LocaleButton({
    required this.code,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String code;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: TextButton(
        // `code` is kept so the two buttons never collapse into identical
        // widgets in the tree.
        key: ValueKey<String>('locale_$code'),
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            color: active ? const Color(0xFFFF8A5B) : const Color(0xFF8A7A72),
          ),
        ),
      ),
    );
  }
}