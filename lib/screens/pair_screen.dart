import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/strings.dart';
import '../state/app_state.dart';
import '../widgets/romantic_scaffold.dart';

/// Pairing: generate invite code or accept a partner's code.
class PairScreen extends ConsumerStatefulWidget {
  const PairScreen({super.key});

  @override
  ConsumerState<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends ConsumerState<PairScreen> {
  final _codeController = TextEditingController();
  final _partnerController = TextEditingController();
  String _myCode = '';
  String? _error;

  static const List<String> _partnerEmojis = <String>[
    '🐼', '🦊', '🐱', '🐰', '🐻', '🦉',
  ];
  String _partnerEmoji = '🦊';

  @override
  void initState() {
    super.initState();
    _myCode = ref.read(appProvider.notifier).generateInviteCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _partnerController.dispose();
    super.dispose();
  }

  void _accept() {
    final s = Strings(ref.read(appProvider).locale);
    final code = _codeController.text.trim().toUpperCase();
    if (code.length < 4) {
      setState(() => _error = s.t('codeTooShort'));
      return;
    }
    ref.read(appProvider.notifier).acceptInvite(
          code: code,
          partnerName: _partnerController.text,
          partnerEmoji: _partnerEmoji,
        );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.t('pairToast'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    final s = Strings(state.locale);
    final pair = state.pair;

    return RomanticScaffold(
      seed: _myCode.hashCode,
      appBar: romAppBar(title: s.t('pairTitle')),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: pair != null
              ? _PairedView(myCode: _myCode)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      s.t('pairSubtitle'),
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF8A7A72), height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    // my invite code
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          Text(s.t('myCode'),
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF8A7A72))),
                          const SizedBox(height: 10),
                          Text(
                            _myCode,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 8,
                              color: Color(0xFFFF8A5B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(s.t('shareHint'),
                              style: const TextStyle(
                                  fontSize: 12.5, color: Color(0xFF8A7A72))),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                  ClipboardData(text: _myCode));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(s.t('copied'))),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: Text(s.t('copy')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      const Expanded(child: Divider(color: Color(0xFFE8D9CE))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(s.t('orDivider'),
                            style: const TextStyle(
                                color: Color(0xFF8A7A72),
                                fontWeight: FontWeight.w700)),
                      ),
                      const Expanded(child: Divider(color: Color(0xFFE8D9CE))),
                    ]),
                    const SizedBox(height: 20),
                    // accept partner code
                    TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      onChanged: (_) => setState(() => _error = null),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: s.t('enterCode'),
                        errorText: _error,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _partnerController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: s.t('partnerName'),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      children: _partnerEmojis.map((String e) {
                        final active = e == _partnerEmoji;
                        return GestureDetector(
                          onTap: () => setState(() => _partnerEmoji = e),
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: active
                                    ? const Color(0xFFFF8A5B)
                                    : const Color(0xFFEFE2D8),
                                width: active ? 2.5 : 1,
                              ),
                            ),
                            child: Text(e, style: const TextStyle(fontSize: 22)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A5B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: _accept,
                      child: Text(s.t('acceptBtn'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PairedView extends ConsumerWidget {
  const _PairedView({required this.myCode});

  final String myCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final s = Strings(state.locale);
    final pair = state.pair!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              Text(pair.partnerEmoji, style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 10),
              Text(
                '${s.t('pairedWith')} ${pair.partnerName}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3B2F2F)),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${s.t('myCode')}: $myCode',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF8A5B),
                      letterSpacing: 1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(s.t('breakPair')),
                content: Text(s.t('breakPairConfirm')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(s.t('cancel')),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(s.t('breakPair')),
                  ),
                ],
              ),
            );
            if (ok == true) {
              await ref.read(appProvider.notifier).breakPair();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.t('unpairedToast'))),
                );
              }
            }
          },
          child: Text(s.t('breakPair')),
        ),
      ],
    );
  }
}
