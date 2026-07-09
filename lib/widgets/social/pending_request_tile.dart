import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/social.dart';
import '../profile_avatar.dart';
import '../../core/theme/app_accent.dart';

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
    return Card(
      color: AppColors.card,
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: incoming ? context.accentColor.withValues(alpha: 0.35) : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
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
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: incoming ? context.accentColor : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: incoming ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (incoming) ...[
              IconButton(
                icon: Icon(Icons.check_circle_outline),
                color: context.accentColor,
                onPressed: onAccept,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                color: AppColors.textMuted,
                onPressed: onDecline,
              ),
            ] else
              IconButton(
                icon: const Icon(Icons.close),
                color: AppColors.textMuted,
                onPressed: onDecline,
              ),
          ],
        ),
      ),
    );
  }
}
