import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';

class FoodWeekStrip extends StatelessWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onChanged;

  const FoodWeekStrip({
    super.key,
    required this.selectedDay,
    required this.onChanged,
  });

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  List<DateTime> get _weekDays {
    final start = _today.subtract(Duration(days: _today.weekday - 1));
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final weekdayFormat = DateFormat('E', locale);
    final dayFormat = DateFormat('d', locale);

    return Row(
      children: _weekDays.map((day) {
        final isSelected = _isSameDay(day, selectedDay);
        final isFuture = day.isAfter(_today);
        final isToday = _isSameDay(day, _today);
        final raw = weekdayFormat.format(day);
        final label = raw.isNotEmpty ? raw[0].toUpperCase() : raw;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isFuture ? null : () => onChanged(day),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.orange : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.orange
                          : isToday
                              ? AppColors.orange.withValues(alpha: 0.45)
                              : AppColors.border.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : isFuture
                                  ? AppColors.textMuted.withValues(alpha: 0.45)
                                  : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayFormat.format(day),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : isFuture
                                  ? AppColors.textMuted.withValues(alpha: 0.45)
                                  : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
