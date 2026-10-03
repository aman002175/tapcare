import 'package:home_widget/home_widget.dart';

import '../data/romance_content.dart';
import '../models/app_user.dart';
import '../models/nudge.dart';
import '../models/pairing.dart';
import '../state/app_state.dart';

/// Pushes the couple's live care data onto the Android home-screen widget.
///
/// The native side ([TapCareWidgetProvider]) is a plain `RemoteViews`
/// provider — RemoteViews cannot run Flutter, so everything it can display
/// has to be flattened into simple string values here and written into the
/// `HomeWidgetPreferences` file that the provider reads.
///
/// All calls are fire-and-forget and fully guarded: a widget is a nice-to-have,
/// so a platform-channel failure must never break sending care.
class HomeWidgetService {
  const HomeWidgetService._();

  /// Must match the provider class name registered in the Android manifest.
  static const String providerName = 'TapCareWidgetProvider';

  /// Keeps the last pushed snapshot so we can skip redundant native writes.
  static String? _lastPayload;

  /// Writes the latest couple data and asks Android to redraw every
  /// placed instance of the widget.
  static Future<void> syncFrom(AppState state) async {
    try {
      final me = state.profile;
      final pair = state.pair;
      final stats = state.stats;
      final latest = state.nudges.isEmpty ? null : state.nudges.first;

      final latestIsMine =
          latest != null && latest.senderId == (me?.id ?? 'u_local');

      final payload = <String, String>{
        'partner_name': pair?.partnerName ?? 'Buddy',
        'partner_emoji': pair?.partnerEmoji ?? '💛',
        'my_name': me?.displayName ?? 'You',
        'my_emoji': me?.avatarEmoji ?? '💗',
        'love_meter': '${stats.loveMeter.round()}',
        'streak': '${stats.streakDays}',
        'sent': '${stats.mine}',
        'received': '${stats.theirs}',
        'together': stats.togetherLabel('en'),
        'latest_emoji': _emojiFor(latest),
        'latest_text': latest?.message ?? '',
        'latest_from': _fromLabel(latestIsMine, me, pair),
        'latest_time': _relativeTime(latest?.createdAt),
        'has_nudge': latest == null ? '0' : '1',
        'unseen': stats.unseenCount > 0 ? '1' : '0',
        'quote': _quoteOfDay(),
      };

      final signature = payload.entries
          .map((MapEntry<String, String> e) => '${e.key}=${e.value}')
          .join('|');
      if (signature == _lastPayload) return;
      _lastPayload = signature;

      for (final MapEntry<String, String> e in payload.entries) {
        await HomeWidget.saveWidgetData<String>(e.key, e.value);
      }
      await HomeWidget.updateWidget(name: providerName);
    } catch (_) {
      // A home-screen widget must never be able to break the app.
    }
  }

  /// Emoji that represents the nudge on the widget card.
  static String _emojiFor(Nudge? n) {
    if (n == null) return '💗';
    switch (n.theme) {
      case 'mint':
        return '🌿';
      case 'sky':
        return '🌤️';
      case 'night':
        return '🌙';
      default:
        return '💛';
    }
  }

  static String _fromLabel(bool isMine, AppUser? me, Pairing? pair) {
    if (me == null && pair == null) return 'TapCare';
    return isMine
        ? (me?.displayName ?? 'You')
        : (pair?.partnerName ?? 'Buddy');
  }

  static String _relativeTime(DateTime? at) {
    if (at == null) return '';
    final d = DateTime.now().difference(at);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  static String _quoteOfDay() {
    final d = DateTime.now();
    final quote = RomanceContent.quotes[(d.day + d.month) %
        RomanceContent.quotes.length];
    return quote['en'] ?? '';
  }
}
