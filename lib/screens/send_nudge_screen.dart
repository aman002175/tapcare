import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/strings.dart';
import '../state/app_state.dart';
import '../widgets/romantic_scaffold.dart';

/// Write a short custom nudge and send it with one tap.
class SendNudgeScreen extends ConsumerStatefulWidget {
  const SendNudgeScreen({super.key});

  @override
  ConsumerState<SendNudgeScreen> createState() => _SendNudgeScreenState();
}

class _SendNudgeScreenState extends ConsumerState<SendNudgeScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final s = Strings(ref.read(appProvider).locale);
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await ref.read(appProvider.notifier).sendNudge(
          message: text,
          emoji: '💛',
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.t('sentToast'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    final s = Strings(state.locale);

    return RomanticScaffold(
      seed: 2,
      hearts: 6,
      appBar: romAppBar(title: s.t('writeOwn')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  maxLength: 120,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: s.t('writeHint'),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(fontSize: 22, height: 1.4),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6E91),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _send,
                icon: const Icon(Icons.favorite, size: 20),
                label: Text(
                  s.t('sendBtn'),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
