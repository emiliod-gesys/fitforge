import 'routine.dart';

/// Una rutina generada por el coach con estado de guardado/descarte independiente.
class CoachRoutineSlot {
  const CoachRoutineSlot({
    required this.routine,
    this.isSaved = false,
    this.isDiscarded = false,
  });

  final Routine routine;
  final bool isSaved;
  final bool isDiscarded;

  bool get isActive => !isSaved && !isDiscarded;

  CoachRoutineSlot copyWith({
    Routine? routine,
    bool? isSaved,
    bool? isDiscarded,
  }) {
    return CoachRoutineSlot(
      routine: routine ?? this.routine,
      isSaved: isSaved ?? this.isSaved,
      isDiscarded: isDiscarded ?? this.isDiscarded,
    );
  }
}
