import 'package:uuid/uuid.dart';

import 'offline_json_file.dart';

enum SyncOperationType {
  startWorkout,
  addExercise,
  logSet,
  deleteSet,
  completeWorkout,
  cancelWorkout,
  saveRunnerSession,
}

class SyncOperation {
  final String id;
  final SyncOperationType type;
  final String workoutId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime occurredAt;
  final int retryCount;
  final String? lastError;

  const SyncOperation({
    required this.id,
    required this.type,
    required this.workoutId,
    required this.payload,
    required this.createdAt,
    required this.occurredAt,
    this.retryCount = 0,
    this.lastError,
  });

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      type: SyncOperationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SyncOperationType.logSet,
      ),
      workoutId: json['workout_id'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      createdAt: DateTime.parse(json['created_at'] as String),
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      retryCount: json['retry_count'] as int? ?? 0,
      lastError: json['last_error'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'workout_id': workoutId,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'occurred_at': occurredAt.toIso8601String(),
        'retry_count': retryCount,
        if (lastError != null) 'last_error': lastError,
      };

  SyncOperation copyWith({
    int? retryCount,
    String? lastError,
  }) {
    return SyncOperation(
      id: id,
      type: type,
      workoutId: workoutId,
      payload: payload,
      createdAt: createdAt,
      occurredAt: occurredAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }
}

/// Cola persistente de operaciones pendientes de subir a Supabase.
class SyncOutbox {
  static const _fileName = 'sync_outbox.json';
  final _uuid = const Uuid();

  Future<List<SyncOperation>> loadAll() async {
    final raw = await OfflineJsonFile.readList(_fileName);
    return raw
        .whereType<Map>()
        .map((e) => SyncOperation.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
  }

  Future<void> enqueue({
    required SyncOperationType type,
    required String workoutId,
    required Map<String, dynamic> payload,
    DateTime? occurredAt,
  }) async {
    final ops = await loadAll();
    ops.add(
      SyncOperation(
        id: _uuid.v4(),
        type: type,
        workoutId: workoutId,
        payload: payload,
        createdAt: DateTime.now().toUtc(),
        occurredAt: (occurredAt ?? DateTime.now()).toUtc(),
      ),
    );
    await OfflineJsonFile.writeList(_fileName, ops.map((o) => o.toJson()).toList());
  }

  Future<void> remove(String operationId) async {
    final ops = await loadAll()..removeWhere((o) => o.id == operationId);
    await OfflineJsonFile.writeList(_fileName, ops.map((o) => o.toJson()).toList());
  }

  Future<void> markFailed(SyncOperation op, Object error) async {
    final ops = await loadAll();
    final index = ops.indexWhere((o) => o.id == op.id);
    if (index < 0) return;
    ops[index] = op.copyWith(
      retryCount: op.retryCount + 1,
      lastError: error.toString(),
    );
    await OfflineJsonFile.writeList(_fileName, ops.map((o) => o.toJson()).toList());
  }

  Future<int> pendingCount() async => (await loadAll()).length;

  /// Entrenamientos distintos con operaciones pendientes (no cada serie suelta).
  Future<int> pendingWorkoutCount() async {
    final ops = await loadAll();
    return ops.map((o) => o.workoutId).toSet().length;
  }

  Future<void> clearWorkout(String workoutId) async {
    final ops = await loadAll()..removeWhere((o) => o.workoutId == workoutId);
    await OfflineJsonFile.writeList(_fileName, ops.map((o) => o.toJson()).toList());
  }
}
