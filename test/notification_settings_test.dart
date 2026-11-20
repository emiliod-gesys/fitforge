import 'package:fitforge/models/notification_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notifications are on unless a flag is false', () {
    const settings = NotificationSettings();

    expect(settings.restEnd, isTrue);
    expect(settings.allowsSocialType('friend_request'), isTrue);
    expect(settings.allowsSocialType('workout_completed'), isTrue);
    expect(settings.allowsSocialType('user_post'), isTrue);
    expect(settings.allowsSocialType('unknown_event'), isFalse);
  });

  test('each switch only mutes its own events', () {
    const settings = NotificationSettings(
      friendRequests: false,
      comments: false,
      routines: false,
      friendActivity: false,
    );

    expect(settings.allowsSocialType('friend_request'), isFalse);
    expect(settings.allowsSocialType('feed_comment'), isFalse);
    expect(settings.allowsSocialType('feed_reaction'), isFalse);
    expect(settings.allowsSocialType('routine_share'), isFalse);
    expect(settings.allowsSocialType('trainer_request'), isFalse);
    expect(settings.allowsSocialType('pr_unlocked'), isFalse);
    expect(settings.restEnd, isTrue);
  });

  test('a missing server flag stays enabled', () {
    final settings = NotificationSettings.fromRow(const {
      'friend_requests': false,
    });

    expect(settings.friendRequests, isFalse);
    expect(settings.comments, isTrue);
    expect(settings.friendActivity, isTrue);
    expect(settings.restEnd, isTrue);
  });
}
