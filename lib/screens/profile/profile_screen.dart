import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_locale.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/unit_converter.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/body_metric.dart';
import '../../models/profile.dart';
import '../../models/rest_timer_alert_mode.dart';
import '../../providers/app_providers.dart';
import '../../data/avatar_catalog.dart';
import '../../services/supabase_service.dart';
import '../../services/rest_preferences.dart';
import '../../services/ai_preferences.dart';
import '../../widgets/avatar_picker_sheet.dart';
import '../../widgets/body_metric_card.dart';
import '../../widgets/body_metric_health_legend.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/profile_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _scrollController = ScrollController();
  bool _trainerModeUpdating = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profileAsync = ref.watch(profileProvider);
    final metricsAsync = ref.watch(bodyMetricSnapshotsProvider);

    return Scaffold(
      appBar: FitForgeAppBar(
        title: l10n.profileTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: profileAsync.when(
        skipLoadingOnReload: true,
        data: (profile) {
          final unitSystem = ref.watch(unitSystemProvider);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(profileProvider);
              ref.invalidate(bodyMetricSnapshotsProvider);
            },
            child: ListView(
              key: const PageStorageKey<String>('profile_scroll'),
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          ProfileAvatar(
                            avatarUrl: profile?.avatarUrl,
                            radius: 44,
                            fallbackLetter: profile?.displayName,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Material(
                              color: AppColors.orange,
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: () => _pickAvatar(profile),
                                customBorder: const CircleBorder(),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.edit, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _pickAvatar(profile),
                        child: Text(l10n.changeAvatar),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    profile?.displayName ?? l10n.user,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 20),
                _SectionTitle(l10n.personalData),
                const SizedBox(height: 4),
                ListTile(
                  leading: const Icon(Icons.person_outline, color: AppColors.orange),
                  title: Text(l10n.displayName),
                  subtitle: Text(profile?.displayName ?? l10n.notDefined),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editDisplayName(profile),
                ),
                ListTile(
                  leading: const Icon(Icons.cake_outlined, color: AppColors.orange),
                  title: Text(l10n.age),
                  subtitle: Text(profile?.age != null ? '${profile!.age} ${l10n.years}' : l10n.notDefined),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editAge(profile),
                ),
                ListTile(
                  leading: const Icon(Icons.wc_outlined, color: AppColors.orange),
                  title: Text(l10n.gender),
                  subtitle: Text(l10n.genderLabel(profile?.gender)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editGender(profile),
                ),
                ListTile(
                  leading: const Icon(Icons.height, color: AppColors.orange),
                  title: Text(l10n.height),
                  subtitle: Text(
                    profile?.heightCm != null
                        ? UnitConverter.formatHeight(profile!.heightCm)
                        : l10n.notDefined,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editHeight(profile),
                ),
                ListTile(
                  leading: const Icon(Icons.language, color: AppColors.orange),
                  title: Text(l10n.preferredLanguage),
                  subtitle: Text(l10n.languageLabel(profile?.preferredLanguage ?? 'es')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editLanguage(profile),
                ),
                const SizedBox(height: 16),
                _SectionTitle(l10n.unitSystem),
                const SizedBox(height: 8),
                _UnitSelector(
                  unitSystem: unitSystem,
                  onChanged: (unit) async {
                    await ref.read(profileServiceProvider).updateUnitSystem(unit);
                    ref.invalidate(profileProvider);
                  },
                ),
                const SizedBox(height: 20),
                _SectionTitle(l10n.bodyMetrics),
                const SizedBox(height: 8),
                metricsAsync.when(
                  skipLoadingOnReload: true,
                  data: (snapshots) => Column(
                    children: [
                      _MetricsGrid(
                        snapshots: snapshots,
                        profile: profile,
                        unitSystem: unitSystem,
                        onEdit: (def) => _editMetric(profile, def, snapshots[def.key], unitSystem),
                      ),
                      const SizedBox(height: 12),
                      const BodyMetricHealthLegend(),
                    ],
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: FitForgeLoadingIndicator(size: 100)),
                  ),
                  error: (e, _) => Text(l10n.errorGeneric(e.toString())),
                ),
                const SizedBox(height: 24),
                _SectionTitle(l10n.trainingConfig),
                ListTile(
                  leading: const Icon(Icons.flag, color: AppColors.orange),
                  title: Text(l10n.goal),
                  subtitle: Text(l10n.goalLabel(profile?.fitnessGoal)),
                  onTap: () => _editGoal(profile),
                ),
                ListTile(
                  leading: const Icon(Icons.directions_walk, color: AppColors.orange),
                  title: Text(l10n.activityLevel),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.activityLevelLabel(profile?.activityLevel ?? DailyActivityLevel.moderate)),
                      Text(
                        l10n.activityLevelHint,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  onTap: () => _editActivityLevel(profile),
                ),
                ListTile(
                  leading: const Icon(Icons.trending_up, color: AppColors.orange),
                  title: Text(l10n.experienceLevel),
                  subtitle: Text(l10n.experienceLabel(profile?.experienceLevel)),
                  onTap: () => _editExperience(profile),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.school_outlined, color: AppColors.orange),
                  title: Text(l10n.personalTrainerMode),
                  subtitle: Text(l10n.personalTrainerModeSubtitle),
                  value: profile?.isTrainer ?? false,
                  activeThumbColor: AppColors.orange,
                  onChanged: _trainerModeUpdating ? null : (value) => _setTrainerMode(enabled: value),
                ),
                ref.watch(restTimerAlertModeProvider).when(
                  skipLoadingOnReload: true,
                  data: (mode) => ListTile(
                    leading: const Icon(Icons.timer_outlined, color: AppColors.orange),
                    title: Text(l10n.restTimerAlert),
                    subtitle: Text(l10n.restTimerAlertModeLabel(mode)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editRestTimerAlert(mode),
                  ),
                  loading: () => ListTile(
                    leading: const Icon(Icons.timer_outlined, color: AppColors.orange),
                    title: Text(l10n.restTimerAlert),
                    subtitle: Text(l10n.loading),
                  ),
                  error: (_, __) => ListTile(
                    leading: const Icon(Icons.timer_outlined, color: AppColors.orange),
                    title: Text(l10n.restTimerAlert),
                    subtitle: Text(l10n.notDefined),
                    onTap: () => _editRestTimerAlert(RestTimerAlertMode.both),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle(l10n.aiSection),
                ref.watch(aiProactiveEnabledProvider).when(
                  skipLoadingOnReload: true,
                  data: (enabled) => SwitchListTile(
                    secondary: const Icon(Icons.psychology_outlined, color: AppColors.orange),
                    title: Text(l10n.proactiveAi),
                    subtitle: Text(
                      enabled ? l10n.proactiveAiSubtitleOn : l10n.proactiveAiSubtitleOff,
                    ),
                    value: enabled,
                    activeThumbColor: AppColors.orange,
                    onChanged: (value) => _setProactiveAi(enabled: value, currentlyEnabled: enabled),
                  ),
                  loading: () => ListTile(
                    leading: const Icon(Icons.psychology_outlined, color: AppColors.orange),
                    title: Text(l10n.proactiveAi),
                    subtitle: Text(l10n.loading),
                  ),
                  error: (_, __) => SwitchListTile(
                    secondary: const Icon(Icons.psychology_outlined, color: AppColors.orange),
                    title: Text(l10n.proactiveAi),
                    subtitle: Text(l10n.proactiveAiSubtitleOff),
                    value: false,
                    activeThumbColor: AppColors.orange,
                    onChanged: (value) => _setProactiveAi(enabled: value, currentlyEnabled: false),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.key, color: AppColors.orange),
                  title: Text(l10n.apiKeys),
                  subtitle: Text(
                    profile?.hasAiKey == true
                        ? l10n.apiKeysConfigured(profile?.aiProvider.name ?? '')
                        : l10n.apiKeysNotConfigured,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/api-keys'),
                ),
                ListTile(
                  leading: const Icon(Icons.auto_awesome, color: AppColors.orange),
                  title: Text(l10n.coachAi),
                  subtitle: Text(l10n.aiCoachSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/ai-coach'),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    8,
                    0,
                    8,
                    16 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Text(
                    l10n.profileDedication,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted.withValues(alpha: 0.75),
                          height: 1.45,
                          fontSize: 11,
                        ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const FitForgeLoadingScreen(),
        error: (e, _) => Center(child: Text(l10n.errorGeneric(e.toString()))),
      ),
    );
  }

  Future<void> _pickAvatar(UserProfile? profile) async {
    final email = SupabaseService.currentUser?.email;
    final selected = await showAvatarPickerSheet(
      context,
      selectedId: profile?.avatarUrl,
      userEmail: email,
    );
    if (selected == null) return;
    if (!AvatarCatalog.canSelect(selected, email)) return;

    await ref.read(profileServiceProvider).updateProfile({'avatar_url': selected});
    ref.invalidate(profileProvider);
  }

  Future<void> _editDisplayName(UserProfile? profile) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: profile?.displayName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.displayNameTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 50,
          decoration: InputDecoration(hintText: l10n.displayName),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(l10n.displayNameRequired)),
                );
                return;
              }
              Navigator.pop(ctx, name);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref.read(profileServiceProvider).updateProfile({'display_name': result});
      ref.invalidate(profileProvider);
      ref.invalidate(leaderboardProvider);
    }
  }

  Future<void> _editAge(UserProfile? profile) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: profile?.age?.toString() ?? '');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.ageTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(suffixText: l10n.years),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (result != null && result > 0 && result < 120) {
      await ref.read(profileServiceProvider).updateProfile({'age': result});
      ref.invalidate(profileProvider);
    }
  }

  Future<void> _editGender(UserProfile? profile) async {
    final l10n = context.l10n;
    final selected = await showDialog<Gender>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.genderTitle),
        children: Gender.values
            .map(
              (g) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, g),
                child: Text(l10n.genderLabel(g)),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null) {
      await ref.read(profileServiceProvider).updateProfile({'gender': selected.code});
      ref.invalidate(profileProvider);
    }
  }

  Future<void> _editHeight(UserProfile? profile) async {
    final l10n = context.l10n;
    final cmController = TextEditingController(
      text: profile?.heightCm != null ? profile!.heightCm!.toStringAsFixed(0) : '',
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.heightTitle),
        content: TextField(
          controller: cmController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(suffixText: 'cm'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(cmController.text.replaceAll(',', '.'))),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result != null && result > 50 && result < 280) {
      await ref.read(profileServiceProvider).updateProfile({'height_cm': result});
      ref.invalidate(profileProvider);
    }
  }

  Future<void> _editLanguage(UserProfile? profile) async {
    final l10n = context.l10n;
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.languageTitle),
        children: AppLocale.supportedCodes
            .map(
              (code) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, code),
                child: Text(l10n.languageLabel(code)),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null && selected != profile?.preferredLanguage) {
      await ref.read(profileServiceProvider).updateProfile({'preferred_language': selected});
      ref.read(exerciseServiceProvider).configure(language: selected);
      ref.invalidate(profileProvider);
      ref.invalidate(exercisesProvider);
    }
  }

  Future<void> _editGoal(UserProfile? profile) async {
    final l10n = context.l10n;
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.fitnessGoalTitle),
        children: l10n.fitnessGoals
            .map((g) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, g), child: Text(g)))
            .toList(),
      ),
    );
    if (selected != null) {
      await ref.read(profileServiceProvider).updateProfile({
        'fitness_goal': l10n.canonicalGoal(selected),
      });
      ref.invalidate(profileProvider);
      ref.invalidate(dailyNutritionProvider);
    }
  }

  Future<void> _editExperience(UserProfile? profile) async {
    final l10n = context.l10n;
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.experienceTitle),
        children: l10n.experienceLevels
            .map((l) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, l), child: Text(l)))
            .toList(),
      ),
    );
    if (selected != null) {
      await ref.read(profileServiceProvider).updateProfile({
        'experience_level': l10n.canonicalExperience(selected),
      });
      ref.invalidate(profileProvider);
    }
  }

  Future<void> _editActivityLevel(UserProfile? profile) async {
    final l10n = context.l10n;
    final current = profile?.activityLevel ?? DailyActivityLevel.moderate;
    final selected = await showDialog<DailyActivityLevel>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.activityLevelTitle),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              l10n.activityLevelHint,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          ...l10n.activityLevels.map(
            (level) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, level),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.activityLevelLabel(level),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.activityLevelDescription(level),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Text(
              l10n.activityLevelFootnote,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.35),
            ),
          ),
        ],
      ),
    );
    if (selected != null && selected != current) {
      await ref.read(profileServiceProvider).updateProfile({
        'activity_level': selected.code,
      });
      ref.invalidate(profileProvider);
      ref.invalidate(dailyNutritionProvider);
    }
  }

  Future<void> _setProactiveAi({
    required bool enabled,
    required bool currentlyEnabled,
  }) async {
    if (enabled == currentlyEnabled) return;

    if (enabled) {
      final l10n = context.l10n;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.proactiveAiEnableTitle),
          content: Text(l10n.proactiveAiEnableMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.proactiveAiEnableConfirm),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
    }

    await AiPreferences.setProactiveAiEnabled(enabled);
    ref.invalidate(aiProactiveEnabledProvider);
  }

  Future<void> _setTrainerMode({required bool enabled}) async {
    if (_trainerModeUpdating) return;

    setState(() => _trainerModeUpdating = true);
    final l10n = context.l10n;

    try {
      await ref.read(profileServiceProvider).updateProfile({
        'user_type': enabled ? 'trainer' : 'athlete',
      });
      ref.invalidate(profileProvider);
      await ref.read(profileProvider.future);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled ? l10n.personalTrainerModeEnabled : l10n.personalTrainerModeDisabled,
          ),
        ),
      );

      if (enabled) {
        context.go('/students');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.personalTrainerModeFailed('$e')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _trainerModeUpdating = false);
    }
  }

  Future<void> _editRestTimerAlert(RestTimerAlertMode current) async {
    final l10n = context.l10n;
    final selected = await showDialog<RestTimerAlertMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.restTimerAlertTitle),
        children: RestTimerAlertMode.values
            .map(
              (mode) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, mode),
                child: Row(
                  children: [
                    if (mode == current)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.check, color: AppColors.orange, size: 20),
                      ),
                    Expanded(child: Text(l10n.restTimerAlertModeLabel(mode))),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null && selected != current) {
      await RestPreferences.setRestTimerAlertMode(selected);
      ref.invalidate(restTimerAlertModeProvider);
    }
  }

  Future<void> _editMetric(
    UserProfile? profile,
    BodyMetricDefinition def,
    BodyMetricSnapshot? snapshot,
    String unitSystem,
  ) async {
    if (def.isComputed) return;

    final l10n = context.l10n;
    String initialText = '';
    if (snapshot?.hasValue == true) {
      if (def.kind == BodyMetricKind.mass) {
        initialText = UnitConverter.kgToDisplay(snapshot!.valueKg!, unitSystem).toStringAsFixed(1);
      } else {
        final decimals = def.kind == BodyMetricKind.kcal || def.kind == BodyMetricKind.years ? 0 : 1;
        initialText = snapshot!.rawValue!.toStringAsFixed(decimals);
      }
    }

    final controller = TextEditingController(text: initialText);
    final suffix = def.kind == BodyMetricKind.mass
        ? UnitConverter.massLabel(unitSystem)
        : def.unitLabel(unitSystem, yearsLabel: l10n.years);

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.bodyMetricLabel(def.key)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            suffixText: suffix.isEmpty ? null : suffix,
            hintText: l10n.enterValue,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text.replaceAll(',', '.'))),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref.read(profileServiceProvider).saveBodyMetric(
            type: def.key,
            displayValue: result,
            unitSystem: unitSystem,
          );
      ref.invalidate(bodyMetricSnapshotsProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(bodyMeasurementsProvider);
    }
  }
}

