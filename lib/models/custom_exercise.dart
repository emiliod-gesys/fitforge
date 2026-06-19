import 'exercise.dart';
import 'exercise_logging.dart';

/// Estado de sincronización (futuro sync opcional a Supabase).
enum CustomExerciseSyncState {
  local,
  pendingUpload,
  synced,
}

/// Ejercicio creado por el usuario, almacenado en el dispositivo.
class CustomExercise {
  static const idPrefix = 'custom:';
  static const maxPerUser = 100;

  final String id;
  final String name;
  final List<String> muscles;
  final String? category;
  final String? localImagePath;
  /// Si true, el peso registrado es por brazo/mancuerna (volumen ×2 salvo unilateral).
  final bool perArmWeight;
  final ExerciseLoggingType loggingType;
  final CardioLoggingConfig cardioConfig;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final CustomExerciseSyncState syncState;

  CustomExercise({
    required this.id,
    required this.name,
    required this.muscles,
    this.category,
    this.localImagePath,
    this.perArmWeight = false,
    this.loggingType = ExerciseLoggingType.strength,
    CardioLoggingConfig? cardioConfig,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncState = CustomExerciseSyncState.local,
  }) : cardioConfig = cardioConfig ?? CardioLoggingConfig.fromPreset(CardioPreset.treadmill);

  bool get isCardio => loggingType == ExerciseLoggingType.cardio;

  String get exerciseId => '$idPrefix$id';

  bool get isDeleted => deletedAt != null;

  Exercise toExercise() {
    return Exercise(
      supabaseId: id,
      name: name,
      category: category ?? _inferCategory(muscles),
      muscles: muscles,
      imageUrl: localImagePath,
      isCustom: true,
      isUserCustom: true,
      perArmWeight: perArmWeight,
      loggingType: loggingType,
      cardioConfig: isCardio ? cardioConfig : null,
    );
  }

  static String _inferCategory(List<String> muscles) {
    if (muscles.isEmpty) return 'Otros';
    return muscles.first;
  }

  CustomExercise copyWith({
    String? name,
    List<String>? muscles,
    String? category,
    String? localImagePath,
    bool? perArmWeight,
    ExerciseLoggingType? loggingType,
    CardioLoggingConfig? cardioConfig,
    DateTime? updatedAt,
    DateTime? deletedAt,
    CustomExerciseSyncState? syncState,
  }) {
    return CustomExercise(
      id: id,
      name: name ?? this.name,
      muscles: muscles ?? this.muscles,
      category: category ?? this.category,
      localImagePath: localImagePath ?? this.localImagePath,
      perArmWeight: perArmWeight ?? this.perArmWeight,
      loggingType: loggingType ?? this.loggingType,
      cardioConfig: cardioConfig ?? this.cardioConfig,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncState: syncState ?? this.syncState,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'muscles': muscles,
        if (category != null) 'category': category,
        if (localImagePath != null) 'local_image_path': localImagePath,
        'per_arm_weight': perArmWeight,
        'logging_type': loggingType.toJson(),
        'cardio_metrics': cardioConfig.toJsonList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
        'sync_state': syncState.name,
      };

  factory CustomExercise.fromJson(Map<String, dynamic> json) {
    return CustomExercise(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      muscles: List<String>.from(json['muscles'] ?? []),
      category: json['category'] as String?,
      localImagePath: json['local_image_path'] as String?,
      perArmWeight: json['per_arm_weight'] as bool? ?? false,
      loggingType: ExerciseLoggingType.fromJson(json['logging_type'] as String?),
      cardioConfig: CardioLoggingConfig.fromJson(json['cardio_metrics'] as List?),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      syncState: CustomExerciseSyncState.values.firstWhere(
        (s) => s.name == json['sync_state'],
        orElse: () => CustomExerciseSyncState.local,
      ),
    );
  }
}
