import 'app_user.dart';
import 'mood_entry.dart';
import 'nudge.dart';
import 'pairing.dart';

/// Purely derived couple statistics — computed from local data, never stored.
///
/// The love meter is a weighted blend of four sub-scores so it is always
/// explainable and never punishes you for showing up:
///   * **Care given** (30%) — how much *you* initiate. Sending can only raise it.
///   * **Balance**      (30%) — how even the care is between both people.
///   * **Rhythm**       (20%) — streak of consecutive days with a nudge.
///   * **Acknowledged** (20%) — share of *received* nudges you actually opened.
///
/// Acknowledgement deliberately ignores nudges **you** sent: you never "see"
/// your own nudge, so counting them used to dilute the score every time the
/// user sent care — which made the percentage drop on every send.
class CoupleStats {
  const CoupleStats({
    required this.togetherDays,
    required this.totalNudges,
    required this.mine,
    required this.theirs,
    required this.seenCount,
    required this.unseenCount,
    required this.receivedSeen,
    required this.streakDays,
    required this.loveMeter,
    required this.careScore,
    required this.balanceScore,
    required this.rhythmScore,
    required this.ackScore,
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

  /// Received nudges the user actually opened. Only *their* nudges can be
  /// acknowledged — your own nudges are acknowledged by your partner.
  final int receivedSeen;
  final int streakDays;
  final double loveMeter; // 0..100

  /// Sub-scores, each 0..1, shown as a breakdown in "Your story".
  final double careScore;
  final double balanceScore;
  final double rhythmScore;
  final double ackScore;

  final DateTime? lastNudgeAt;
  final String? lastMoodEmoji;
  final int? daysToAnniversary;

  /// Share of all nudges that you sent, 0..1. Used by the love-balance bar.
  /// Never clamps — 8 sent and 2 received renders as 80/20, not 50/50.
  double get mineShare => totalNudges == 0 ? 0.5 : mine / totalNudges;
  double get theirsShare => totalNudges == 0 ? 0.5 : 1 - mineShare;

  /// Flex weights for the balance bar. A side with zero nudges still gets a
  /// thin sliver so the bar never collapses to a single flat colour.
  int get mineFlex {
    if (totalNudges == 0) return 1;
    if (mine == 0) return 1;
    return (mine * 1000) ~/ totalNudges;
  }

  int get theirsFlex {
    if (totalNudges == 0) return 1;
    if (theirs == 0) return 1;
    return (theirs * 1000) ~/ totalNudges;
  }

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

  /// Short explanation of what is holding the meter back right now.
  String meterHint(String lang) {
    if (theirs == 0) {
      return lang == 'hi'
          ? 'पार्टनर से कोई नज़ मिले तो पैमाना और चढ़ेगा।'
          : 'Once your partner nudges back, the meter climbs further.';
    }
    if (ackScore < 0.99) {
      return lang == 'hi'
          ? 'आए हुए नज़ देख लो — प्यार पहचाना सबसे बड़ा कदम है।'
          : 'Open the nudges you receive — seeing them counts for a lot.';
    }
    if (balanceScore < 0.7) {
      return lang == 'hi'
          ? 'दोनों थोड़ा-थोड़ा भेजो, पैमाना बराबर होगा।'
          : 'A nudge each way keeps the balance even.';
    }
    return lang == 'hi'
        ? 'सब ठीक चल रहा है — ऐसे ही बनाए रखो! 💛'
        : 'Everything is flowing — keep it up! 💛';
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
    var receivedSeen = 0;
    DateTime? last;
    for (final Nudge n in nudges) {
      if (n.senderId == myId) {
        mine++;
      } else {
        theirs++;
        if (n.seen) receivedSeen++;
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

    // ---- love meter: four transparent sub-scores ----
    final total = mine + theirs;

    // How much care you personally show up with. Sending always raises this.
    final care = (mine / 10).clamp(0.0, 1.0);

    // How even the care is between the two of you.
    final balance =
        total == 0 ? 0.0 : (2 * (mine < theirs ? mine : theirs) / total);

    // Daily rhythm.
    final rhythm = (streak / 7).clamp(0.0, 1.0);

    // Do you actually open what arrives? (received nudges only)
    final ack = theirs == 0 ? 0.0 : receivedSeen / theirs;

    final meter = (care * 0.30 +
            balance * 0.30 +
            rhythm * 0.20 +
            ack * 0.20) *
        100;

    int? daysToAnniversary;
    if (anniversary != null) {
      var next = DateTime(now.year, anniversary.month, anniversary.day);
      if (next.isBefore(DateTime(now.year, now.month, now.day))) {
        next = DateTime(now.year + 1, anniversary.month, anniversary.day);
      }
      daysToAnniversary =
          next.difference(DateTime(now.year, now.month, now.day)).inDays;
    }

    return CoupleStats(
      togetherDays: togetherDays,
      totalNudges: nudges.length,
      mine: mine,
      theirs: theirs,
      seenCount: seen,
      unseenCount: nudges.length - seen,
      receivedSeen: receivedSeen,
      streakDays: streak,
      loveMeter: meter.clamp(0.0, 100.0),
      careScore: care,
      balanceScore: balance,
      rhythmScore: rhythm,
      ackScore: ack,
      lastNudgeAt: last,
      lastMoodEmoji: moods.isEmpty ? null : moods.first.emoji,
      daysToAnniversary: daysToAnniversary,
    );
  }
}
