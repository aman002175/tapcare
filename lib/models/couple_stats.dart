import 'app_user.dart';
import 'mood_entry.dart';
import 'nudge.dart';
import 'pairing.dart';

/// Purely derived couple statistics — computed from local data, never stored.
class CoupleStats {
  const CoupleStats({
    required this.togetherDays,
    required this.totalNudges,
    required this.mine,
    required this.theirs,
    required this.seenCount,
    required this.unseenCount,
    required this.streakDays,
    required this.loveMeter,
    required this.lastNudgeAt,
    required this.lastMoodEmoji,
    required this.daysToAnniversary,
  });

  final int togetherDays;
  final int totalNudges;
  final int mine;
  final int theirs;
  final int seenCount;
  final int unseenCount;
  final int streakDays;
  final double loveMeter; // 0..100
  final DateTime? lastNudgeAt;
  final String? lastMoodEmoji;
  final int? daysToAnniversary;

  /// "Together" chip label, e.g. "42 days 💞" / "3 months 💞".
  String togetherLabel(String lang) {
    if (togetherDays <= 0) return lang == 'hi' ? 'आज से 💞' : 'Since today 💞';
    if (togetherDays < 30) {
      return '$togetherDays ${lang == 'hi' ? 'दिन' : 'days'} 💞';
    }
    final months = (togetherDays / 30).floor();
    return '$months ${lang == 'hi' ? 'महीने' : 'months'} 💞';
  }

  String meterLabel(String lang) {
    if (loveMeter >= 80) return lang == 'hi' ? 'बहुत प्यार! 🔥' : 'So loved! 🔥';
    if (loveMeter >= 55) return lang == 'hi' ? 'प्यार बढ़ रहा है 🌸' : 'Love is blooming 🌸';
    if (loveMeter >= 30) return lang == 'hi' ? 'अच्छी शुरुआत 💛' : 'A lovely start 💛';
    return lang == 'hi' ? 'नज़ भेजो, प्यार बढ़ेगा 💌' : 'Send a nudge to grow love 💌';
  }

  factory CoupleStats.from({
    required AppUser? profile,
    required Pairing? pair,
    required List<Nudge> nudges,
    List<MoodEntry> moods = const <MoodEntry>[],
    DateTime? anniversary,
  }) {
    final now = DateTime.now();
    final myId = profile?.id ?? 'u_local';

    var mine = 0;
    var theirs = 0;
    var seen = 0;
    DateTime? last;
    for (final Nudge n in nudges) {
      if (n.senderId == myId) {
        mine++;
      } else {
        theirs++;
      }
      if (n.seen) seen++;
      if (last == null || n.createdAt.isAfter(last)) last = n.createdAt;
    }

    // Streak: consecutive days (ending today or yesterday) with a nudge.
    final days = <String>{};
    for (final Nudge n in nudges) {
      days.add('${n.createdAt.year}-${n.createdAt.month}-${n.createdAt.day}');
    }
    var streak = 0;
    var cursor = DateTime(now.year, now.month, now.day);
    if (!days.contains('${cursor.year}-${cursor.month}-${cursor.day}')) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (days.contains('${cursor.year}-${cursor.month}-${cursor.day}')) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final togetherDays = pair == null
        ? 0
        : DateTime.now().difference(pair.createdAt).inDays;

    // Love meter: balance + rhythm + acknowledgement.
    final balance = mine + theirs == 0 ? 0.0 : (1 - (mine - theirs).abs() / (mine + theirs));
    final rhythm = (streak / 7).clamp(0.0, 1.0);
    final ack = nudges.isEmpty ? 0.0 : seen / nudges.length;
    final meter = (balance * 0.4 + rhythm * 0.3 + ack * 0.3) * 100;

    int? daysToAnniversary;
    if (anniversary != null) {
      var next = DateTime(now.year, anniversary.month, anniversary.day);
      if (next.isBefore(DateTime(now.year, now.month, now.day))) {
        next = DateTime(now.year + 1, anniversary.month, anniversary.day);
      }
      daysToAnniversary = next.difference(DateTime(now.year, now.month, now.day)).inDays;
    }

    return CoupleStats(
      togetherDays: togetherDays,
      totalNudges: nudges.length,
      mine: mine,
      theirs: theirs,
      seenCount: seen,
      unseenCount: nudges.length - seen,
      streakDays: streak,
      loveMeter: meter.clamp(0.0, 100.0),
      lastNudgeAt: last,
      lastMoodEmoji: moods.isEmpty ? null : moods.first.emoji,
      daysToAnniversary: daysToAnniversary,
    );
  }
}
