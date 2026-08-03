import 'package:flutter/material.dart';

import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import 'ff_surface.dart';

/// Tile de hub para perfil / navegación secundaria.
class FfHubTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? accentOverride;

  const FfHubTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accentOverride,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentOverride ?? context.accentColor;
    return FfSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: AppTokens.borderRadiusMd,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.28),
                  accent.withValues(alpha: 0.08),
                ],
              ),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: AppTokens.space14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: accent.withValues(alpha: 0.8)),
        ],
      ),
    );
  }
}
