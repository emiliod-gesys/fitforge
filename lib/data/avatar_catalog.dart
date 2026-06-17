/// Avatar predefinido del catálogo FitForge (imágenes locales, sin subida).
class AvatarOption {
  final String id;
  final String assetPath;

  const AvatarOption({
    required this.id,
    required this.assetPath,
  });
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

  static AvatarOption defaultOption() => options.first;
}
