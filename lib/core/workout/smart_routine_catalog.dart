/// Músculos concretos que se pueden pedir en una rutina inteligente.
class SmartMuscleTarget {
  final String id;
  final String groupEs;
  final String groupEn;
  final String labelEs;
  final String labelEn;

  /// Músculo principal del catálogo, ya normalizado.
  final Set<String> primaryKeys;

  /// Ejercicios de gym, del más habitual al menos habitual.
  final List<String> stapleIds;

  const SmartMuscleTarget({
    required this.id,
    required this.groupEs,
    required this.groupEn,
    required this.labelEs,
    required this.labelEn,
    required this.primaryKeys,
    required this.stapleIds,
  });

  String groupLabel(String languageCode) => languageCode == 'en' ? groupEn : groupEs;

  String label(String languageCode) => languageCode == 'en' ? labelEn : labelEs;
}

abstract final class SmartRoutineCatalog {
  static const targets = <SmartMuscleTarget>[
    SmartMuscleTarget(
      id: 'pecho',
      groupEs: 'Pecho',
      groupEn: 'Chest',
      labelEs: 'Pecho',
      labelEn: 'Chest',
      primaryKeys: {'pecho', 'chest'},
      stapleIds: [
        'ff_chest_barbell_bench_press',
        'ff_chest_dumbbell_bench_press',
        'ff_chest_chest_press_machine',
        'ff_chest_pec_deck_fly_machine',
        'ff_chest_cable_fly',
        'ff_chest_dumbbell_fly',
      ],
    ),
    SmartMuscleTarget(
      id: 'pecho_superior',
      groupEs: 'Pecho',
      groupEn: 'Chest',
      labelEs: 'Pecho superior',
      labelEn: 'Upper chest',
      primaryKeys: {'pecho superior', 'upper chest'},
      stapleIds: [
        'ff_chest_incline_barbell_bench_press',
        'ff_chest_incline_dumbbell_bench_press',
        'ff_chest_incline_chest_press_machine',
        'ff_chest_low_to_high_cable_fly',
      ],
    ),
    SmartMuscleTarget(
      id: 'pecho_inferior',
      groupEs: 'Pecho',
      groupEn: 'Chest',
      labelEs: 'Pecho inferior',
      labelEn: 'Lower chest',
      primaryKeys: {'pecho inferior', 'lower chest'},
      stapleIds: [
        'ff_chest_decline_barbell_bench_press',
        'ff_chest_decline_dumbbell_bench_press',
        'ff_chest_decline_chest_press_machine',
        'ff_chest_high_to_low_cable_fly',
      ],
    ),
    SmartMuscleTarget(
      id: 'dorsales',
      groupEs: 'Espalda',
      groupEn: 'Back',
      labelEs: 'Dorsales',
      labelEn: 'Lats',
      primaryKeys: {'dorsales', 'lats'},
      stapleIds: [
        'ff_back_lat_pulldown_machine',
        'ff_back_lat_pulldown_classic',
        'ff_back_pull_up',
        'ff_back_seated_cable_row',
        'ff_back_barbell_row',
        'ff_back_single_arm_dumbbell_row',
      ],
    ),
    SmartMuscleTarget(
      id: 'espalda_alta',
      groupEs: 'Espalda',
      groupEn: 'Back',
      labelEs: 'Espalda alta',
      labelEn: 'Upper back',
      primaryKeys: {'espalda alta', 'upper back'},
      stapleIds: [
        'ff_back_chest_supported_row_machine',
        'ff_back_chest_supported_dumbbell_row',
        'ff_back_barbell_incline_row',
        'ff_back_dumbbell_incline_row',
        'ff_back_barbell_shrug',
        'ff_back_dumbbell_shrug',
      ],
    ),
    SmartMuscleTarget(
      id: 'deltoides_anterior',
      groupEs: 'Hombros',
      groupEn: 'Shoulders',
      labelEs: 'Deltoides anterior',
      labelEn: 'Front delts',
      primaryKeys: {'deltoides anterior', 'front delts'},
      stapleIds: [
        'ff_shoulders_dumbbell_shoulder_press',
        'ff_shoulders_shoulder_press_machine',
        'ff_shoulders_barbell_overhead_press',
        'ff_shoulders_seated_barbell_overhead_press',
      ],
    ),
    SmartMuscleTarget(
      id: 'deltoides_lateral',
      groupEs: 'Hombros',
      groupEn: 'Shoulders',
      labelEs: 'Deltoides lateral',
      labelEn: 'Side delts',
      primaryKeys: {'deltoides lateral', 'side delts'},
      stapleIds: [
        'ff_shoulders_dumbbell_lateral_raise',
        'ff_shoulders_machine_lateral_raise',
        'ff_shoulders_cable_lateral_raise',
      ],
    ),
    SmartMuscleTarget(
      id: 'deltoides_posterior',
      groupEs: 'Hombros',
      groupEn: 'Shoulders',
      labelEs: 'Deltoides posterior',
      labelEn: 'Rear delts',
      primaryKeys: {'deltoides posterior', 'rear delts'},
      stapleIds: [
        'ff_shoulders_rear_delt_dumbbell_fly',
        'ff_shoulders_face_pull',
        'ff_shoulders_cable_rear_delt_fly',
      ],
    ),
    SmartMuscleTarget(
      id: 'biceps',
      groupEs: 'Brazos',
      groupEn: 'Arms',
      labelEs: 'Bíceps',
      labelEn: 'Biceps',
      primaryKeys: {'biceps', 'braquial', 'brachialis'},
      stapleIds: [
        'ff_biceps_dumbbell_curl',
        'ff_biceps_barbell_curl',
        'ff_biceps_ez_bar_curl',
        'ff_biceps_cable_curl',
        'ff_biceps_hammer_curl',
        'ff_biceps_preacher_curl_machine',
      ],
    ),
    SmartMuscleTarget(
      id: 'triceps',
      groupEs: 'Brazos',
      groupEn: 'Arms',
      labelEs: 'Tríceps',
      labelEn: 'Triceps',
      primaryKeys: {'triceps'},
      stapleIds: [
        'ff_triceps_rope_pushdown',
        'ff_triceps_straight_bar_pushdown',
        'ff_triceps_v_bar_pushdown',
        'ff_triceps_overhead_cable_extension',
        'ff_triceps_triceps_extension_machine',
        'ff_triceps_close_grip_bench_press',
      ],
    ),
    SmartMuscleTarget(
      id: 'antebrazos',
      groupEs: 'Brazos',
      groupEn: 'Arms',
      labelEs: 'Antebrazos',
      labelEn: 'Forearms',
      primaryKeys: {'antebrazos', 'forearms'},
      stapleIds: [
        'ff_forearms_dumbbell_wrist_curl',
        'ff_forearms_barbell_wrist_curl',
        'ff_biceps_reverse_cable_curl',
      ],
    ),
    SmartMuscleTarget(
      id: 'cuadriceps',
      groupEs: 'Piernas',
      groupEn: 'Legs',
      labelEs: 'Cuádriceps',
      labelEn: 'Quads',
      primaryKeys: {'cuadriceps', 'quads'},
      stapleIds: [
        'ff_legs_back_squat',
        'ff_legs_leg_press_machine',
        'ff_legs_hack_squat_machine',
        'ff_legs_leg_extension_machine',
        'ff_legs_bulgarian_split_squat',
        'ff_legs_walking_lunge',
      ],
    ),
    SmartMuscleTarget(
      id: 'isquios',
      groupEs: 'Piernas',
      groupEn: 'Legs',
      labelEs: 'Isquios',
      labelEn: 'Hamstrings',
      primaryKeys: {'isquios', 'hamstrings'},
      stapleIds: [
        'ff_legs_romanian_deadlift',
        'ff_back_romanian_deadlift',
        'ff_legs_lying_leg_curl_machine',
        'ff_legs_seated_leg_curl_machine',
        'ff_legs_stiff_leg_deadlift',
      ],
    ),
    SmartMuscleTarget(
      id: 'gluteos',
      groupEs: 'Piernas',
      groupEn: 'Legs',
      labelEs: 'Glúteos',
      labelEn: 'Glutes',
      primaryKeys: {'gluteos', 'glutes'},
      stapleIds: [
        'ff_glutes_barbell_hip_thrust',
        'ff_glutes_hip_thrust_machine',
        'ff_glutes_dumbbell_hip_thrust',
        'ff_glutes_smith_machine_hip_thrust',
      ],
    ),
    SmartMuscleTarget(
      id: 'gluteo_medio',
      groupEs: 'Piernas',
      groupEn: 'Legs',
      labelEs: 'Glúteo medio',
      labelEn: 'Glute medius',
      primaryKeys: {'gluteo medio', 'glute medius'},
      stapleIds: ['ff_glutes_hip_abductor_machine'],
    ),
    SmartMuscleTarget(
      id: 'aductores',
      groupEs: 'Piernas',
      groupEn: 'Legs',
      labelEs: 'Aductores',
      labelEn: 'Adductors',
      primaryKeys: {'aductores', 'adductors'},
      stapleIds: ['ff_legs_adductor_machine'],
    ),
    SmartMuscleTarget(
      id: 'pantorrillas',
      groupEs: 'Piernas',
      groupEn: 'Legs',
      labelEs: 'Pantorrillas',
      labelEn: 'Calves',
      primaryKeys: {'pantorrillas', 'calves'},
      stapleIds: [
        'ff_calves_standing_calf_raise_machine',
        'ff_calves_seated_calf_raise_machine',
        'ff_calves_leg_press_calf_raise_machine',
        'ff_calves_barbell_standing_calf_raise',
      ],
    ),
    SmartMuscleTarget(
      id: 'abdominales',
      groupEs: 'Abdominales',
      groupEn: 'Abs',
      labelEs: 'Abdominales',
      labelEn: 'Abs',
      primaryKeys: {'abdominales', 'abs'},
      stapleIds: [
        'ff_abs_cable_crunch',
        'ff_abs_ab_crunch_machine',
        'ff_abs_crunch',
        'ff_abs_plank',
        'ff_abs_decline_bench_sit_up',
      ],
    ),
  ];

