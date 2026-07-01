/// Avatar predefinido del catálogo FitForge (imágenes locales, sin subida).
class AvatarOption {
  final String id;
  final String assetPath;
  /// Si se define, solo ese correo puede ver y seleccionar el avatar.
  final String? exclusiveEmail;

  const AvatarOption({
    required this.id,
    required this.assetPath,
    this.exclusiveEmail,
  });

  bool isAvailableTo(String? email) {
    if (exclusiveEmail == null) return true;
    if (email == null) return false;
    return email.trim().toLowerCase() == exclusiveEmail!.trim().toLowerCase();
  }
}

abstract final class AvatarCatalog {
  static const prefix = 'catalog:';
  static const _assetBase = 'assets/images/avatars';

  static const options = <AvatarOption>[
    AvatarOption(id: 'gymrat_male', assetPath: '$_assetBase/gymrat_male.png'),
    AvatarOption(id: 'gymrat_female', assetPath: '$_assetBase/gymrat_female.png'),
    AvatarOption(id: 'panda', assetPath: '$_assetBase/panda.png'),
    AvatarOption(id: 'rabbit', assetPath: '$_assetBase/rabbit.png'),
    AvatarOption(id: 'bull', assetPath: '$_assetBase/bull.png'),
    AvatarOption(id: 'shark', assetPath: '$_assetBase/shark.png'),
    AvatarOption(id: 'dragon', assetPath: '$_assetBase/dragon.png'),
    AvatarOption(id: 'lion', assetPath: '$_assetBase/lion.png'),
    AvatarOption(id: 'cheetah', assetPath: '$_assetBase/cheetah.png'),
    AvatarOption(id: 'duck', assetPath: '$_assetBase/duck.png'),
    AvatarOption(id: 'frog', assetPath: '$_assetBase/frog.png'),
    AvatarOption(id: 'gym_bot', assetPath: '$_assetBase/gym_bot.png'),
    AvatarOption(id: 'astronaut', assetPath: '$_assetBase/astronaut.png'),
    AvatarOption(id: 'retro_bot', assetPath: '$_assetBase/retro_bot.png'),
    AvatarOption(id: 'unicorn', assetPath: '$_assetBase/unicorn.png'),
    AvatarOption(id: 'pumpkin_gains', assetPath: '$_assetBase/pumpkin_gains.png'),
    AvatarOption(id: 'bulldog', assetPath: '$_assetBase/bulldog.png'),
    AvatarOption(id: 'lizard', assetPath: '$_assetBase/lizard.png'),
    AvatarOption(id: 'reps_bot', assetPath: '$_assetBase/reps_bot.png'),
    AvatarOption(id: 'capybara', assetPath: '$_assetBase/capybara.png'),
    AvatarOption(id: 'red_panda', assetPath: '$_assetBase/red_panda.png'),
    AvatarOption(id: 'sloth', assetPath: '$_assetBase/sloth.png'),
    AvatarOption(id: 'panther', assetPath: '$_assetBase/panther.png'),
    AvatarOption(id: 'fox', assetPath: '$_assetBase/fox.png'),
    AvatarOption(id: 'pumpkin_spooky', assetPath: '$_assetBase/pumpkin_spooky.png'),
    AvatarOption(id: 'quack_pump_duck', assetPath: '$_assetBase/quack_pump_duck.png'),
    AvatarOption(id: 'snow_leopard', assetPath: '$_assetBase/snow_leopard.png'),
    AvatarOption(id: 'cyber_samurai', assetPath: '$_assetBase/cyber_samurai.png'),
    AvatarOption(id: 'skeleton_grind', assetPath: '$_assetBase/skeleton_grind.png'),
    AvatarOption(id: 'gamer_crown', assetPath: '$_assetBase/gamer_crown.png'),
    AvatarOption(id: 'focus_conquer', assetPath: '$_assetBase/focus_conquer.png'),
    AvatarOption(id: 'hooded_striker', assetPath: '$_assetBase/hooded_striker.png'),
    AvatarOption(id: 'cyber_pilot', assetPath: '$_assetBase/cyber_pilot.png'),
    AvatarOption(id: 'discipline_skull', assetPath: '$_assetBase/discipline_skull.png'),
    AvatarOption(id: 'strong_mind', assetPath: '$_assetBase/strong_mind.png'),
    AvatarOption(id: 'discipline_goth', assetPath: '$_assetBase/discipline_goth.png'),
    AvatarOption(
      id: 'admin',
      assetPath: '$_assetBase/admin.png',
      exclusiveEmail: 'emiliodiaz@gesys.gt',
    ),
  ];

  static String toStorageId(String optionId) => '$prefix$optionId';

  static bool isCatalogValue(String? value) =>
      value != null && value.startsWith(prefix);

  static bool isNetworkUrl(String? value) =>
      value != null && (value.startsWith('http://') || value.startsWith('https://'));

  static AvatarOption? resolve(String? value) {
    if (!isCatalogValue(value)) return null;
    final id = value!.substring(prefix.length);
    for (final option in options) {
      if (option.id == id) return option;
    }
    return null;
  }

  static List<AvatarOption> optionsForUser(String? email) =>
      options.where((option) => option.isAvailableTo(email)).toList();

  /// Opciones del picker: las del usuario más la selección actual si quedó fuera
  /// (p. ej. sesión sin email pero perfil con avatar exclusivo).
  static List<AvatarOption> pickerOptionsForUser(
    String? email, {
    String? selectedStorageId,
  }) {
    final available = optionsForUser(email);
    if (!isCatalogValue(selectedStorageId)) return available;

    final selectedId = selectedStorageId!.substring(prefix.length);
    if (available.any((option) => option.id == selectedId)) return available;

    final selected = resolve(selectedStorageId);
    if (selected == null) return available;
    return [selected, ...available];
  }

  static bool canSelect(String? storageId, String? email) {
    if (storageId == null) return false;
    if (!isCatalogValue(storageId)) return true;
    final option = resolve(storageId);
    if (option == null) return false;
    return option.isAvailableTo(email);
  }

  static AvatarOption defaultOption() => options.first;
}
