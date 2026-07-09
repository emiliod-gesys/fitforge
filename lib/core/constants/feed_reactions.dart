/// Reacciones permitidas en publicaciones del feed (máx. 5).
abstract final class FeedReactions {
  static const emojis = ['💪', '🔥', '👏', '🏆', '❤️'];

  static bool isAllowed(String emoji) => emojis.contains(emoji);
}
