import 'package:fitforge/core/content/fitness_daily_tips.dart';
import 'package:fitforge/l10n/app_localizations.dart';
import 'package:fitforge/l10n/l10n_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FitnessDailyTips', () {
    test('catalog has a large tip pool', () {
      expect(FitnessDailyTips.catalog.length, greaterThanOrEqualTo(80));
    });

    test('every catalog id resolves to localized copy in Spanish and English', () {
      for (final locale in [const Locale('es'), const Locale('en')]) {
        final l10n = lookupAppLocalizations(locale);
        for (final tip in FitnessDailyTips.catalog) {
          final body = l10n.dailyTipBody(tip.id);
          expect(body, isNot(equals(tip.id)), reason: '${locale.languageCode}:${tip.id}');
          expect(body.trim(), isNotEmpty);
        }
      }
    });

    test('tip copy differs by user language', () {
      const tipId = 'general_doms';
      final es = lookupAppLocalizations(const Locale('es')).dailyTipBody(tipId);
      final en = lookupAppLocalizations(const Locale('en')).dailyTipBody(tipId);

      expect(es, isNot(equals(en)));
      expect(es, contains('músculo'));
      expect(en.toLowerCase(), contains('doms'));
    });

    test('pickFor is stable for the same user and day', () {
      const userId = 'user-abc';
      final date = DateTime(2026, 7, 22);

      final a = FitnessDailyTips.pickFor(
        date: date,
        userId: userId,
        fitnessGoal: 'Hipertrofia',
      );
      final b = FitnessDailyTips.pickFor(
        date: date,
        userId: userId,
        fitnessGoal: 'Hipertrofia',
      );

      expect(a.id, b.id);
    });

    test('pickFor prefers goal-specific tips when goal matches', () {
      const userId = 'goal-user';
      final date = DateTime(2026, 1, 1);

      for (var day = 0; day < 40; day++) {
        final tip = FitnessDailyTips.pickFor(
          date: date.add(Duration(days: day)),
          userId: userId,
          fitnessGoal: 'Fuerza',
        );
        expect(tip.goal == null || tip.goal == 'Fuerza', isTrue);
      }
    });

    test('pickFor falls back to general tips for unknown goal', () {
      final tip = FitnessDailyTips.pickFor(
        date: DateTime(2026, 3, 15),
        userId: 'unknown-goal-user',
        fitnessGoal: 'Objetivo raro',
      );

      expect(tip.goal, isNull);
    });
  });
}
