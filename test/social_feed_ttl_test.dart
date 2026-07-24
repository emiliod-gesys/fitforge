import 'package:fitforge/core/constants/social_feed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feed cutoff is 24 hours before now', () {
    final now = DateTime.utc(2026, 7, 9, 18, 0);
    final cutoff = SocialFeed.cutoffSince(now);

    expect(cutoff, DateTime.utc(2026, 7, 8, 18, 0));
    expect(now.difference(cutoff), SocialFeed.maxAge);
  });

  test('feed types include social events and user posts', () {
    expect(SocialFeed.feedTypes, contains('pr_unlocked'));
    expect(SocialFeed.feedTypes, contains('user_post'));
    expect(SocialFeed.feedTypes, isNot(contains('trainer_request')));
  });

  test('bell types include actionable social notifications only', () {
    expect(SocialFeed.bellTypes, containsAll([
      'friend_request',
      'feed_comment',
      'feed_reaction',
      'feed_comment_reaction',
      'routine_share',
      'trainer_request',
    ]));
    expect(SocialFeed.bellTypes, isNot(contains('workout_completed')));
    expect(SocialFeed.bellTypes, isNot(contains('user_post')));
  });
}
