import 'package:fitforge/models/social.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses milestone metadata from notification', () {
    final notification = SocialNotification.fromJson({
      'id': 'n1',
      'actor_id': 'u2',
      'type': 'milestone_unlocked',
      'message': 'fallback',
      'metadata': {'category': 'reps', 'tier': 3},
      'created_at': '2026-07-09T12:00:00Z',
    });

    expect(notification.isMilestoneUnlock, isTrue);
    expect(notification.milestoneCategory?.name, 'reps');
    expect(notification.milestoneTier, 3);
    expect(notification.isFeedItem, isTrue);
  });

  test('parses level up metadata from notification', () {
    final notification = SocialNotification.fromJson({
      'id': 'n2',
      'actor_id': 'u2',
      'type': 'level_up',
      'message': 'fallback',
      'metadata': {'level': 42},
      'created_at': '2026-07-09T12:00:00Z',
    });

    expect(notification.isLevelUp, isTrue);
    expect(notification.levelReached, 42);
  });

  test('parses personal record metadata from notification', () {
    final notification = SocialNotification.fromJson({
      'id': 'n3',
      'actor_id': 'u2',
      'type': 'pr_unlocked',
      'message': 'fallback',
      'metadata': {
        'exercise_id': 'bench_press',
        'exercise_name': 'Bench Press',
        'record_type': 'strength',
        'weight_kg': 100,
        'reps': 5,
      },
      'created_at': '2026-07-09T12:00:00Z',
    });

    expect(notification.isPrUnlock, isTrue);
    expect(notification.isFeedItem, isTrue);
    expect(notification.isOwnPost('u2'), isTrue);
    expect(notification.isOwnPost('u1'), isFalse);
    final pr = notification.feedPersonalRecord;
    expect(pr, isNotNull);
    expect(pr!.exerciseId, 'bench_press');
    expect(pr.exerciseName, 'Bench Press');
    expect(pr.weight, 100);
    expect(pr.reps, 5);
  });
}
