import 'package:flutter_test/flutter_test.dart';
import 'package:tapcare/models/bear_mood.dart';
import 'package:tapcare/widgets/bear_rig.dart';

/// The bears are meant to behave like living cartoons, not like a particle
/// effect. These lock the behaviours down as maths that can be asserted.
void main() {
  /// Sample a pose across the whole loop.
  List<RigPose> sweep({
    required BearEmotion emotion,
    bool speaking = false,
    double talk = 0.8,
    int partnerSide = 1,
  }) =>
      List<RigPose>.generate(
        200,
        (int i) => RigAnimator.pose(
          t: i / 200,
          emotion: emotion,
          speaking: speaking,
          talk: talk,
          partnerSide: partnerSide,
        ),
      );

  group('the bears live', () {
    test('they walk — the walk reaches both ends of the lane', () {
      final poses = sweep(emotion: BearEmotion.happy);

      final double furthest = poses
          .map((RigPose p) => p.walkT)
          .reduce((double a, double b) => a > b ? a : b);
      final double nearest = poses
          .map((RigPose p) => p.walkT)
          .reduce((double a, double b) => a < b ? a : b);

      expect(furthest, greaterThan(0.95), reason: 'must reach the far end');
      expect(nearest, lessThan(0.05), reason: 'must come back to the start');
    });

    test('they turn around instead of teleporting', () {
      final poses = sweep(emotion: BearEmotion.calm);

      // At the far end the character walks back the other way.
      final RigPose endOfLane = poses.firstWhere(
        (RigPose p) => p.walkT > 0.9,
      );
      expect(endOfLane.facingRight, isTrue);

      final int flips = _directionChanges(poses);
      expect(flips, greaterThanOrEqualTo(1), reason: 'must turn around');
    });

    test('they blink', () {
      expect(RigAnimator.isBlinking(0.0), isTrue);
      expect(RigAnimator.isBlinking(0.1), isFalse);

      final poses = sweep(emotion: BearEmotion.happy);
      final int blinks =
          poses.where((RigPose p) => p.eyesClosed).length;
      expect(blinks, greaterThan(0), reason: 'eyes must close sometimes');
      // …and stay open most of the time.
      expect(blinks, lessThan(poses.length ~/ 3));
    });

    test('a tap makes them open their mouth', () {
      final quiet = sweep(emotion: BearEmotion.calm);
      expect(quiet.any((RigPose p) => p.mouthOpen), isFalse);

      final talking = sweep(emotion: BearEmotion.calm, speaking: true);
      expect(talking.any((RigPose p) => p.mouthOpen), isTrue);
    });

    test('the head turns, and it turns towards the partner', () {
      final lookingRight = RigAnimator.pose(
        t: 0.25,
        emotion: BearEmotion.calm,
        partnerSide: 1,
      );
      final lookingLeft = RigAnimator.pose(
        t: 0.25,
        emotion: BearEmotion.calm,
        partnerSide: -1,
      );

      expect(lookingRight.headDx, greaterThan(0));
      expect(lookingLeft.headDx, lessThan(0));
      expect(lookingRight.headAngle.abs(), greaterThan(0.0),
          reason: 'the neck must actually move');
    });

    test('they are never perfectly still', () {
      for (final BearEmotion emotion in BearEmotion.values) {
        final poses = sweep(emotion: emotion);
        final double travel = poses
            .map((RigPose p) => p.bob)
            .reduce((double a, double b) => a > b ? a : b) -
            poses.map((RigPose p) => p.bob)
                .reduce((double a, double b) => a < b ? a : b);
        expect(travel, greaterThan(0.5),
            reason: '$emotion should bob while moving');
      }
    });
  });

  group('the mood changes how they hold themselves', () {
    test('sad hangs the head and dims them', () {
      final sad = RigAnimator.pose(t: 0.2, emotion: BearEmotion.sad);
      final happy = RigAnimator.pose(t: 0.2, emotion: BearEmotion.happy);

      expect(sad.headDy, greaterThan(happy.headDy));
      expect(sad.headAngle, lessThan(happy.headAngle));
      expect(sad.opacity, lessThan(1.0));
      expect(sad.scale, lessThan(happy.scale));
    });

    test('loving leans towards the partner', () {
      final toRight = RigAnimator.pose(
        t: 0.4,
        emotion: BearEmotion.loving,
        partnerSide: 1,
      );
      final toLeft = RigAnimator.pose(
        t: 0.4,
        emotion: BearEmotion.loving,
        partnerSide: -1,
      );

      expect(toRight.headDx, greaterThan(0));
      expect(toLeft.headDx, lessThan(0));
      expect(toRight.headAngle, greaterThan(toLeft.headAngle));
    });

    test('angry shakes instead of walking calmly', () {
      final angry = sweep(emotion: BearEmotion.angry);
      final calm = sweep(emotion: BearEmotion.calm);

      double spread(List<RigPose> poses) => poses
              .map((RigPose p) => p.bodyAngle)
              .reduce((double a, double b) => a > b ? a : b) -
          poses
              .map((RigPose p) => p.bodyAngle)
              .reduce((double a, double b) => a < b ? a : b);

      expect(spread(angry), greaterThan(spread(calm)));
    });

    test('every traverse count is whole, so the walk never jumps', () {
      for (final BearEmotion emotion in BearEmotion.values) {
        expect(
          RigAnimator.traversesPerLoop(emotion) % 1,
          0,
          reason: '$emotion must walk a whole number of times per loop',
        );
      }
    });
  });

  group('sanity', () {
    test('the loop closes: t = 1 looks like t = 0', () {
      for (final BearEmotion emotion in BearEmotion.values) {
        final RigPose start = RigAnimator.pose(t: 0, emotion: emotion);
        final RigPose end = RigAnimator.pose(t: 1, emotion: emotion);
        expect(end.walkT, closeTo(start.walkT, 0.0001),
            reason: '$emotion walk must be continuous across the loop');
        expect(end.facingRight, start.facingRight);
      }
    });

    test('poses are finite — no NaN ever reaches the transform stack', () {
      for (final BearEmotion emotion in BearEmotion.values) {
        for (int i = 0; i < 40; i++) {
          final RigPose p =
              RigAnimator.pose(t: i / 40, emotion: emotion, speaking: true);
          expect(p.bob.isFinite, isTrue);
          expect(p.bodyAngle.isFinite, isTrue);
          expect(p.headAngle.isFinite, isTrue);
          expect(p.headDx.isFinite, isTrue);
          expect(p.headDy.isFinite, isTrue);
          expect(p.scale.isFinite, isTrue);
          expect(p.opacity.isFinite, isTrue);
        }
      }
    });
  });
}

int _directionChanges(List<RigPose> poses) {
  int changes = 0;
  for (int i = 1; i < poses.length; i++) {
    if (poses[i].facingRight != poses[i - 1].facingRight) changes++;
  }
  return changes;
}