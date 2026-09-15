import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/l10n_extensions.dart';

class ReferralCodeCopyRow extends StatelessWidget {
  final String code;

  const ReferralCodeCopyRow({super.key, required this.code});

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.referralCodeCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = context.accentColor;
    return Material(
      color: AppColors.card,
      borderRadius: AppTokens.borderRadiusMd,
      child: InkWell(
        onTap: () => _copy(context),
        borderRadius: AppTokens.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space16,
            vertical: AppTokens.space16,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppTokens.borderRadiusSm,
                ),
                child: Icon(Icons.confirmation_number_outlined,
                    color: accent, size: 20),
              ),
              const SizedBox(width: AppTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.referralYourCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      code,
                      style: TextStyle(
                        color: accent,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.copy_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
