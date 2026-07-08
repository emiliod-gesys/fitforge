import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum FitForgeLogoVariant { full, icon, wordmark }

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

  const FitForgeLogo.full({super.key, this.height, this.width}) : variant = FitForgeLogoVariant.full;

  const FitForgeLogo.icon({super.key, this.height, this.width}) : variant = FitForgeLogoVariant.icon;

  const FitForgeLogo.wordmark({super.key, this.height}) : variant = FitForgeLogoVariant.wordmark, width = null;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      FitForgeLogoVariant.full => _FullLogo(height: height ?? 140, width: width),
      FitForgeLogoVariant.icon => Image.asset(
          'assets/images/logo_icon.png',
          height: height ?? 64,
          width: width ?? height ?? 64,
          fit: BoxFit.contain,
        ),
      FitForgeLogoVariant.wordmark => _Wordmark(height: height ?? 32),
    };
  }
}

class _FullLogo extends StatelessWidget {
  final double height;
  final double? width;

  const _FullLogo({required this.height, this.width});

  @override
  Widget build(BuildContext context) {
    final markHeight = height * 0.72;
    final wordmarkHeight = height * 0.16;

    return SizedBox(
      width: width,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo_icon.png',
            height: markHeight,
            fit: BoxFit.contain,
          ),
          SizedBox(height: height * 0.06),
          _Wordmark(height: wordmarkHeight),
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  final double height;

  const _Wordmark({required this.height});

  @override
  Widget build(BuildContext context) {
    final fontSize = height * 0.85;
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          fontFamily: 'Montserrat',
        ),
        children: [
          TextSpan(text: 'FIT', style: TextStyle(color: AppColors.logoFit)),
          TextSpan(text: 'FORGE', style: TextStyle(color: AppColors.logoForge)),
        ],
      ),
    );
  }
}
