import 'package:flutter/material.dart';

import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/social.dart';
import '../profile_avatar.dart';

class PendingRequestTile extends StatelessWidget {
  final FriendUser friend;
  final String subtitle;
  final bool incoming;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const PendingRequestTile({
    super.key,
    required this.friend,
    required this.subtitle,
    required this.incoming,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = context.accentColor;

    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        side: BorderSide(
          color: incoming ? accent.withValues(alpha: 0.35) : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                ProfileAvatar(
                  avatarUrl: friend.avatarUrl,
                  radius: 22,
                  fallbackLetter: friend.label,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: incoming ? accent : AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: incoming ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (incoming) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
                        minimumSize: const Size(0, 40),
                      ),
                      child: Text(l10n.decline),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: onAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(0, 40),
                      ),
                      child: Text(l10n.accept),
                    ),
                  ),
                ],
              ),
            ] else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onDecline,
                  child: Text(l10n.cancel),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
