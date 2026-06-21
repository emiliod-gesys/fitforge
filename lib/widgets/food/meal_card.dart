import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/food_entry.dart';

class MealCard extends StatelessWidget {
  final MealType mealType;
  final String title;
  final String emoji;
  final int eatenKcal;
  final int goalKcal;
  final List<FoodEntry> entries;
  final VoidCallback onAdd;

  const MealCard({
    super.key,
    required this.mealType,
    required this.title,
    required this.emoji,
    required this.eatenKcal,
    required this.goalKcal,
    required this.entries,
    required this.onAdd,
  });

  String _preview() {
    if (entries.isEmpty) return '';
    return entries
        .take(3)
        .map((e) => '${e.name} (${e.caloriesKcal} kcal)')
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          '$eatenKcal / $goalKcal kcal',
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.orange,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onAdd,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
