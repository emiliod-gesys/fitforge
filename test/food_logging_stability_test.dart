import 'package:fitforge/core/router/food_route_extra.dart';
import 'package:fitforge/core/utils/food_logged_at.dart';
import 'package:fitforge/core/utils/json_parsing.dart';
import 'package:fitforge/core/utils/supabase_datetime.dart';
import 'package:fitforge/models/food_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('foodRouteExtraMap', () {
    test('accepts Map<String, Object> from route extras', () {
      final extra = <String, Object>{
        'meal': MealType.lunch,
        'day': DateTime(2026, 9, 11),
      };
      final parsed = foodRouteExtraMap(extra);
      expect(parsed, isNotNull);
      expect(parsed!['meal'], MealType.lunch);
    });

    test('returns null when extra is missing', () {
      expect(foodRouteExtraMap(null), isNull);
    });
  });

  group('FoodLoggedAt', () {
    test('keeps the selected calendar day with current clock', () {
      final now = DateTime(2026, 9, 11, 21, 40, 15);
      final logged = FoodLoggedAt.forSelectedDay(DateTime(2026, 9, 10), now: now);
      expect(logged.year, 2026);
      expect(logged.month, 9);
      expect(logged.day, 10);
      expect(logged.hour, 21);
      expect(logged.minute, 40);
    });
  });

  group('FoodEntry.fromJson', () {
    test('parses timestamptz without zone as UTC', () {
      final entry = FoodEntry.fromJson({
        'id': '1',
        'user_id': 'u',
        'logged_at': '2026-09-11T06:00:00',
        'meal_type': 'lunch',
        'name': 'Huevos',
        'calories_kcal': 250.0,
        'protein_g': 20,
        'carbs_g': 2,
        'fat_g': 18,
      });
      expect(entry.loggedAt.isUtc, isTrue);
      expect(entry.loggedAt, DateTime.utc(2026, 9, 11, 6));
      expect(entry.caloriesKcal, 250);
    });
  });

  group('parseJsonInt', () {
    test('accepts double calories from json', () {
      expect(parseJsonInt(250.0), 250);
    });
  });

  group('SupabaseDateTime', () {
    test('treats naive iso as utc', () {
      expect(
        SupabaseDateTime.parse('2026-09-10T22:00:00'),
        DateTime.utc(2026, 9, 10, 22),
      );
    });
  });
}
