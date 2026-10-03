import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/strings.dart';
import '../design/romantic_tokens.dart';
import '../state/app_state.dart';
import '../themes/widget_themes.dart';
import '../widgets/heart_burst.dart';
import '../widgets/romance_motion.dart';
import '../widgets/theme_card.dart';

/// Settings: profile, language, accent colours, anniversary, themes,
/// premium stub (no payment flow yet) and demo-mode note.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _nameController;
  late String _emoji;

  static const List<String> _emojis = <String>[
    '🐼', '🦊', '🐱', '🐰', '🐻', '🦉', '🌻', '⚡',
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(appProvider).profile;
    _nameController = TextEditingController(text: profile?.displayName ?? '');
    _emoji = profile?.avatarEmoji ?? '🐼';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAnniversary(DateTime? current, String locale) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year, now.month, now.day),
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    await ref.read(appProvider.notifier).setAnniversary(picked);
    if (!mounted) return;
    final s = Strings(locale);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.t('anniversarySet')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    final s = Strings(state.locale);

    return AnimatedMeshBackground(
      seed: (state.profile?.id.hashCode ?? 11) + 4,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(s.t('settings'), style: Rom.title),
          iconTheme: const IconThemeData(color: Rom.ink),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: <Widget>[
              // ---- profile ----
              FadeSlideIn(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: Rom.glass(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(s.t('yourName'), style: Rom.title),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: s.t('yourName'),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        children: _emojis.map((String e) {
                          final active = e == _emoji;
                          return GestureDetector(
                            onTap: () => setState(() => _emoji = e),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: active
                                      ? Rom.rose
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child:
                                  Text(e, style: const TextStyle(fontSize: 21)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ShineButton(
                          label: s.t('save'),
                          icon: Icons.check_rounded,
                          compact: true,
                          gradient: Rom.gradientByName(state.accentName),
                          onPressed: () async {
                            await ref
                                .read(appProvider.notifier)
                                .updateProfile(
                                    name: _nameController.text, emoji: _emoji);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(s.t('save')),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ---- language ----
              FadeSlideIn(
                delayMs: 60,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: Rom.glass(),
                  child: Row(
                    children: <String>['hi', 'en'].map((String code) {
                      final active = code == state.locale;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              ref.read(appProvider.notifier).setLocale(code),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: active ? Rom.rose : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              code == 'hi' ? 'हिंदी' : 'English',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: active
                                    ? Colors.white
                                    : Rom.inkSoft,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ---- accent colours ----
              FadeSlideIn(
                delayMs: 110,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: Rom.glass(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('🎨 ${s.t('accent')}', style: Rom.title),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List<Widget>.generate(
                          Rom.palette.length,
                          (int i) {
                            final name = Rom.paletteNames[i];
                            final active = name == state.accentName;
                            return GestureDetector(
                              onTap: () => ref
                                  .read(appProvider.notifier)
                                  .setAccent(name),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  gradient: Rom.palette[i],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: active ? Rom.ink : Colors.white,
                                    width: active ? 3 : 2,
                                  ),
                                  boxShadow: active
                                      ? Rom.glowShadow(Rom.rose)
                                      : null,
                                ),
                                child: active
                                    ? const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 20)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ---- anniversary ----
              FadeSlideIn(
                delayMs: 160,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: Rom.glass(),
                  child: Row(
                    children: <Widget>[
                      const Text('💐', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(s.t('anniversary'), style: Rom.title),
                            Text(
                              state.anniversary == null
                                  ? s.t('setAnniversary')
                                  : '${state.anniversary!.day}/'
                                      '${state.anniversary!.month}/'
                                      '${state.anniversary!.year}',
                              style: Rom.body,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _pickAnniversary(
                            state.anniversary, state.locale),
                        child: Text(s.t('save'),
                            style: const TextStyle(
                                color: Rom.rose,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // ---- themes ----
              FadeSlideIn(
                delayMs: 210,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('🎨 ${s.t('themes')}', style: Rom.title),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 132,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: kThemes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (BuildContext context, int i) {
                          final t = kThemes[i];
                          return SizedBox(
                            width: 132,
                            child: ThemeCard(
                              theme: t,
                              selected: t.id == state.themeId,
                              locale: state.locale,
                              onTap: () {
                                if (t.locked) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(s.t('comingSoon')),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                ref
                                    .read(appProvider.notifier)
                                    .setTheme(t.id);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ---- premium stub ----
              FadeSlideIn(
                delayMs: 260,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: Rom.dreamGradient,
                    borderRadius: BorderRadius.circular(Rom.rLg),
                    boxShadow: Rom.glowShadow(Rom.lilac),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Text('👑', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(s.t('premiumLine1'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(s.t('premiumLine2'),
                          style: const TextStyle(
                              fontSize: 13, color: Colors.white70)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '₹199 · ${s.t('comingSoon')}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Rom.rose),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ---- about ----
              FadeSlideIn(
                delayMs: 310,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: Rom.glass(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE9F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(s.t('demoBadge'),
                            style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Rom.rose)),
                      ),
                      const SizedBox(height: 10),
                      Text(s.t('demoNote'), style: Rom.body),
                      const SizedBox(height: 6),
                      const Text('NudgeBuddy v1.1.0',
                          style: TextStyle(fontSize: 12, color: Rom.inkSoft)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
