import 'package:flutter/material.dart';

import '../models/nudge.dart';
import '../widgets/nudge_overlay.dart';

/// Route wrapper around the animated [NudgeOverlay].
/// Waits a beat after "Seen" so the heart-burst celebration plays, then pops.
class OverlayScreen extends StatefulWidget {
  const OverlayScreen({
    super.key,
    required this.nudge,
    required this.senderName,
    required this.senderEmoji,
    required this.locale,
    required this.onSeen,
  });

  final Nudge nudge;
  final String senderName;
  final String senderEmoji;
  final String locale;
  final VoidCallback onSeen;

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  bool _leaving = false;

  Future<void> _handleSeen() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    widget.onSeen();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return NudgeOverlay(
      nudge: widget.nudge,
      senderName: widget.senderName,
      senderEmoji: widget.senderEmoji,
      locale: widget.locale,
      onSeen: _handleSeen,
    );
  }
}
