import '../core/constants/feed_reactions.dart';
import 'social.dart';

class FeedReactionRow {
  final String notificationId;
  final String userId;
  final String emoji;

  const FeedReactionRow({
    required this.notificationId,
    required this.userId,
    required this.emoji,
  });

  factory FeedReactionRow.fromJson(Map<String, dynamic> json) {
    return FeedReactionRow(
      notificationId: json['notification_id'] as String,
      userId: json['user_id'] as String,
      emoji: json['emoji'] as String,
    );
  }
}

class FeedReactionSummary {
  final Map<String, int> counts;
  final String? myEmoji;

  const FeedReactionSummary({
    this.counts = const {},
    this.myEmoji,
  });

  static const empty = FeedReactionSummary();

  bool get hasAny => counts.values.any((c) => c > 0);

  List<MapEntry<String, int>> get sortedEntries {
    final entries = counts.entries.where((e) => e.value > 0).toList();
    entries.sort((a, b) {
      final orderA = FeedReactions.emojis.indexOf(a.key);
      final orderB = FeedReactions.emojis.indexOf(b.key);
      return orderA.compareTo(orderB);
    });
    return entries;
  }

  static Map<String, FeedReactionSummary> aggregate(
    List<FeedReactionRow> rows, {
    required String? currentUserId,
  }) {
    final grouped = <String, List<FeedReactionRow>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.notificationId, () => []).add(row);
    }

    return {
      for (final entry in grouped.entries)
        entry.key: _summaryFor(entry.value, currentUserId: currentUserId),
    };
  }

  static FeedReactionSummary _summaryFor(
    List<FeedReactionRow> rows, {
    required String? currentUserId,
  }) {
    final counts = <String, int>{};
    String? myEmoji;

    for (final row in rows) {
      counts[row.emoji] = (counts[row.emoji] ?? 0) + 1;
      if (currentUserId != null && row.userId == currentUserId) {
        myEmoji = row.emoji;
      }
    }

    return FeedReactionSummary(counts: counts, myEmoji: myEmoji);
  }
}

class FeedPost {
  final SocialNotification notification;
  final FeedReactionSummary reactions;

  const FeedPost({
    required this.notification,
    required this.reactions,
  });
}
