import 'package:fitforge/services/ai_coach_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('routine intents', () {
    test('save intent does not trigger creation', () {
      expect(AiCoachService.isRoutineSaveIntent('guarda la rutina'), isTrue);
      expect(AiCoachService.isRoutineCreationRequest('guarda la rutina'), isFalse);
    });

    test('create intent still works', () {
      expect(AiCoachService.isRoutineCreationRequest('crea una rutina de piernas'), isTrue);
      expect(AiCoachService.isRoutineSaveIntent('crea una rutina de piernas'), isFalse);
    });

    test('create and save requests auto-save only', () {
      expect(AiCoachService.requestsRoutineAutoSave('crea una rutina y guardala'), isTrue);
      expect(AiCoachService.isRoutineSaveIntent('crea una rutina y guardala'), isFalse);
      expect(AiCoachService.isRoutineCreationRequest('crea una rutina y guardala'), isTrue);
    });
  });
}
