import 'package:fitforge/core/constants/social_feed.dart';
import 'package:fitforge/models/feed_comment.dart';
import 'package:fitforge/models/feed_reaction.dart';
import 'package:fitforge/models/social.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses post_id from notification metadata', () {
    final notification = SocialNotification.fromJson({
      'id': 'n1',
      'actor_id': 'u1',
      'type': 'user_post',
      'message': 'Hello',
      'metadata': {
        'post_id': 'post-123',
        'text': 'Hello',
      },
      'created_at': '2026-07-09T12:00:00Z',
    });

    expect(notification.feedPostId, 'post-123');
    expect(notification.isFeedItem, isTrue);
  });

  test('FeedComment parses from json', () {
    final comment = FeedComment.fromJson({
      'id': 'c1',
      'post_id': 'post-123',
      'user_id': 'u2',
      'body': 'Nice work!',
      'created_at': '2026-07-09T12:05:00Z',
    });

    expect(comment.body, 'Nice work!');
    expect(comment.postId, 'post-123');
  });

  test('aggregates comment reaction counts', () {
    final summary = FeedReactionSummary.aggregateComments(
      const [
        FeedCommentReactionRow(commentId: 'c1', userId: 'u1', emoji: '🔥'),
        FeedCommentReactionRow(commentId: 'c1', userId: 'u2', emoji: '👏'),
      ],
      currentUserId: 'u1',
    )['c1']!;

    expect(summary.counts['🔥'], 1);
    expect(summary.counts['👏'], 1);
    expect(summary.myEmoji, '🔥');
  });
}
