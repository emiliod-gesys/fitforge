import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/referrals/referral_rules.dart';
import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/profile.dart';
import '../../models/referral.dart';
import '../../providers/app_providers.dart';
import '../ff/ff_section_header.dart';
import '../fitforge_loading_indicator.dart';
import '../profile_avatar.dart';
import 'referral_code_copy_row.dart';

class ReferralsSection extends ConsumerWidget {
  final UserProfile? profile;

  const ReferralsSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final code = profile?.referralCode;
    final referralsAsync = ref.watch(myReferralsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myReferralsProvider);
        ref.invalidate(profileProvider);
        await ref.read(myReferralsProvider.future);
      },
      child: ListView(
        padding: AppTokens.pagePaddingWithBottomInset(context),
        children: [
          if (code != null && code.isNotEmpty) ...[
            ReferralCodeCopyRow(code: code),
            const SizedBox(height: AppTokens.space20),
          ],
          referralsAsync.when(
            skipLoadingOnReload: true,
            data: (entries) {
              final active = entries.where((e) => e.isActive).length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FfSectionHeader(
                    title: l10n.referralProgressTitle,
                    subtitle: l10n.referralProgressSubtitle(
                      active,
                      referralProThreshold,
                    ),
                  ),
                  _ProgressBar(
                    active: active,
                    needed: referralProThreshold,
                  ),
                  const SizedBox(height: AppTokens.space20),
                  FfSectionHeader(title: l10n.referralConditionsTitle),
                  Text(
                    l10n.referralConditionsBody,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space24),
                  FfSectionHeader(title: l10n.referralListTitle),
                  if (entries.isEmpty)
                    Text(
                      l10n.referralListEmpty,
                      style: const TextStyle(color: AppColors.textMuted),
                    )
                  else
                    ...entries.map((entry) => _ReferralTile(entry: entry)),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(AppTokens.space32),
              child: Center(child: FitForgeLoadingIndicator(size: 100)),
            ),
            error: (e, _) => Text(l10n.errorGeneric('$e')),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int active;
  final int needed;

  const _ProgressBar({required this.active, required this.needed});

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;
    final value = needed == 0 ? 0.0 : (active / needed).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 8,
        backgroundColor: AppColors.border.withValues(alpha: 0.45),
        color: accent,
      ),
    );
  }
}

class _ReferralTile extends StatelessWidget {
  final ReferralEntry entry;

  const _ReferralTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = (entry.displayName ?? '').trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space8),
      child: Row(
        children: [
          ProfileAvatar(
            avatarUrl: entry.avatarUrl,
            radius: 20,
            fallbackLetter: name,
          ),
          const SizedBox(width: AppTokens.space12),
          Expanded(
            child: Text(
              name.isEmpty ? l10n.user : name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: entry.isActive
                  ? context.accentColor.withValues(alpha: 0.16)
                  : AppColors.cardElevated,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              entry.isActive
                  ? l10n.referralStatusActive
                  : l10n.referralStatusInactive,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color:
                    entry.isActive ? context.accentColor : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
