/// Configuración del feed social (publicaciones efímeras).
abstract final class SocialFeed {
  static const maxAge = Duration(hours: 24);

  static const feedTypes = [
    'workout_completed',
    'milestone_unlocked',
    'level_up',
    'pr_unlocked',
    'user_post',
  ];

  /// Tipos que aparecen en la campana de notificaciones (no en el feed).
  static const bellTypes = [
    'friend_request',
    'feed_comment',
    'feed_reaction',
    'feed_comment_reaction',
    'routine_share',
    'trainer_request',
  ];

  static const maxPostLength = 150;

  static const maxCommentLength = 300;

  static DateTime cutoffSince([DateTime? now]) {
    return (now ?? DateTime.now()).toUtc().subtract(maxAge);
  }
}
