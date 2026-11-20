/// Avisos que el usuario puede apagar. Todos vienen activos.
enum NotificationKind {
  restEnd,
  friendRequests,
  comments,
  routines,
  friendActivity;

  static NotificationKind? forSocialType(String? type) {
    return switch (type) {
      'friend_request' => NotificationKind.friendRequests,
      'feed_comment' ||
      'feed_reaction' ||
      'feed_comment_reaction' =>
        NotificationKind.comments,
      'routine_share' || 'trainer_request' => NotificationKind.routines,
      'workout_completed' ||
      'milestone_unlocked' ||
      'level_up' ||
      'pr_unlocked' ||
      'user_post' =>
        NotificationKind.friendActivity,
      _ => null,
    };
  }
}

class NotificationSettings {
  const NotificationSettings({
    this.restEnd = true,
    this.friendRequests = true,
    this.comments = true,
    this.routines = true,
    this.friendActivity = true,
  });

  final bool restEnd;
  final bool friendRequests;
  final bool comments;
  final bool routines;
  final bool friendActivity;

  static const restEndColumn = 'rest_end';
  static const friendRequestsColumn = 'friend_requests';
  static const commentsColumn = 'comments';
  static const routinesColumn = 'routines';
  static const friendActivityColumn = 'friend_activity';

  bool allows(NotificationKind kind) {
    return switch (kind) {
      NotificationKind.restEnd => restEnd,
      NotificationKind.friendRequests => friendRequests,
      NotificationKind.comments => comments,
      NotificationKind.routines => routines,
      NotificationKind.friendActivity => friendActivity,
    };
  }

  bool allowsSocialType(String? type) {
    final kind = NotificationKind.forSocialType(type);
    if (kind == null) return false;
    return allows(kind);
  }

  NotificationSettings copyWith({
    bool? restEnd,
    bool? friendRequests,
    bool? comments,
    bool? routines,
    bool? friendActivity,
  }) {
    return NotificationSettings(
      restEnd: restEnd ?? this.restEnd,
      friendRequests: friendRequests ?? this.friendRequests,
      comments: comments ?? this.comments,
      routines: routines ?? this.routines,
      friendActivity: friendActivity ?? this.friendActivity,
    );
  }

  factory NotificationSettings.fromRow(Map<String, dynamic> row) {
    bool flag(String key) => row[key] is bool ? row[key] as bool : true;
    return NotificationSettings(
      restEnd: flag(restEndColumn),
      friendRequests: flag(friendRequestsColumn),
      comments: flag(commentsColumn),
      routines: flag(routinesColumn),
      friendActivity: flag(friendActivityColumn),
    );
  }

  Map<String, dynamic> toRow(String userId) {
    return {
      'user_id': userId,
      restEndColumn: restEnd,
      friendRequestsColumn: friendRequests,
      commentsColumn: comments,
      routinesColumn: routines,
      friendActivityColumn: friendActivity,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
