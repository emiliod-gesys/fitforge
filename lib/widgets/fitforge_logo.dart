import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum FitForgeLogoVariant { full, icon, wordmark }

/// Brand assets.
///
/// - [full] / brand lockup: isotipo + wordmark FORGEN (AppBar / login).
/// - [icon]: isotipo solo — se actualizará cuando llegue el nuevo archivo.
abstract final class ForgenBrandAssets {
  static const brandLockup = 'assets/images/logo_brand.png';
  static const icon = 'assets/images/logo_icon.png';
}

class FitForgeLogo extends StatelessWidget {
  final FitForgeLogoVariant variant;
  final double? height;
  final double? width;

  const FitForgeLogo({
    super.key,
    this.variant = FitForgeLogoVariant.full,
    this.height,
    this.width,
  });

  const FitForgeLogo.full({super.key, this.height, this.width})
      : variant = FitForgeLogoVariant.full;

  const FitForgeLogo.icon({super.key, this.height, this.width})
      : variant = FitForgeLogoVariant.icon;

  const FitForgeLogo.wordmark({super.key, this.height})
      : variant = FitForgeLogoVariant.wordmark,
        width = null;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      FitForgeLogoVariant.full => Image.asset(
          ForgenBrandAssets.brandLockup,
          height: height ?? 140,
          width: width,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      FitForgeLogoVariant.icon => Image.asset(
          ForgenBrandAssets.icon,
          height: height ?? 64,
          width: width ?? height ?? 64,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      FitForgeLogoVariant.wordmark => _Wordmark(height: height ?? 32),
    };
  }
}

class _Wordmark extends StatelessWidget {
  final double height;

  const _Wordmark({required this.height});

  @override
  Widget build(BuildContext context) {
    final fontSize = height * 0.85;
    return Text(
      'FORGEN',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        fontFamily: 'Montserrat',
        color: AppColors.logoForge,
      ),
    );
  }
}
