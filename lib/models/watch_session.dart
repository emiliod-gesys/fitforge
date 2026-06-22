import 'dart:convert';

/// Snapshot of the active workout sent to the watch companion.
class WatchWorkoutSnapshot {
  const WatchWorkoutSnapshot({
    required this.workoutId,
    required this.exerciseId,
    required this.exerciseName,
    required this.setId,
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.unitSystem,
    required this.isCardio,
    this.restEndsAtEpochMs,
    this.restTotalSeconds,
    required this.updatedAtEpochMs,
  });

  final String workoutId;
  final String exerciseId;
  final String exerciseName;
  final String setId;
  final int setNumber;
  final double? weight;
  final int reps;
  final String unitSystem;
  final bool isCardio;
  final int? restEndsAtEpochMs;
  final int? restTotalSeconds;
  final int updatedAtEpochMs;

  bool get restActive =>
      restEndsAtEpochMs != null &&
      restEndsAtEpochMs! > DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'workoutId': workoutId,
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'setId': setId,
        'setNumber': setNumber,
        'weight': weight,
        'reps': reps,
        'unitSystem': unitSystem,
        'isCardio': isCardio,
        'restEndsAtEpochMs': restEndsAtEpochMs,
        'restTotalSeconds': restTotalSeconds,
        'updatedAtEpochMs': updatedAtEpochMs,
      };

  factory WatchWorkoutSnapshot.fromJson(Map<String, dynamic> json) {
    return WatchWorkoutSnapshot(
      workoutId: json['workoutId'] as String,
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      setId: json['setId'] as String,
      setNumber: json['setNumber'] as int? ?? 1,
      weight: (json['weight'] as num?)?.toDouble(),
      reps: json['reps'] as int? ?? 0,
      unitSystem: json['unitSystem'] as String? ?? 'kg',
      isCardio: json['isCardio'] as bool? ?? false,
      restEndsAtEpochMs: json['restEndsAtEpochMs'] as int?,
      restTotalSeconds: json['restTotalSeconds'] as int?,
      updatedAtEpochMs: json['updatedAtEpochMs'] as int? ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  String encode() => jsonEncode(toJson());

  static WatchWorkoutSnapshot? decode(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return WatchWorkoutSnapshot.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}

enum WatchActionType {
  completeSet,
  skipRest,
  adjustRest,
  updateSet,
}

class WatchWorkoutAction {
  const WatchWorkoutAction({
    required this.type,
    this.deltaSeconds,
    this.weight,
    this.reps,
  });

  final WatchActionType type;
  final int? deltaSeconds;
  final double? weight;
  final int? reps;

  Map<String, dynamic> toJson() {
    return {
      'type': switch (type) {
        WatchActionType.completeSet => 'complete_set',
        WatchActionType.skipRest => 'skip_rest',
        WatchActionType.adjustRest => 'adjust_rest',
        WatchActionType.updateSet => 'update_set',
      },
      if (deltaSeconds != null) 'deltaSeconds': deltaSeconds,
      if (weight != null) 'weight': weight,
      if (reps != null) 'reps': reps,
    };
  }

  factory WatchWorkoutAction.fromJson(Map<String, dynamic> json) {
    final typeRaw = json['type'] as String? ?? '';
    final type = switch (typeRaw) {
      'complete_set' => WatchActionType.completeSet,
      'skip_rest' => WatchActionType.skipRest,
      'adjust_rest' => WatchActionType.adjustRest,
      'update_set' => WatchActionType.updateSet,
      _ => WatchActionType.completeSet,
    };
    return WatchWorkoutAction(
      type: type,
      deltaSeconds: json['deltaSeconds'] as int?,
      weight: (json['weight'] as num?)?.toDouble(),
      reps: json['reps'] as int?,
    );
  }

  static WatchWorkoutAction? decode(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return WatchWorkoutAction.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
