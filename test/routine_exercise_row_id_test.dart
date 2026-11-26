import 'package:fitforge/services/routine_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('coach draft ids are replaced before insert', () {
    final id = routineExerciseRowId(
      'draft-0-ff_legs_bulgarian_split_squat',
      create: () => '11111111-1111-4111-8111-111111111111',
    );

    expect(id, '11111111-1111-4111-8111-111111111111');
  });

  test('a saved exercise id is kept', () {
    const saved = '22222222-2222-4222-8222-222222222222';
    expect(routineExerciseRowId(saved, create: () => 'nope'), saved);
  });
}
