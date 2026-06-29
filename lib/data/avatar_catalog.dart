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

  static bool canSelect(String? storageId, String? email) {
    if (storageId == null) return false;
    if (!isCatalogValue(storageId)) return true;
    final option = resolve(storageId);
    if (option == null) return false;
    return option.isAvailableTo(email);
  }

  static AvatarOption defaultOption() => options.first;
}
