import 'package:fitforge/core/constants/social_feed.dart';
import 'package:fitforge/models/social.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user_post is a feed item with text and image metadata', () {
    final notification = SocialNotification.fromJson({
      'id': 'n4',
      'actor_id': 'u1',
      'type': 'user_post',
      'message': 'Great session today',
      'metadata': {
        'text': 'Great session today',
        'image_path': 'u1/abc.jpg',
        'pr': {
          'exercise_id': 'squat',
          'exercise_name': 'Squat',
          'record_type': 'strength',
          'weight_kg': 120,
          'reps': 5,
        },
      },
      'created_at': '2026-07-09T12:00:00Z',
    });

    expect(notification.isUserPost, isTrue);
    expect(notification.isFeedItem, isTrue);
    expect(notification.feedPostText, 'Great session today');
    expect(notification.feedImagePath, 'u1/abc.jpg');
    expect(notification.feedAttachedPersonalRecord?.exerciseId, 'squat');
  });

  test('SocialFeed includes user_post and post length limit', () {
    expect(SocialFeed.feedTypes, contains('user_post'));
    expect(SocialFeed.maxPostLength, 150);
  });
}