  static List<String> groupOrder(String languageCode) {
    final seen = <String>[];
    for (final target in targets) {
      final group = target.groupLabel(languageCode);
      if (!seen.contains(group)) seen.add(group);
    }
    return seen;
  }

  static List<SmartMuscleTarget> inGroup(String groupLabel, String languageCode) {
    return targets.where((target) => target.groupLabel(languageCode) == groupLabel).toList();
  }

  /// Mismo movimiento con otro equipo, agarre o máquina.
  ///
  /// Sirve para no armar press con barra y el mismo press con mancuernas.
  static String movementKey(String exerciseId, String name) {
    final mapped = _familyById[exerciseId];
    if (mapped != null) return mapped;
    final fromName = _familyFromName(name);
    if (fromName != null) return fromName;
    final stripped = _stripEquipment(_normalize(name));
    return stripped.isEmpty ? exerciseId : 'name:$stripped';
  }

  static final Map<String, String> _familyById = {
    for (final entry in _movementFamilies.entries)
      for (final id in entry.value) id: entry.key,
  };

  static List<({String alias, String family})>? _aliases;

  static List<({String alias, String family})> get _sortedAliases {
    return _aliases ??= [
      for (final entry in _nameFamilies.entries)
        for (final alias in entry.value) (alias: alias, family: entry.key),
    ]..sort((a, b) => b.alias.length.compareTo(a.alias.length));
  }

