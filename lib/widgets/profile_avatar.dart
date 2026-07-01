import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../data/avatar_catalog.dart';

/// Muestra avatar de catálogo, URL externa o inicial por defecto.
class ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final String? fallbackLetter;

  const ProfileAvatar({
    super.key,
    this.avatarUrl,
    this.radius = 40,
    this.fallbackLetter,
  });

  double get size => radius * 2;

  Widget _square({required Widget child}) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: ColoredBox(
          color: AppColors.card,
          child: child,
        ),
      ),
    );
  }

  Widget _image(ImageProvider provider) {
    return _square(
      child: Image(
        image: provider,
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Center(
          child: Icon(Icons.person, size: radius, color: AppColors.textMuted),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = AvatarCatalog.resolve(avatarUrl);
    if (catalog != null) {
      return _image(AssetImage(catalog.assetPath));
    }

    if (AvatarCatalog.isNetworkUrl(avatarUrl)) {
      return _image(NetworkImage(avatarUrl!));
    }

    final letter = fallbackLetter?.trim();
    return _square(
      child: Center(
        child: letter != null && letter.isNotEmpty
            ? Text(
                letter[0].toUpperCase(),
                style: TextStyle(
                  fontSize: radius * 0.9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              )
            : Icon(Icons.person, size: radius, color: AppColors.textMuted),
      ),
    );
  }
}
