/// Configuración del feed social (publicaciones efímeras).
abstract final class SocialFeed {
  static const maxAge = Duration(hours: 24);

  static const feedTypes = [
    'workout_completed',
    'milestone_unlocked',
    'level_up',
    'pr_unlocked',
  ];

  static DateTime cutoffSince([DateTime? now]) {
    return (now ?? DateTime.now()).toUtc().subtract(maxAge);
  }
}