class _UnitSelector extends StatelessWidget {
  final String unitSystem;
  final ValueChanged<String> onChanged;

  const _UnitSelector({required this.unitSystem, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _UnitChip(
              label: l10n.kilograms,
              shortLabel: 'kg',
              selected: unitSystem == 'kg',
              onTap: () => onChanged('kg'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _UnitChip(
              label: l10n.pounds,
              shortLabel: 'lb',
              selected: unitSystem == 'lb',
              onTap: () => onChanged('lb'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  final String label;
  final String shortLabel;
  final bool selected;
  final VoidCallback onTap;

  const _UnitChip({
    required this.label,
    required this.shortLabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.orange : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                shortLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? Colors.white70 : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final Map<String, BodyMetricSnapshot> snapshots;
  final UserProfile? profile;
  final String unitSystem;
  final void Function(BodyMetricDefinition def) onEdit;

  const _MetricsGrid({
    required this.snapshots,
    required this.profile,
    required this.unitSystem,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemCount: BodyMetricDefinition.all.length,
      itemBuilder: (context, index) {
        final def = BodyMetricDefinition.all[index];
        final snapshot = snapshots[def.key] ?? BodyMetricSnapshot(type: def.key);
        return BodyMetricCard(
          definition: def,
          displayLabel: l10n.bodyMetricLabel(def.key),
          snapshot: snapshot,
          unitSystem: unitSystem,
          yearsLabel: l10n.years,
          profile: profile,
          allSnapshots: snapshots,
          computedHint: def.isComputed ? l10n.metricCalculatedAutomatically : null,
          onTap: def.isComputed ? null : () => onEdit(def),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textMuted),
    );
  }
}
