import 'mood_entry.dart';
import 'nudge.dart';

/// How a cartoon bear pair is feeling, derived from real app activity.
///
/// Deliberately *not* stored: it is recomputed from the nudge list and the
/// personal mood check-in, so it can never drift out of sync with the data.
enum BearEmotion {
  /// Everything is quiet for a long time — the bears are missing each other.
  sad,

  /// Nothing is happening, but it is not broken either.
  sulky,

  /// Steady, low-key warmth.
  calm,

  /// Plenty of recent activity from both sides.
  happy,

  /// Recent activity *both ways* — the good state.
  loving,

  /// Care was sent and then ignored.
  angry,
}

/// One frame of "what is the mood between us right now".
class BearMoodReport {
  const BearMoodReport({
    required this.paired,
    required this.pair,
    required this.mine,
    required this.theirs,
    required this.hoursSinceLast,
    required this.pendingFromThem,
  });

  /// No partner yet — a single bear, waiting.
  const BearMoodReport.solo()
      : paired = false,
        pair = BearEmotion.sad,
        mine = BearEmotion.sad,
        theirs = BearEmotion.sad,
        hoursSinceLast = null,
        pendingFromThem = 0;

  final bool paired;

  /// The shared mood — drives which artwork and movement the pair shows.
  final BearEmotion pair;

  /// Mood of *your* bear.
  final BearEmotion mine;

  /// Mood of the partner's bear.
  final BearEmotion theirs;

  /// Null when no nudge has ever been exchanged.
  final int? hoursSinceLast;

  /// Nudges the partner sent that you have not opened yet.
  final int pendingFromThem;
}

/// Pure analysis of "the mood between us" — no I/O, fully unit-testable.
class BearMoodEngine {
  BearMoodEngine._();

  /// Recency of the last nudge of any kind, as a 0..1 score.
  ///
  /// 1.0 = something happened within the last 6 hours, 0.1 = over a week.
  static double recencyScore(int? hours) {
    if (hours == null) return 0.0;
    if (hours < 6) return 1.0;
    if (hours < 24) return 0.85;
    if (hours < 48) return 0.7;
    if (hours < 96) return 0.45;
    if (hours < 168) return 0.25;
    return 0.1;
  }

  /// Valence of a mood-check-in emoji: >0 happy, 0 neutral, <0 heavy.
  static int moodValence(String? emoji) {
    if (emoji == null || emoji.isEmpty) return 0;
    switch (emoji) {
      case '🥰':
      case '😍':
      case '😊':
      case '🥳':
      case '😌':
        return 1;
      case '😔':
      case '🤒':
        return -1;
      case '😤':
        return -2;
      default:
        return 0;
    }
  }

  /// Reads the nudge history and returns the emotion for both bears.
  ///
  /// [myId] is the local user id — nudges sent by anybody else are treated as
  /// the partner's.
  static BearMoodReport analyze({
    required List<Nudge> nudges,
    required String myId,
    required bool paired,
    List<MoodEntry> moods = const <MoodEntry>[],
    DateTime? now,
  }) {
    if (!paired && nudges.isEmpty) return const BearMoodReport.solo();

    final at = now ?? DateTime.now();

    var mineCount = 0;
    var theirsCount = 0;
    var pending = 0;
    DateTime? lastMine;
    DateTime? lastTheirs;
    DateTime? lastAny;

    for (final Nudge n in nudges) {
      if (n.senderId == myId) {
        mineCount++;
        if (lastMine == null || n.createdAt.isAfter(lastMine)) {
          lastMine = n.createdAt;
        }
      } else {
        theirsCount++;
        if (!n.seen) pending++;
        if (lastTheirs == null || n.createdAt.isAfter(lastTheirs)) {
          lastTheirs = n.createdAt;
        }
      }
      if (lastAny == null || n.createdAt.isAfter(lastAny)) {
        lastAny = n.createdAt;
      }
    }

    final hours = lastAny == null ? null : at.difference(lastAny).inHours;
    final hoursSinceMine = lastMine == null ? null : at.difference(lastMine).inHours;
    final hoursSinceTheirs =
        lastTheirs == null ? null : at.difference(lastTheirs).inHours;

    final total = mineCount + theirsCount;
    final recency = recencyScore(hours);
    final balance =
        total == 0 ? 0.5 : (2 * (mineCount < theirsCount ? mineCount : theirsCount) / total);

    // ---- the shared mood ----
    BearEmotion pair;
    if (!paired) {
      // Nothing has ever been exchanged and there is no partner.
      pair = BearEmotion.sad;
    } else if (pending >= 2) {
      // They reached out twice and it was never opened.
      pair = BearEmotion.angry;
    } else if (recency >= 0.85 && balance >= 0.4 && total > 1) {
      pair = BearEmotion.loving;
    } else if (recency >= 0.7) {
      pair = BearEmotion.happy;
    } else if (recency >= 0.45) {
      pair = BearEmotion.calm;
    } else if (recency >= 0.2) {
      pair = BearEmotion.sulky;
    } else {
      pair = BearEmotion.sad;
    }

    // A heavy personal check-in can pull the pair mood down one step.
    final valence = moodValence(moods.isEmpty ? null : moods.first.emoji);
    if (valence <= -2) {
      pair = BearEmotion.angry;
    } else if (valence <= -1 &&
        (pair == BearEmotion.loving ||
            pair == BearEmotion.happy ||
            pair == BearEmotion.calm)) {
      pair = BearEmotion.sulky;
    }

    // ---- your bear ----
    BearEmotion mine;
    if (pending >= 2) {
      mine = BearEmotion.angry;
    } else if (!paired) {
      mine = BearEmotion.sad;
    } else if (mineCount == 0 && theirsCount > 0) {
      // They keep showing up, you never do.
      mine = BearEmotion.sulky;
    } else if (hoursSinceMine != null && hoursSinceMine >= 72) {
      // You have gone quiet as well.
      mine = BearEmotion.sulky;
    } else if (hoursSinceTheirs != null && hoursSinceTheirs >= 72) {
      // Partner has been quiet for days.
      mine = BearEmotion.sad;
    } else if (recency >= 0.85) {
      mine = BearEmotion.happy;
    } else if (recency >= 0.5) {
      mine = BearEmotion.calm;
    } else {
      mine = BearEmotion.sulky;
    }

    // ---- the partner's bear (inferred) ----
    BearEmotion theirs;
    if (hoursSinceTheirs == null) {
      theirs = BearEmotion.sad; // never heard from them
    } else if (hoursSinceTheirs >= 72) {
      theirs = BearEmotion.sulky;
    } else if (pending > 0) {
      theirs = BearEmotion.calm; // they said something, you have not answered
    } else if (recency >= 0.7) {
      theirs = BearEmotion.happy;
    } else {
      theirs = BearEmotion.calm;
    }

    return BearMoodReport(
      paired: paired,
      pair: pair,
      mine: mine,
      theirs: theirs,
      hoursSinceLast: hours,
      pendingFromThem: pending,
    );
  }
}