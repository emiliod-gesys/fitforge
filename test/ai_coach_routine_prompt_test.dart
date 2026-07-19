import 'package:fitforge/core/utils/ai_coach_routine_prompt.dart';
import 'package:fitforge/models/exercise.dart';
import 'package:fitforge/services/routine_limit_service.dart';
import 'package:fitforge/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseAvailableEquipment detects dumbbells and ignores full gym', () {
    expect(
      AiCoachRoutinePrompt.parseAvailableEquipment('solo tengo mancuernas en casa'),
      ['dumbbell'],
    );
    expect(
      AiCoachRoutinePrompt.parseAvailableEquipment('tengo acceso a todo el gimnasio'),
      isEmpty,
    );
  });

  test('filterCatalogByEquipment keeps matching exercises only', () {
    const catalog = [
      Exercise(catalogId: 'ff_1', name: 'Dumbbell Curl', equipment: ['Mancuerna']),
      Exercise(catalogId: 'ff_2', name: 'Lat Pulldown', equipment: ['Máquina']),
    ];

    final filtered = AiCoachRoutinePrompt.filterCatalogByEquipment(
      catalog,
      const ['dumbbell'],
    );

    expect(filtered.map((e) => e.id), ['ff_1']);
  });

  test('buildRoutineLimitSection warns when no slots remain', () {
    const status = RoutineLimitStatus(
      used: 10,
      limit: 10,
      tier: SubscriptionTier.free,
    );

    final section = AiCoachRoutinePrompt.buildRoutineLimitSection(
      status: status,
      languageCode: 'es',
    );

    expect(section, contains('Espacios disponibles: 0'));
    expect(section, contains('NO puede guardar'));
  });
}
