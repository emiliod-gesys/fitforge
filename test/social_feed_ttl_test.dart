import 'package:fitforge/core/constants/social_feed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feed cutoff is 24 hours before now', () {
    final now = DateTime.utc(2026, 7, 9, 18, 0);
    final cutoff = SocialFeed.cutoffSince(now);

    expect(cutoff, DateTime.utc(2026, 7, 8, 18, 0));
    expect(now.difference(cutoff), SocialFeed.maxAge);
  });

  test('feed types include passive social events only', () {
    expect(SocialFeed.feedTypes, contains('pr_unlocked'));
    expect(SocialFeed.feedTypes, isNot(contains('trainer_request')));
  });
}
