import '../models/routine.dart';

class CoachMessage {
  final String? text;
  final Routine? routinePreview;
  final bool isUser;
  final bool isError;
  final bool isRoutineSaved;
  final bool isRoutineDiscarded;

  const CoachMessage({
    this.text,
    this.routinePreview,
    this.isUser = false,
    this.isError = false,
    this.isRoutineSaved = false,
    this.isRoutineDiscarded = false,
  }) : assert(text != null || routinePreview != null);

  bool get hasActiveRoutinePreview =>
      routinePreview != null && !isRoutineSaved && !isRoutineDiscarded;

  CoachMessage copyWith({
    String? text,
    Routine? routinePreview,
    bool? isUser,
    bool? isError,
    bool? isRoutineSaved,
    bool? isRoutineDiscarded,
  }) {
    return CoachMessage(
      text: text ?? this.text,
      routinePreview: routinePreview ?? this.routinePreview,
      isUser: isUser ?? this.isUser,
      isError: isError ?? this.isError,
      isRoutineSaved: isRoutineSaved ?? this.isRoutineSaved,
      isRoutineDiscarded: isRoutineDiscarded ?? this.isRoutineDiscarded,
    );
  }
}
