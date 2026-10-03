import 'package:flutter_test/flutter_test.dart';
import 'package:tapcare/models/bear_mood.dart';
import 'package:tapcare/models/mood_entry.dart';
import 'package:tapcare/models/nudge.dart';

/// Locks in the rules the Milk & Mocha bears react to.
///
/// The brief: quiet for a long time → sad, more than usual → happy, care that
/// is ignored → angry, and love only when care actually moves *both* ways
/// recently.
void main() {
  final now = DateTime(2026, 3, 14, 18);

  Nudge nudge(
    String id, {
    required bool mine,
    bool seen = true,
    Duration ago = const Duration(hours: 1),
  }) =>
      Nudge(
        id: id,
        pairId: 'p_1',
        senderId: mine ? 'u_me' : 'u_partner',
        message: 'Drink water',
        theme: 'peach',
        sound: 'soft_chime',
        createdAt: now.subtract(ago),
        seenAt: seen ? now : null,
      );

  BearMoodReport read(
    List<Nudge> nudges, {
    bool paired = true,
    List<MoodEntry> moods = const <MoodEntry>[],
  }) =>
      BearMoodEngine.analyze(
        nudges: nudges,
        myId: 'u_me',
        paired: paired,
        moods: moods,
        now: now,
      );

  group('bear mood', () {
    test('no partner and no nudges = waiting, not an error', () {
      final report = read(<Nudge>[], paired: false);

      expect(report.paired, isFalse);
      expect(report.pair, BearEmotion.sad);
      expect(report.hoursSinceLast, isNull);
    });

    test('care moving both ways just now = loving', () {
      final report = read(<Nudge>[
        nudge('m1', mine: true),
        nudge('m2', mine: true),
        nudge('t1', mine: false),
        nudge('t2', mine: false),
      ]);

      expect(report.pair, BearEmotion.loving);
      expect(report.mine, BearEmotion.happy);
      expect(report.theirs, BearEmotion.happy);
    });

    test('nothing for days = the bears miss each other', () {
      final report = read(<Nudge>[
        nudge('m1', mine: true, ago: const Duration(days: 9)),
        nudge('t1', mine: false, ago: const Duration(days: 10)),
      ]);

      expect(report.pair, BearEmotion.sad);
      expect(report.mine, BearEmotion.sulky);
      expect(report.hoursSinceLast, greaterThan(168));
    });

    test('a few days of silence = sulky, not sad', () {
      final report = read(<Nudge>[
        nudge('m1', mine: true, ago: const Duration(hours: 100)),
        nudge('t1', mine: false, ago: const Duration(hours: 104)),
      ]);

      expect(report.pair, BearEmotion.sulky);
    });

    test('activity only from you = happy, partner bear waits', () {
      final report = read(<Nudge>[
        nudge('m1', mine: true),
        nudge('m2', mine: true),
        nudge('m3', mine: true),
      ]);

      expect(report.mine, BearEmotion.happy);
      expect(report.theirs, BearEmotion.sad);
    });

    test('two unopened nudges = angry, whoever ignored them', () {
      final report = read(<Nudge>[
        nudge('m1', mine: true),
        nudge('t1', mine: false, seen: false),
        nudge('t2', mine: false, seen: false),
      ]);

      expect(report.pendingFromThem, 2);
      expect(report.pair, BearEmotion.angry);
      expect(report.mine, BearEmotion.angry);
    });

    test('a heavy personal check-in pulls the pair mood down', () {
      final good = read(<Nudge>[
        nudge('m1', mine: true),
        nudge('t1', mine: false),
        nudge('t2', mine: false),
      ]);
      expect(good.pair, BearEmotion.loving);

      final upset = read(
        <Nudge>[
          nudge('m1', mine: true),
          nudge('t1', mine: false),
          nudge('t2', mine: false),
        ],
        moods: <MoodEntry>[MoodEntry(emoji: '😤', at: now)],
      );
      expect(upset.pair, BearEmotion.angry);
    });

    test('a happy check-in never turns a quiet couple into lovers', () {
      final report = read(
        <Nudge>[nudge('m1', mine: true, ago: const Duration(days: 8))],
        moods: <MoodEntry>[MoodEntry(emoji: '🥰', at: now)],
      );

      expect(report.pair, BearEmotion.sad);
    });

    test('recency score is monotonic and bounded', () {
      expect(BearMoodEngine.recencyScore(null), 0.0);
      expect(BearMoodEngine.recencyScore(0), 1.0);
      expect(BearMoodEngine.recencyScore(30), greaterThan(0.5));
      expect(BearMoodEngine.recencyScore(72), lessThan(0.5));
      expect(BearMoodEngine.recencyScore(9999), greaterThanOrEqualTo(0.0));
      expect(
        BearMoodEngine.recencyScore(3),
        greaterThan(BearMoodEngine.recencyScore(30)),
      );
    });
  });
}