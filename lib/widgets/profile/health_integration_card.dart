import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/unit_converter.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../../providers/health_integration_provider.dart';
import '../../services/health/health_body_metrics_evaluator.dart';

class HealthIntegrationCard extends ConsumerStatefulWidget {
  const HealthIntegrationCard({super.key, required this.profile});

  final UserProfile? profile;

  @override
  ConsumerState<HealthIntegrationCard> createState() => _HealthIntegrationCardState();
}

class _HealthIntegrationCardState extends ConsumerState<HealthIntegrationCard> {
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    await ref.read(healthIntegrationProvider.notifier).initialize();
    final state = ref.read(healthIntegrationProvider);
    if (state.prefs.connected && state.permissionsGranted) {
      await _sync(showNoUpdatesSnack: false);
    }
  }

  Future<void> _sync({bool showNoUpdatesSnack = true}) async {
    final snapshots = ref.read(bodyMetricSnapshotsProvider).valueOrNull ?? {};
    await ref.read(healthIntegrationProvider.notifier).syncNow(
          profile: widget.profile,
          snapshots: snapshots,
        );
    if (!mounted) return;

    final state = ref.read(healthIntegrationProvider);
    if (state.pendingProposals.isNotEmpty) {
      await _showProposalDialogs(state.pendingProposals);
    } else if (showNoUpdatesSnack && state.errorCode == null && state.prefs.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.healthIntegrationNoUpdates)),
      );
    } else if (state.errorCode != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(context, state.errorCode!))),
      );
    }
  }

  Future<void> _showProposalDialogs(List<HealthImportProposal> proposals) async {
    final unit = widget.profile?.unitSystem ?? 'kg';
    for (final proposal in proposals) {
      if (!mounted) break;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(_proposalTitle(context, proposal)),
          content: Text(
            context.l10n.healthIntegrationImportConfirm(
              _formatProposalValue(context, proposal, unit),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.healthIntegrationImportDismiss),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.healthIntegrationImportApply),
            ),
          ],
        ),
      );

      if (!mounted) break;
      if (accepted == true) {
        await ref.read(healthIntegrationProvider.notifier).applyProposal(
              proposal,
              unitSystem: unit,
            );
      } else {
        await ref.read(healthIntegrationProvider.notifier).dismissProposal(proposal);
      }
    }
  }

  String _proposalTitle(BuildContext context, HealthImportProposal proposal) {
    return proposal.sample.type == 'weight'
        ? context.l10n.healthIntegrationImportWeightTitle
        : context.l10n.healthIntegrationImportBodyFatTitle;
  }

  String _formatProposalValue(
    BuildContext context,
    HealthImportProposal proposal,
    String unitSystem,
  ) {
    if (proposal.sample.type == 'weight') {
      final display = UnitConverter.kgToDisplay(proposal.sample.value, unitSystem);
      return '${display.toStringAsFixed(1)} ${UnitConverter.massLabel(unitSystem)}';
    }
    return '${proposal.sample.value.toStringAsFixed(1)} %';
  }

  String _errorMessage(BuildContext context, String code) {
    final l10n = context.l10n;
    return switch (code) {
      'unsupported_platform' => l10n.healthIntegrationUnsupported,
      'health_connect_unavailable' => l10n.healthIntegrationHealthConnectMissing,
      'permission_denied' => l10n.healthIntegrationPermissionDenied,
      'connect_failed' || 'sync_failed' => l10n.healthIntegrationSyncFailed,
      _ => l10n.healthIntegrationSyncFailed,
    };
  }

  String _platformLabel() {
    if (Platform.isIOS) return 'Apple Health';
    if (Platform.isAndroid) return 'Health Connect';
    return 'Health';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(healthIntegrationProvider);

    if (!state.platformSupported && state.initialized) {
      return const SizedBox.shrink();
    }

    final lastSyncLabel = state.prefs.lastSyncAt != null
        ? l10n.healthIntegrationLastSync(
            DateFormat.yMMMd().add_Hm().format(state.prefs.lastSyncAt!.toLocal()),
          )
        : l10n.healthIntegrationNeverSynced;

    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.favorite_outline, color: context.accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.healthIntegrationTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.healthIntegrationSubtitle,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.healthIntegrationDisclaimer,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              state.prefs.connected && state.permissionsGranted
                  ? l10n.healthIntegrationConnected
                  : l10n.healthIntegrationNotConnected,
              style: TextStyle(
                color: state.prefs.connected ? context.accentColor : AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(lastSyncLabel, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            if (Platform.isAndroid && !state.healthConnectAvailable) ...[
              const SizedBox(height: 12),
              Text(
                l10n.healthIntegrationHealthConnectMissing,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: state.loading
                    ? null
                    : () => ref.read(healthIntegrationProvider.notifier).installHealthConnect(),
                child: Text(l10n.healthIntegrationInstallHealthConnect),
              ),
            ],
            if (state.prefs.connected) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.healthIntegrationImportWeight),
                value: state.prefs.importWeight,
                activeThumbColor: context.accentColor,
                onChanged: state.loading
                    ? null
                    : (value) => ref.read(healthIntegrationProvider.notifier).setImportWeight(value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.healthIntegrationImportBodyFat),
                value: state.prefs.importBodyFat,
                activeThumbColor: context.accentColor,
                onChanged: state.loading
                    ? null
                    : (value) => ref.read(healthIntegrationProvider.notifier).setImportBodyFat(value),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: state.loading
                        ? null
                        : () async {
                            if (state.prefs.connected) {
                              await _sync();
                            } else {
                              final ok =
                                  await ref.read(healthIntegrationProvider.notifier).connect();
                              if (ok && mounted) await _sync(showNoUpdatesSnack: false);
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: context.accentColor,
                      foregroundColor: Colors.white,
                    ),
                    child: state.loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            state.prefs.connected
                                ? l10n.healthIntegrationSyncNow
                                : '${l10n.healthIntegrationConnect} (${_platformLabel()})',
                          ),
                  ),
                ),
                if (state.prefs.connected) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: state.loading
                        ? null
                        : () => ref.read(healthIntegrationProvider.notifier).disconnect(),
                    child: Text(l10n.healthIntegrationDisconnect),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
