import 'package:flutter_test/flutter_test.dart';
import 'package:fitforge/core/utils/workout_suggestion_context.dart';
import 'package:fitforge/models/exercise.dart';
import 'package:fitforge/models/exercise_history.dart';
import 'package:fitforge/models/exercise_logging.dart';
import 'package:fitforge/models/profile.dart';
import 'package:fitforge/models/workout.dart';

void main() {
  group('WorkoutSuggestionContextBuilder', () {
    test('includes latest session summary and recent top set', () {
      final context = WorkoutSuggestionContextBuilder.build(
        exercises: const [
          WorkoutExercise(
            id: 'we-1',
            exerciseId: 'bench',
            exerciseName: 'Barbell Bench Press',
            orderIndex: 0,
            sets: [
              WorkoutSet(
                id: 's1',
                setNumber: 1,
                weight: 30,
                reps: 10,
                loggingType: ExerciseLoggingType.strength,
              ),
            ],
          ),
        ],
        profile: UserProfile(id: 'u1', createdAt: DateTime(2026, 1, 1)),
        muscleRecovery: const {'chest': 92},
        catalog: const <Exercise>[],
        historyByExerciseId: {
          'bench': [
            ExerciseSessionHistory(
              workoutId: 'w1',
              workoutName: 'Push A',
              date: DateTime(2026, 6, 28),
              sets: const [
                WorkoutSet(
                  id: 'a',
                  setNumber: 1,
                  weight: 25,
                  reps: 12,
                  loggingType: ExerciseLoggingType.strength,
                ),
                WorkoutSet(
                  id: 'b',
                  setNumber: 2,
                  weight: 30,
                  reps: 10,
                  rir: 2,
                  loggingType: ExerciseLoggingType.strength,
                ),
              ],
            ),
            ExerciseSessionHistory(
              workoutId: 'w0',
              workoutName: 'Push Prev',
              date: DateTime(2026, 6, 20),
              sets: const [
                WorkoutSet(
                  id: 'c',
                  setNumber: 1,
                  weight: 32.5,
                  reps: 8,
                  rir: 1,
                  loggingType: ExerciseLoggingType.strength,
                ),
              ],
            ),
          ],
        },
      ).single;

      expect(context.latestSessionSummary, isNotNull);
      expect(context.latestSessionSummary!['heaviest_weight_kg'], 30.0);
      expect(context.latestSessionSummary!['top_reps_at_heaviest'], 10);

      expect(context.recentTopSet, isNotNull);
      expect(context.recentTopSet!['weight_kg'], 32.5);
      expect(context.recentTopSet!['reps'], 8);
      expect(context.recentTopSet!['rir'], 1);
    });
  });

  group('AiWorkoutSuggestionsMerger', () {
    test('applies AI weight and reps to matching sets', () {
      const exercises = [
        WorkoutExercise(
          id: 'we1',
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          orderIndex: 0,
          sets: [
            WorkoutSet(id: 's1', setNumber: 1, weight: 70, reps: 10),
            WorkoutSet(id: 's2', setNumber: 2, weight: 70, reps: 10),
          ],
        ),
      ];

      const suggestions = AiWorkoutSuggestions(byExerciseId: {
        'bench': [
          AiExerciseSetSuggestion(setNumber: 1, weightKg: 75, reps: 8),
          AiExerciseSetSuggestion(setNumber: 2, weightKg: 75, reps: 8),
        ],
      });

      final merged = AiWorkoutSuggestionsMerger.apply(
        exercises: exercises,
        suggestions: suggestions,
      );

      expect(merged.first.sets[0].weight, 75);
      expect(merged.first.sets[0].reps, 8);
      expect(merged.first.sets[1].weight, 75);
    });

    test('adds sets when AI suggests more than routine template', () {
      const exercises = [
        WorkoutExercise(
          id: 'we1',
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          orderIndex: 0,
          sets: [
            WorkoutSet(id: 's1', setNumber: 1, weight: 70, reps: 10),
            WorkoutSet(id: 's2', setNumber: 2, weight: 70, reps: 10),
          ],
        ),
      ];

      const suggestions = AiWorkoutSuggestions(byExerciseId: {
        'bench': [
          AiExerciseSetSuggestion(setNumber: 1, weightKg: 75, reps: 8),
          AiExerciseSetSuggestion(setNumber: 2, weightKg: 75, reps: 8),
          AiExerciseSetSuggestion(setNumber: 3, weightKg: 72.5, reps: 8),
          AiExerciseSetSuggestion(setNumber: 4, weightKg: 70, reps: 8),
        ],
      });

      final merged = AiWorkoutSuggestionsMerger.apply(
        exercises: exercises,
        suggestions: suggestions,
      );

      expect(merged.first.sets, hasLength(4));
      expect(merged.first.sets.last.weight, 70);
    });

    test('removes sets when AI suggests fewer than routine template', () {
      const exercises = [
        WorkoutExercise(
          id: 'we1',
          exerciseId: 'squat',
          exerciseName: 'Squat',
          orderIndex: 0,
          sets: [
            WorkoutSet(id: 's1', setNumber: 1, weight: 100, reps: 5),
            WorkoutSet(id: 's2', setNumber: 2, weight: 100, reps: 5),
            WorkoutSet(id: 's3', setNumber: 3, weight: 100, reps: 5),
            WorkoutSet(id: 's4', setNumber: 4, weight: 100, reps: 5),
          ],
        ),
      ];

      const suggestions = AiWorkoutSuggestions(byExerciseId: {
        'squat': [
          AiExerciseSetSuggestion(setNumber: 1, weightKg: 105, reps: 5),
          AiExerciseSetSuggestion(setNumber: 2, weightKg: 105, reps: 5),
        ],
      });

      final merged = AiWorkoutSuggestionsMerger.apply(
        exercises: exercises,
        suggestions: suggestions,
      );

      expect(merged.first.sets, hasLength(2));
      expect(merged.first.sets.first.weight, 105);
    });

    test('supports warmup plus working sets up to 10', () {
      const exercises = [
        WorkoutExercise(
          id: 'we1',
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          orderIndex: 0,
          sets: [
            WorkoutSet(id: 's1', setNumber: 1, weight: 70, reps: 10),
            WorkoutSet(id: 's2', setNumber: 2, weight: 70, reps: 10),
            WorkoutSet(id: 's3', setNumber: 3, weight: 70, reps: 10),
          ],
        ),
      ];

      const suggestions = AiWorkoutSuggestions(byExerciseId: {
        'bench': [
          AiExerciseSetSuggestion(setNumber: 1, weightKg: 40, reps: 10),
          AiExerciseSetSuggestion(setNumber: 2, weightKg: 55, reps: 6),
          AiExerciseSetSuggestion(setNumber: 3, weightKg: 70, reps: 5),
          AiExerciseSetSuggestion(setNumber: 4, weightKg: 75, reps: 5),
          AiExerciseSetSuggestion(setNumber: 5, weightKg: 75, reps: 5),
        ],
      });

      final merged = AiWorkoutSuggestionsMerger.apply(
        exercises: exercises,
        suggestions: suggestions,
      );

      expect(merged.first.sets, hasLength(5));
      expect(merged.first.sets.first.weight, 40);
      expect(merged.first.sets.first.reps, 10);
      expect(merged.first.sets.last.weight, 75);
    });
  });

  group('AiWorkoutSuggestionsParser', () {
    test('parses valid JSON response', () {
      const raw = '''
{"exercises":[{"exercise_id":"bench","sets":[{"set_number":1,"weight_kg":80,"reps":10}]}]}
''';
      final parsed = AiWorkoutSuggestionsParser.parse(raw);
      expect(parsed, isNotNull);
      expect(parsed!.byExerciseId['bench'], hasLength(1));
      expect(parsed.byExerciseId['bench']!.first.weightKg, 80);
    });
  });
}
