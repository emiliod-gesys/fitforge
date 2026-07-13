import 'package:fitforge/core/utils/exercise_load.dart';
import 'package:fitforge/models/exercise_logging.dart';
import 'package:fitforge/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('farmers walk volume uses meters as rep equivalents', () {
    const set = WorkoutSet(
      id: '1',
      setNumber: 1,
      weight: 24,
      reps: 0,
      distanceMeters: 40,
      completed: true,
    );

    final volume = ExerciseLoad.setVolumeKg(
      set,
      exerciseName: "Farmer's Walk",
      perArmWeight: true,
      loadMode: ExerciseLoadMode.loadedDistance,
    );

    // 24 kg per arm × 40 m × 2 arms = 1920 kg
    expect(volume, 1920);
  });
}
