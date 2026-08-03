import 'package:fitforge/l10n/app_localizations.dart';
import 'package:fitforge/widgets/workout_unit_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WorkoutUnitToggle switches between kg and lb', (tester) async {
    var unit = 'kg';

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: WorkoutUnitToggle(
            unitSystem: unit,
            onChanged: (value) => unit = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('kg'), findsOneWidget);
    expect(find.text('lb'), findsOneWidget);

    await tester.tap(find.text('lb'));
    await tester.pumpAndSettle();

    expect(unit, 'lb');
  });
}
