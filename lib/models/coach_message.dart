import 'coach_routine_slot.dart';
import 'routine.dart';

class CoachMessage {
  final String? text;
  final Routine? routinePreview;
  final List<CoachRoutineSlot>? routineSlots;
  final bool isUser;
  final bool isError;
  final bool isRoutineSaved;
  final bool isRoutineDiscarded;

  CoachMessage({
    this.text,
    this.routinePreview,
    this.routineSlots,
    this.isUser = false,
    this.isError = false,
    this.isRoutineSaved = false,
    this.isRoutineDiscarded = false,
  }) : assert(
          text != null ||
              routinePreview != null ||
              (routineSlots != null && routineSlots.isNotEmpty),
        );

  List<CoachRoutineSlot> get allRoutineSlots {
    if (routineSlots != null && routineSlots!.isNotEmpty) return routineSlots!;
    if (routinePreview != null) {
      return [
        CoachRoutineSlot(
          routine: routinePreview!,
          isSaved: isRoutineSaved,
          isDiscarded: isRoutineDiscarded,
        ),
      ];
    }
    return const [];
  }

  bool get hasRoutinePreviews => allRoutineSlots.isNotEmpty;

  bool get hasActiveRoutinePreview => allRoutineSlots.any((slot) => slot.isActive);

  CoachMessage copyWith({
    String? text,
    Routine? routinePreview,
    List<CoachRoutineSlot>? routineSlots,
    bool? isUser,
    bool? isError,
    bool? isRoutineSaved,
    bool? isRoutineDiscarded,
  }) {
    return CoachMessage(
      text: text ?? this.text,
      routinePreview: routinePreview ?? this.routinePreview,
      routineSlots: routineSlots ?? this.routineSlots,
      isUser: isUser ?? this.isUser,
      isError: isError ?? this.isError,
      isRoutineSaved: isRoutineSaved ?? this.isRoutineSaved,
      isRoutineDiscarded: isRoutineDiscarded ?? this.isRoutineDiscarded,
    );
  }

  CoachMessage withSlotAt(int index, CoachRoutineSlot slot) {
    final slots = List<CoachRoutineSlot>.from(allRoutineSlots);
    if (index < 0 || index >= slots.length) return this;
    slots[index] = slot;
    return copyWith(routineSlots: slots, routinePreview: null);
  }
}
