import 'package:fitforge/l10n/app_localizations.dart';
import 'package:fitforge/models/workout.dart';
import 'package:fitforge/models/workout_summary.dart';
import 'package:fitforge/widgets/workout_share_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

WorkoutSummaryData _gymSummary({String? photo}) {
  return WorkoutSummaryData(
    workout: Workout(
      id: 'w1',
      userId: 'u1',
      name: 'Empuje',
      startedAt: DateTime.utc(2026, 11, 19, 18),
      completedAt: DateTime.utc(2026, 11, 19, 19),
    ),
    durationMinutes: 48,
    totalVolumeKg: 8200,
    totalReps: 120,
    maxWeightKg: 80,
    finishPhotoLocalPath: photo,
    exercises: const [
      ExerciseSummaryLine(
        exerciseId: 'e1',
        exerciseName: 'Press banca',
        completedSets: 4,
        totalReps: 32,
      ),
      ExerciseSummaryLine(
        exerciseId: 'e2',
        exerciseName: 'Curl de biceps',
        completedSets: 3,
        totalReps: 30,
      ),
    ],
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('en');
  });

  test('la captura de la historia es 1080x1920', () {
    expect(workoutShareStoryWidth * workoutShareStoryPixelRatio, 1080);
    expect(workoutShareStoryHeight * workoutShareStoryPixelRatio, 1920);
    expect(workoutShareStoryWidth / workoutShareStoryHeight, 9 / 16);
  });

  testWidgets('la tarjeta ocupa siempre una historia 9:16', (tester) async {
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
          body: Builder(
            builder: (context) {
              final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
              if (l10n == null) return const SizedBox.shrink();
              return SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: workoutShareStoryWidth,
                    child: WorkoutShareCard(
                      summary: _gymSummary(),
                      unitSystem: 'metric',
                      l10n: l10n,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(WorkoutShareCard));
    expect(size.width, workoutShareStoryWidth);
    expect(size.height, workoutShareStoryHeight);
    expect(find.text('FORGEN'), findsOneWidget);
    expect(find.text('Empuje'), findsOneWidget);
    expect(find.text('2 ejercicios'), findsOneWidget);
    expect(find.text('Curl de biceps'), findsNothing);
    expect(find.text('Press banca'), findsNothing);
  });

  testWidgets('el lienzo que se comparte mide 360x640 aunque se pinte chico', (tester) async {
    final key = GlobalKey();
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
          body: Builder(
            builder: (context) {
              final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
              if (l10n == null) return const SizedBox.shrink();
              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Transform.scale(
                      scale: 0.2,
                      alignment: Alignment.bottomLeft,
                      child: RepaintBoundary(
                        key: key,
                        child: WorkoutShareStory(
                          summary: _gymSummary(photo: 'missing.jpg'),
                          unitSystem: 'metric',
                          l10n: l10n,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    expect(boundary.size, const Size(workoutShareStoryWidth, workoutShareStoryHeight));
    final image = await boundary.toImage(pixelRatio: workoutShareStoryPixelRatio);
    expect(image.width, 1080);
    expect(image.height, 1920);
    image.dispose();
  });
}
