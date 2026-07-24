import 'feed_reaction.dart';
import 'social.dart';

class FeedComment {
  final String id;
  final String postId;
  final String userId;
  final String body;
  final DateTime createdAt;
  final FriendUser? author;
  final FeedReactionSummary reactions;

  const FeedComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.body,
    required this.createdAt,
    this.author,
    this.reactions = FeedReactionSummary.empty,
  });

  factory FeedComment.fromJson(Map<String, dynamic> json) {
    return FeedComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      author: json['author'] != null
          ? FriendUser.fromJson(Map<String, dynamic>.from(json['author'] as Map))
          : null,
    );
  }

  FeedComment copyWithReactions(FeedReactionSummary reactions) {
    return FeedComment(
      id: id,
      postId: postId,
      userId: userId,
      body: body,
      createdAt: createdAt,
      author: author,
      reactions: reactions,
    );
  }
}

class FeedPostDetailData {
  final FeedPost post;
  final List<FeedComment> comments;
  final String? commentPostId;

  const FeedPostDetailData({
    required this.post,
    required this.comments,
    this.commentPostId,
  });

  bool get canComment => commentPostId != null && commentPostId!.isNotEmpty;

  bool canDeletePost(String? currentUserId) =>
      commentPostId != null &&
      currentUserId != null &&
      post.notification.isOwnPost(currentUserId);
}
