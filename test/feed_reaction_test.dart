import 'package:fitforge/core/constants/feed_reactions.dart';
import 'package:fitforge/models/feed_reaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allows exactly five fitness-themed emojis', () {
    expect(FeedReactions.emojis, ['💪', '🔥', '👏', '🏆', '❤️']);
    expect(FeedReactions.emojis.length, 5);
  });

  test('aggregates reaction counts and tracks current user emoji', () {
    final summary = FeedReactionSummary.aggregate(
      const [
        FeedReactionRow(notificationId: 'n1', userId: 'u1', emoji: '💪'),
        FeedReactionRow(notificationId: 'n1', userId: 'u2', emoji: '🔥'),
        FeedReactionRow(notificationId: 'n1', userId: 'u3', emoji: '💪'),
      ],
      currentUserId: 'u2',
    )['n1']!;

    expect(summary.counts['💪'], 2);
    expect(summary.counts['🔥'], 1);
    expect(summary.myEmoji, '🔥');
    expect(summary.sortedEntries.first.key, '💪');
  });
}
