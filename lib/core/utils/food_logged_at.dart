/// Timestamp for a food/water/activity row on the selected nutrition day.
abstract final class FoodLoggedAt {
  /// Keeps the entry on [day]'s local calendar date.
  /// Today uses the current clock; other days reuse the current time-of-day.
  static DateTime forSelectedDay(DateTime day, {DateTime? now}) {
    final n = now ?? DateTime.now();
    return DateTime(
      day.year,
      day.month,
      day.day,
      n.hour,
      n.minute,
      n.second,
      n.millisecond,
    );
  }
}