  static String? _familyFromName(String name) {
    final stripped = _stripEquipment(_normalize(name));
    if (stripped.isEmpty) return null;
    for (final alias in _sortedAliases) {
      if (_nameMatches(stripped, alias.alias)) return alias.family;
    }
    return null;
  }

  static bool _nameMatches(String stripped, String alias) {
    return stripped == alias ||
        stripped.startsWith('$alias ') ||
        stripped.endsWith(' $alias') ||
        stripped.contains(' $alias ');
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  static String _stripEquipment(String normalized) {
    var text = ' $normalized ';
    for (final phrase in _equipmentPhrases) {
      text = text.replaceAll(' $phrase ', ' ');
    }
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static const _equipmentPhrases = [
    'con barra ez',
    'con barra recta',
    'con barra v',
    'con barra',
    'con mancuernas',
    'con mancuerna',
    'en maquina smith',
    'en la maquina smith',
    'maquina smith',
    'en maquina',
    'en polea',
    'con cuerda',
    'con disco',
    'con discos',
    'con kettlebell',
    'a una mano',
    'a un brazo',
    'smith machine',
    'ez bar',
    'straight bar',
    'v bar',
    'barbell',
    'dumbbells',
    'dumbbell',
    'kettlebell',
    'cable',
    'machine',
    'with rope',
    'one arm',
    'single arm',
  ];

  static const _nameFamilies = <String, List<String>>{
    'incline_press': [
      'press banca inclinado',
      'press inclinado',
      'incline bench press',
      'incline chest press',
    ],
    'decline_press': [
      'press banca declinado',
      'press declinado',
      'decline bench press',
      'decline chest press',
    ],
    'close_grip_press': [
      'press banca agarre cerrado',
      'close grip bench press',
    ],
    'flat_press': [
      'press banca',
      'press de pecho',
      'bench press',
      'chest press',
      'flexion de pecho',
      'push up',
      'pushup',
    ],
    'incline_fly': ['cruce bajo a alto', 'low to high'],
    'decline_fly': ['cruce alto a bajo', 'high to low'],
    'rear_delt': [
      'apertura posterior',
      'face pull',
      'pec deck invertido',
      'reverse pec deck',
      'rear delt',
    ],
    'fly': ['aperturas', 'pec deck', 'chest fly', 'fly'],
    'upright_row': ['remo al menton', 'upright row'],
    'shrug': ['encogimiento', 'shrug'],
    'vertical_pull': [
      'jalon al pecho',
      'lat pulldown',
      'pull up',
      'pullup',
      'chin up',
      'chinup',
      'dominada',
    ],
    'row': ['remo', 'row'],
    'shoulder_press': [
      'press de hombro',
      'press militar',
      'press arnold',
      'shoulder press',
      'overhead press',
      'arnold press',
    ],
    'lateral_raise': [
      'elevacion lateral',
      'elevaciones laterales',
      'lateral raise',
    ],
    'front_raise': ['elevacion frontal', 'front raise'],
    'seated_calf': [
      'elevacion de pantorrilla sentado',
      'seated calf',
    ],
    'standing_calf': [
      'elevacion de pantorrilla',
      'calf raise',
    ],
    'hammer_curl': ['curl martillo', 'hammer curl'],
    'reverse_wrist': [
      'curl inverso de muneca',
      'curl de muneca inverso',
      'reverse wrist curl',
    ],
    'wrist_curl': ['curl de muneca', 'wrist curl'],
    'reverse_curl': ['curl inverso', 'reverse curl'],
    'curl': [
      'curl de biceps',
      'biceps curl',
      'curl predicador',
      'preacher curl',
    ],
    'pushdown': ['jalon de triceps', 'triceps pushdown', 'pushdown'],
    'overhead_extension': [
      'extension sobre cabeza',
      'extension de triceps',
      'overhead extension',
      'triceps extension',
    ],
    'skull_crusher': ['rompecraneos', 'skull crusher', 'jm press'],
    'dip': ['fondos', 'dip'],
    'lunge': [
      'sentadilla bulgara',
      'bulgarian split squat',
      'split squat',
      'zancada',
      'lunge',
    ],
    'leg_press': ['prensa de piernas', 'leg press'],
    'leg_extension': ['extension de piernas', 'leg extension'],
    'leg_curl': ['curl femoral', 'leg curl'],
    'rdl': [
      'peso muerto rumano',
      'peso muerto piernas rigidas',
      'romanian deadlift',
      'stiff leg deadlift',
    ],
    'sumo_deadlift': ['peso muerto sumo', 'sumo deadlift'],
    'squat': ['sentadilla', 'squat'],
    'hip_thrust': [
      'hip thrust',
      'puente de gluteo',
      'glute bridge',
      'frog pump',
      'glute drive',
    ],
    'crunch': ['crunch', 'sit up', 'situp', 'abdominal completo'],
    'leg_raise': ['elevacion de piernas', 'leg raise'],
    'plank': ['plancha', 'plank'],
    'pullover': ['pullover'],
  };

  static const _movementFamilies = <String, List<String>>{
    'flat_press': [
      'ff_chest_barbell_bench_press',
      'ff_chest_dumbbell_bench_press',
      'ff_chest_chest_press_machine',
      'ff_chest_smith_machine_bench_press',
      'ff_chest_hex_dumbbell_press',
      'ff_chest_standing_cable_chest_press',
      'ff_chest_push_up',
      'ff_chest_ring_push_up',
      'ff_chest_archer_push_up',
    ],
    'incline_press': [
      'ff_chest_incline_barbell_bench_press',
      'ff_chest_incline_dumbbell_bench_press',
      'ff_chest_incline_chest_press_machine',
      'ff_chest_smith_machine_incline_bench_press',
      'ff_chest_decline_push_up',
    ],
    'decline_press': [
      'ff_chest_decline_barbell_bench_press',
      'ff_chest_decline_dumbbell_bench_press',
      'ff_chest_decline_chest_press_machine',
      'ff_chest_incline_push_up',
    ],
    'close_grip_press': ['ff_triceps_close_grip_bench_press'],
    'fly': [
      'ff_chest_cable_fly',
      'ff_chest_dumbbell_fly',
      'ff_chest_pec_deck_fly_machine',
    ],
    'incline_fly': ['ff_chest_low_to_high_cable_fly'],
    'decline_fly': ['ff_chest_high_to_low_cable_fly'],
    'pullover': [
      'ff_chest_barbell_pullover',
      'ff_chest_dumbbell_pullover',
      'ff_back_cable_pullover',
      'ff_back_machine_pullover',
      'ff_cf_bar_pullover',
      'ff_back_straight_arm_cable_pulldown',
    ],
    'vertical_pull': [
      'ff_back_lat_pulldown_machine',
      'ff_back_lat_pulldown_classic',
      'ff_back_close_grip_lat_pulldown_machine',
      'ff_back_wide_grip_lat_pulldown_machine',
      'ff_back_v_bar_lat_pulldown',
      'ff_back_single_arm_lat_pulldown',
      'ff_back_cable_parallel_grip_lat_pulldown',
      'ff_back_pull_up',
      'ff_back_chin_up',
      'ff_biceps_chin_up',
      'ff_biceps_close_grip_chin_up',
      'ff_back_assisted_chin_up_machine',
      'ff_back_assisted_pull_up_machine',
      'ff_back_neutral_grip_pull_up',
      'ff_cf_kipping_pull_up',
    ],
    'row': [
      'ff_back_barbell_row',
      'ff_back_smith_machine_bent_over_row',
      'ff_back_single_arm_dumbbell_row',
      'ff_back_seated_cable_row',
      'ff_back_seated_row_machine',
      'ff_back_t_bar_row',
      'ff_back_t_bar_row_machine',
      'ff_back_meadows_row',
      'ff_back_pendlay_row',
      'ff_back_chest_supported_dumbbell_row',
      'ff_back_dumbbell_incline_row',
      'ff_back_barbell_incline_row',
      'ff_back_chest_supported_row_machine',
      'ff_back_high_row_machine',
      'ff_back_high_cable_row',
      'ff_back_inverted_row',
      'ff_back_australian_pull_up',
    ],
    'shrug': ['ff_back_barbell_shrug', 'ff_back_dumbbell_shrug'],
    'shoulder_press': [
      'ff_shoulders_dumbbell_shoulder_press',
      'ff_shoulders_shoulder_press_machine',
      'ff_shoulders_barbell_overhead_press',
      'ff_shoulders_seated_barbell_overhead_press',
      'ff_shoulders_smith_machine_shoulder_press',
      'ff_shoulders_arnold_press',
      'ff_shoulders_handstand_push_up',
      'ff_shoulders_pike_push_up',
    ],
    'lateral_raise': [
      'ff_shoulders_dumbbell_lateral_raise',
      'ff_shoulders_machine_lateral_raise',
      'ff_shoulders_cable_lateral_raise',
      'ff_shoulders_single_arm_dumbbell_lateral_raise',
    ],
    'front_raise': [
      'ff_shoulders_dumbbell_front_raise',
      'ff_shoulders_cable_front_raise',
    ],
    'rear_delt': [
      'ff_shoulders_rear_delt_dumbbell_fly',
      'ff_shoulders_cable_rear_delt_fly',
      'ff_shoulders_reverse_pec_deck_machine',
      'ff_shoulders_face_pull',
    ],
    'upright_row': ['ff_shoulders_upright_row'],
    'curl': [
      'ff_biceps_dumbbell_curl',
      'ff_biceps_barbell_curl',
      'ff_biceps_ez_bar_curl',
      'ff_biceps_cable_curl',
      'ff_biceps_preacher_curl_machine',
      'ff_biceps_close_grip_preacher_curl',
      'ff_biceps_close_grip_barbell_curl',
      'ff_biceps_alternating_dumbbell_curl',
      'ff_biceps_bayesian_cable_curl',
      'ff_biceps_concentration_curl',
      'ff_biceps_incline_dumbbell_curl',
      'ff_biceps_high_cable_curl',
      'ff_biceps_single_arm_cable_curl',
      'ff_biceps_bodyweight_biceps_curl',
      'ff_biceps_ring_curl',
      'ff_biceps_dumbbell_reverse_spider_curl',
    ],
    'hammer_curl': ['ff_biceps_hammer_curl', 'ff_biceps_rope_hammer_curl'],
    'pushdown': [
      'ff_triceps_rope_pushdown',
      'ff_triceps_straight_bar_pushdown',
      'ff_triceps_v_bar_pushdown',
      'ff_triceps_reverse_grip_pushdown',
      'ff_triceps_single_arm_cable_pushdown',
    ],
    'overhead_extension': [
      'ff_triceps_overhead_cable_extension',
      'ff_triceps_overhead_dumbbell_extension',
      'ff_triceps_single_arm_overhead_dumbbell_extension',
      'ff_triceps_triceps_extension_machine',
      'ff_triceps_bodyweight_triceps_extension',
    ],
    'skull_crusher': [
      'ff_triceps_ez_bar_skull_crusher',
      'ff_triceps_skull_crusher',
      'ff_triceps_jm_press',
    ],
    'dip': [
      'ff_triceps_parallel_bar_dip',
      'ff_triceps_machine_dip',
      'ff_triceps_bench_dip',
      'ff_triceps_ring_dip',
      'ff_triceps_assisted_dip_machine',
      'ff_chest_diamond_push_up',
    ],
    'triceps_kickback': [
      'ff_triceps_dumbbell_kickback',
      'ff_triceps_cable_triceps_kickback',
    ],
    'wrist_curl': [
      'ff_forearms_dumbbell_wrist_curl',
      'ff_forearms_barbell_wrist_curl',
      'ff_forearms_cable_wrist_curl',
    ],
    'reverse_wrist': [
      'ff_forearms_dumbbell_reverse_wrist_curl',
      'ff_forearms_barbell_reverse_wrist_curl',
    ],
    'reverse_curl': ['ff_biceps_reverse_cable_curl'],
    'squat': [
      'ff_legs_back_squat',
      'ff_legs_front_squat',
      'ff_legs_goblet_squat',
      'ff_legs_smith_machine_squat',
      'ff_legs_air_squat',
      'ff_legs_hack_squat_machine',
      'ff_legs_belt_squat_machine',
      'ff_legs_pendulum_squat_machine',
      'ff_legs_v_squat_machine',
      'ff_cf_overhead_squat',
    ],
    'leg_press': [
      'ff_legs_leg_press_machine',
      'ff_legs_plate_loaded_leg_press',
    ],
    'lunge': [
      'ff_legs_walking_lunge',
      'ff_legs_reverse_lunge',
      'ff_legs_bulgarian_split_squat',
      'ff_glutes_curtsy_lunge',
      'ff_cf_sandbag_lunge',
    ],
    'leg_extension': ['ff_legs_leg_extension_machine'],
    'step_up': ['ff_legs_step_up'],
    'rdl': [
      'ff_back_romanian_deadlift',
      'ff_legs_romanian_deadlift',
      'ff_glutes_romanian_deadlift',
      'ff_legs_stiff_leg_deadlift',
    ],
    'leg_curl': [
      'ff_legs_lying_leg_curl_machine',
      'ff_legs_seated_leg_curl_machine',
      'ff_legs_standing_leg_curl_machine',
    ],
    'hip_thrust': [
      'ff_glutes_barbell_hip_thrust',
      'ff_glutes_hip_thrust_machine',
      'ff_glutes_dumbbell_hip_thrust',
      'ff_glutes_smith_machine_hip_thrust',
      'ff_glutes_barbell_glute_bridge',
      'ff_glutes_glute_bridge',
      'ff_glutes_single_leg_glute_bridge',
      'ff_glutes_frog_pump',
      'ff_glutes_glute_drive_machine',
    ],
    'glute_kick': ['ff_glutes_cable_kickback', 'ff_glutes_donkey_kick'],
    'abduction': ['ff_glutes_hip_abductor_machine', 'ff_glutes_fire_hydrant'],
    'adduction': ['ff_legs_adductor_machine'],
    'standing_calf': [
      'ff_calves_standing_calf_raise_machine',
      'ff_calves_barbell_standing_calf_raise',
      'ff_calves_dumbbell_standing_calf_raise',
      'ff_calves_smith_machine_calf_raise',
      'ff_calves_standing_calf_raise',
      'ff_calves_elevated_calf_raise',
      'ff_calves_single_leg_calf_raise',
      'ff_calves_single_leg_dumbbell_calf_raise',
      'ff_calves_donkey_calf_raise_machine',
      'ff_calves_leg_press_calf_raise_machine',
    ],
    'seated_calf': ['ff_calves_seated_calf_raise_machine'],
    'crunch': [
      'ff_abs_crunch',
      'ff_abs_cable_crunch',
      'ff_abs_ab_crunch_machine',
      'ff_abs_bicycle_crunch',
      'ff_abs_cable_standing_crunch',
      'ff_abs_sit_up',
      'ff_abs_decline_bench_sit_up',
    ],
    'leg_raise': [
      'ff_abs_hanging_leg_raise',
      'ff_abs_lying_leg_raise',
      'ff_abs_captain_s_chair_leg_raise',
      'ff_abs_machine_seated_leg_raise_crunch',
      'ff_abs_cable_reverse_crunch',
    ],
    'plank': ['ff_abs_plank'],
    'rotation': [
      'ff_abs_russian_twist',
      'ff_abs_cable_seated_twist',
      'ff_abs_cable_wood_chop',
    ],
    'thruster': ['ff_cf_thruster', 'ff_cf_dumbbell_thruster'],
  };
}
