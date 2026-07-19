import 'package:fitforge/core/utils/ai_coach_catalog.dart';
import 'package:fitforge/models/exercise.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('musclesToQuery falls back to main groups when empty', () {
    expect(
      AiCoachCatalog.musclesToQuery(const []),
      isNot(contains('Cardio')),
    );
    expect(
      AiCoachCatalog.musclesToQuery(const ['Pecho']),
      ['Pecho'],
    );
  });

  test('mergeBundledAndCloud keeps cloud exercises matching target muscles', () {
    const bundled = [
      Exercise(catalogId: 'ff_1', name: 'Bench Press', category: 'Pecho', muscles: ['Pectoral']),
    ];
    const cloud = [
      Exercise(catalogId: 'ext_1', name: 'Cable Fly', category: 'Pecho', muscles: ['Pectoral']),
      Exercise(catalogId: 'ext_2', name: 'Row', category: 'Espalda', muscles: ['Dorsal']),
    ];

    final merged = AiCoachCatalog.mergeBundledAndCloud(
      bundled: bundled,
      cloud: cloud,
      targetMuscles: const ['Pecho'],
    );

    expect(merged.map((e) => e.id), ['ff_1', 'ext_1']);
  });
}
