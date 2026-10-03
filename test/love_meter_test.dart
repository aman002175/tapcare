import 'package:flutter_test/flutter_test.dart';
import 'package:tapcare/models/app_user.dart';
import 'package:tapcare/models/couple_stats.dart';
import 'package:tapcare/models/nudge.dart';
import 'package:tapcare/models/pairing.dart';

/// Regression tests for the reported love-meter bugs:
///
///  1. The balance bar rendered 50/50 no matter the real ratio, because it
///     used `flex: (stats.mine * 100).clamp(1, 100)` — both sides saturated
///     at 100 for any count above 1.
///  2. The percentage visibly *dropped* when sending care, because the
///     acknowledgement score divided seen nudges by ALL nudges — including
///     the ones you sent, which you can never "see". Every send diluted it.
void main() {
  final me = AppUser(
    id: 'u_me',
    displayName: 'Aarav',
    avatarEmoji: '🐼',
    createdAt: DateTime(2026, 1, 1),
  );
  final pair = Pairing(
    id: 'p_1',
    userA: 'u_me',
    userB: 'u_partner',
    partnerName: 'Diya',
    partnerEmoji: '🦊',
    inviteCode: 'K7PXQ2',
    createdAt: DateTime(2026, 1, 1),
  );

  Nudge mine(String id, {int daysAgo = 0}) => Nudge(
        id: id,
        pairId: 'p_1',
        senderId: 'u_me',
        message: 'Drink water',
        theme: 'peach',
        sound: 'soft_chime',
        createdAt: DateTime.now().subtract(Duration(days: daysAgo)),
      );

  Nudge theirs(String id, {bool seen = true, int daysAgo = 0}) => Nudge(
        id: id,
        pairId: 'p_1',
        senderId: 'u_partner',
        message: 'Did you eat?',
        theme: 'peach',
        sound: 'soft_chime',
        createdAt: DateTime.now().subtract(Duration(days: daysAgo)),
        seenAt: seen ? DateTime.now() : null,
      );

  CoupleStats build(List<Nudge> nudges) => CoupleStats.from(
        profile: me,
        pair: pair,
        nudges: nudges,
      );

  group('love meter', () {
    test('8 sent and 2 received is not a 50/50 split', () {
      final stats = build(<Nudge>[
        ...List<Nudge>.generate(8, (int i) => mine('m$i')),
        theirs('t1'),
        theirs('t2'),
      ]);

      expect(stats.mine, 8);
      expect(stats.theirs, 2);
      expect(stats.mineShare, closeTo(0.8, 0.001));
      expect(stats.theirsShare, closeTo(0.2, 0.001));

      // The bar weights must stay proportional — the old clamp made these
      // both 100, which rendered an identical 50/50 bar.
      expect(stats.mineFlex, 800);
      expect(stats.theirsFlex, 200);
      expect(stats.mineFlex, isNot(stats.theirsFlex));
    });

    test('acknowledgement only counts received nudges', () {
      final stats = build(<Nudge>[
        ...List<Nudge>.generate(8, (int i) => mine('m$i')),
        theirs('t1'),
        theirs('t2'),
      ]);

      expect(stats.receivedSeen, 2);
      expect(stats.ackScore, closeTo(1.0, 0.001));
    });

    test('sending another nudge never lowers the meter', () {
      final before = build(<Nudge>[
        ...List<Nudge>.generate(8, (int i) => mine('m$i')),
        theirs('t1'),
        theirs('t2'),
      ]);
      final after = build(<Nudge>[
        ...List<Nudge>.generate(9, (int i) => mine('m$i')),
        theirs('t1'),
        theirs('t2'),
      ]);

      // This is the "percentage kam hone lag gaya" bug from widget mode.
      expect(
        after.loveMeter,
        greaterThan(before.loveMeter),
        reason: 'sending care must never reduce the love meter',
      );
    });

    test('receiving a nudge also raises the meter', () {
      final before = build(<Nudge>[
        ...List<Nudge>.generate(8, (int i) => mine('m$i')),
        theirs('t1'),
        theirs('t2'),
      ]);
      final after = build(<Nudge>[
        ...List<Nudge>.generate(8, (int i) => mine('m$i')),
        theirs('t1'),
        theirs('t2'),
        theirs('t3'),
      ]);

      expect(after.loveMeter, greaterThan(before.loveMeter));
    });

    test('meter sits in a healthy range for real usage', () {
      final stats = build(<Nudge>[
        ...List<Nudge>.generate(8, (int i) => mine('m$i')),
        theirs('t1'),
        theirs('t2'),
      ]);

      // Old formula produced ~20% here and the bar read 50/50.
      expect(stats.loveMeter, greaterThan(50));
      expect(stats.loveMeter, lessThanOrEqualTo(100));
    });

    test('an all-in-one side does not collapse the meter', () {
      final stats = build(<Nudge>[
        ...List<Nudge>.generate(10, (int i) => mine('m$i')),
      ]);

      // You showed up, so you get credit for it even with no reply yet.
      expect(stats.careScore, closeTo(1.0, 0.001));
      expect(stats.loveMeter, greaterThan(25));
    });

    test('a brand new pair starts at zero without dividing by zero', () {
      final stats = build(<Nudge>[]);

      expect(stats.loveMeter, 0);
      expect(stats.mineShare, closeTo(0.5, 0.001));
      expect(stats.mineFlex, 1);
      expect(stats.theirsFlex, 1);
    });
  });
}
