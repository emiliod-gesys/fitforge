import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/l10n/app_locale.dart';
import '../../core/subscription/subscription_features.dart';
import '../../core/subscription/routine_limit_gate.dart';
import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/age_calculator.dart';
import '../../core/utils/unit_converter.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/body_metric.dart';
import '../../models/profile.dart';
import '../../models/rest_timer_alert_mode.dart';
import '../../providers/app_providers.dart';
import '../../providers/cloud_exercise_download_provider.dart';
import '../../providers/health_integration_provider.dart';
import '../../services/offline/cloud_exercise_download_service.dart';
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
import '../../widgets/profile/accent_color_selector.dart';
import '../../widgets/profile/delete_account_section.dart';
import '../../widgets/profile/health_integration_card.dart';
import '../../widgets/profile/subscription_tier_label.dart';
import '../../widgets/food/calorie_budget_editor_sheet.dart';
import '../../widgets/food/water_budget_editor_sheet.dart';
import '../../core/utils/water_goal_calculator.dart';
import '../../core/utils/bmr_calculator.dart';
import '../../core/utils/calorie_budget_adjustment.dart';
import '../../core/utils/daily_nutrition_budget.dart';
import '../../widgets/ff/ff_hub_tile.dart';
import '../../widgets/ff/ff_selectable_tile.dart';
import '../../widgets/ff/ff_list_row.dart';
import '../../widgets/ff/ff_section_header.dart';
import '../../widgets/ff/ff_surface.dart';

enum _ProfileSection {
  hub,
  personal,
  body,
  goals,
  nutrition,
  training,
  appearance,
  offline,
  account,
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _scrollController = ScrollController();
  bool _trainerModeUpdating = false;
  bool _hyroxModeUpdating = false;
  bool _runnerModeUpdating = false;
  _ProfileSection _section = _ProfileSection.hub;
  String? _sectionTitle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cloudExerciseDownloadProvider.notifier).refreshMeta(checkRemote: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openSection(_ProfileSection section, String title) {
    setState(() {
      _section = section;
      _sectionTitle = title;
    });
  }

  void _closeSection() {
    if (_section == _ProfileSection.hub) return;
    setState(() {
      _section = _ProfileSection.hub;
      _sectionTitle = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profileAsync = ref.watch(profileProvider);
    final metricsAsync = ref.watch(bodyMetricSnapshotsProvider);
    final inSection = _section != _ProfileSection.hub;

    return PopScope(
      canPop: !inSection,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeSection();
      },
      child: Scaffold(
        appBar: FitForgeAppBar(
          title: inSection ? (_sectionTitle ?? l10n.profileTitle) : l10n.profileTitle,
          showBrandMark: !inSection,
          leading: inSection
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _closeSection,
                )
              : null,
          automaticallyImplyLeading: !inSection,
          actions: [
            if (!inSection)
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
            if (inSection) {
              return switch (_section) {
                _ProfileSection.hub => const SizedBox.shrink(),
                _ProfileSection.personal => _personalSection(profile, unitSystem),
                _ProfileSection.body => _bodySection(profile, unitSystem, metricsAsync),
                _ProfileSection.goals => _goalsSection(profile),
                _ProfileSection.nutrition => _nutritionSection(profile, metricsAsync),
                _ProfileSection.training => _trainingSection(profile),
                _ProfileSection.appearance => _preferencesSection(profile),
                _ProfileSection.offline => _offlineSection(context),
                _ProfileSection.account => _accountSection(),
              };
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(profileProvider);
                ref.invalidate(bodyMetricSnapshotsProvider);
              },
              child: ListView(
                key: const PageStorageKey<String>('profile_scroll'),
                controller: _scrollController,
                padding: AppTokens.pagePaddingWithBottomInset(context),
                children: [
                  _buildHero(profile),
                  const SizedBox(height: AppTokens.space28),
                  FfSectionHeader(
                    title: l10n.profileHubTitle,
                    subtitle: l10n.profileHubSubtitle,
                  ),
                  FfHubTile(
                    icon: Icons.person_outline,
                    title: l10n.personalData,
                    subtitle: l10n.profileHubPersonalSubtitle,
                    onTap: () => _openSection(_ProfileSection.personal, l10n.personalData),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  FfHubTile(
                    icon: Icons.monitor_weight_outlined,
                    title: l10n.bodyMetrics,
                    subtitle: l10n.profileHubBodySubtitle,
                    onTap: () => _openSection(_ProfileSection.body, l10n.bodyMetrics),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  FfHubTile(
                    icon: Icons.track_changes_outlined,
                    title: l10n.profileHubGoalsTitle,
                    subtitle: l10n.profileHubGoalsSubtitle,
                    onTap: () => _openSection(_ProfileSection.goals, l10n.profileHubGoalsTitle),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  FfHubTile(
                    icon: Icons.restaurant_outlined,
                    title: l10n.profileHubNutritionTitle,
                    subtitle: l10n.profileHubNutritionSubtitle,
                    onTap: () => _openSection(
                      _ProfileSection.nutrition,
                      l10n.profileHubNutritionTitle,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  FfHubTile(
                    icon: Icons.fitness_center_outlined,
                    title: l10n.trainingConfig,
                    subtitle: l10n.profileHubTrainingSubtitle,
                    onTap: () => _openSection(_ProfileSection.training, l10n.trainingConfig),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  FfHubTile(
                    icon: Icons.palette_outlined,
                    title: l10n.profileHubAppearanceTitle,
                    subtitle: l10n.profileHubAppearanceSubtitle,
                    onTap: () => _openSection(
                      _ProfileSection.appearance,
                      l10n.profileHubAppearanceTitle,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  FfHubTile(
                    icon: Icons.cloud_download_outlined,
                    title: l10n.offlineDownloadExercisesTitle,
                    subtitle: l10n.profileHubOfflineSubtitle,
                    onTap: () => _openSection(
                      _ProfileSection.offline,
                      l10n.offlineDownloadExercisesTitle,
                    ),
                  ),
                  if (profile?.isTrainer ?? false) ...[
                    const SizedBox(height: AppTokens.space12),
                    FfHubTile(
                      icon: Icons.groups_outlined,
                      title: l10n.profileHubStudents,
                      subtitle: l10n.profileHubStudentsSubtitle,
                      onTap: () => context.go('/students'),
                    ),
                  ],
                  const SizedBox(height: AppTokens.space12),
                  FfHubTile(
                    icon: Icons.manage_accounts_outlined,
                    title: l10n.profileHubAccount,
                    subtitle: l10n.profileHubAccountSubtitle,
                    onTap: () => _openSection(_ProfileSection.account, l10n.profileHubAccount),
                  ),
                  const SizedBox(height: AppTokens.space32),
                  Text(
                    l10n.profileDedication,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted.withValues(alpha: 0.75),
                          height: 1.45,
                          fontSize: 11,
                        ),
                  ),
                  SizedBox(height: AppTokens.space24 + MediaQuery.paddingOf(context).bottom),
                ],
              ),
            );
          },
          loading: () => const FitForgeLoadingScreen(),
          error: (e, _) {
            final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
            if (!online) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.offlineProfileUnavailable,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              );
            }
            return Center(child: Text(l10n.errorGeneric(e.toString())));
          },
        ),
      ),
    );
  }

  void _leaveSectionAndGo(String location) {
    context.go(location);
  }

  Widget _buildHero(UserProfile? profile) {
    final l10n = context.l10n;
    final metaParts = [
      if (profile?.fitnessGoal != null) l10n.goalLabel(profile?.fitnessGoal),
      if (profile?.experienceLevel != null) l10n.experienceLabel(profile?.experienceLevel),
      if (profile != null) l10n.activityLevelLabel(profile.activityLevel),
    ];
    final meta = metaParts.join(' · ');
    return FfSurface(
      elevated: true,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [context.accentColor.withValues(alpha: 0.22), AppColors.cardElevated],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [context.accentColor, context.accentColor.withValues(alpha: 0.35)],
                  ),
                ),
                child: ProfileAvatar(
                  avatarUrl: profile?.avatarUrl,
                  radius: 48,
                  fallbackLetter: profile?.displayName,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: context.accentColor,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => _pickAvatar(profile),
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(AppTokens.space8),
                      child: Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space12),
          Text(
            profile?.displayName ?? l10n.user,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (profile != null) SubscriptionTierLabel(tier: profile.subscriptionTier),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: AppTokens.space4),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openSection(_ProfileSection.goals, l10n.profileHubGoalsTitle),
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space8,
                    vertical: AppTokens.space4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          meta,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: AppTokens.space4),
                      Icon(Icons.edit_outlined, size: 14, color: context.accentColor.withValues(alpha: 0.85)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionList(List<Widget> children) {
    return ListView(
      padding: AppTokens.pagePaddingWithBottomInset(context),
      children: [
        FfSurface(child: Column(children: children)),
        const SizedBox(height: AppTokens.space24),
      ],
    );
  }

  Widget _personalSection(UserProfile? profile, String unitSystem) {
    final l10n = context.l10n;
    final birthDate = profile?.dateOfBirth;
    final birthSubtitle = birthDate != null
        ? l10n.dateOfBirthSubtitle(
            DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(birthDate),
            profile?.effectiveAge ?? 0,
          )
        : profile?.effectiveAge != null
            ? '${profile!.effectiveAge} ${l10n.years}'
            : l10n.notDefined;
    return _sectionList([
      FfListRow(
        icon: Icons.person_outline,
        title: l10n.displayName,
        subtitle: profile?.displayName ?? l10n.notDefined,
        onTap: () => _editDisplayName(profile),
      ),
      FfListRow(
        icon: Icons.cake_outlined,
        title: l10n.dateOfBirthTitle,
        subtitle: birthSubtitle,
        onTap: () => _editDateOfBirth(profile),
      ),
      FfListRow(
        icon: Icons.wc_outlined,
        title: l10n.gender,
        subtitle: l10n.genderLabel(profile?.gender),
        onTap: () => _editGender(profile),
      ),
      FfListRow(
        icon: Icons.height,
        title: l10n.height,
        subtitle: profile?.heightCm != null
            ? UnitConverter.formatHeight(profile!.heightCm)
            : l10n.notDefined,
        onTap: () => _editHeight(profile),
      ),
      FfListRow(
        icon: Icons.language,
        title: l10n.preferredLanguage,
        subtitle: l10n.languageLabel(profile?.preferredLanguage ?? 'es'),
        onTap: () => _editLanguage(profile),
      ),
      const SizedBox(height: AppTokens.space20),
      FfSectionHeader(title: l10n.unitSystem),
      _UnitSelector(
        unitSystem: unitSystem,
        onChanged: (unit) async {
          await ref.read(profileServiceProvider).updateUnitSystem(unit);
          ref.invalidate(profileProvider);
        },
      ),
    ]);
  }

  Widget _bodySection(
    UserProfile? profile,
    String unitSystem,
    AsyncValue<Map<String, BodyMetricSnapshot>> metricsAsync,
  ) {
    final l10n = context.l10n;
    return _sectionList([
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
            const SizedBox(height: AppTokens.space16),
            const BodyMetricHealthLegend(),
            const SizedBox(height: AppTokens.space20),
            HealthIntegrationCard(profile: profile),
          ],
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(AppTokens.space32),
          child: Center(child: FitForgeLoadingIndicator(size: 100)),
        ),
        error: (e, _) => Text(l10n.errorGeneric(e.toString())),
      ),
    ]);
  }

  Widget _goalsSection(UserProfile? profile) {
    final l10n = context.l10n;
    return _sectionList([
      FfListRow(
        icon: Icons.flag_outlined,
        title: l10n.goal,
        subtitle: l10n.goalLabel(profile?.fitnessGoal),
        onTap: () => _editGoal(profile),
      ),
      FfListRow(
        icon: Icons.trending_up,
        title: l10n.experienceLevel,
        subtitle: l10n.experienceLabel(profile?.experienceLevel),
        onTap: () => _editExperience(profile),
      ),
      FfListRow(
        icon: Icons.directions_walk_outlined,
        title: l10n.activityLevel,
        subtitle: l10n.activityLevelLabel(profile?.activityLevel ?? DailyActivityLevel.moderate),
        onTap: () => _editActivityLevel(profile),
      ),
    ]);
  }

  Widget _nutritionSection(
    UserProfile? profile,
    AsyncValue<Map<String, BodyMetricSnapshot>> metricsAsync,
  ) {
    final l10n = context.l10n;
    final bodyMetrics = metricsAsync.valueOrNull;
    final useFlOz = UnitConverter.isLb(profile?.unitSystem ?? 'kg');
    final suggested = WaterGoalCalculator.suggestedGoalMl(
      profile: profile,
      bodyMetrics: bodyMetrics,
    );
    final waterGoal = WaterGoalCalculator.goalMl(
      profile: profile,
      bodyMetrics: bodyMetrics,
    );
    final waterSubtitle = profile?.waterGoalMl == null
        ? l10n.profileNutritionWaterSuggested(
            WaterGoalCalculator.formatVolume(suggested, useFlOz: useFlOz),
          )
        : l10n.profileNutritionWaterCurrent(
            WaterGoalCalculator.formatVolume(waterGoal, useFlOz: useFlOz),
          );

    final bmr = BmrCalculator.calculate(profile: profile, snapshots: bodyMetrics);
    String calorieSubtitle = l10n.profileNutritionCaloriesSubtitle;
    if (bmr != null) {
      final tdee = DailyNutritionBudget.computeTdee(
        bmr: bmr,
        activityLevel: profile?.activityLevel ?? DailyActivityLevel.moderate,
      );
      final pct = CalorieBudgetAdjustment.resolvedPercent(
        profile?.fitnessGoal,
        profile?.calorieAdjustmentPct,
      );
      final goalKcal = CalorieBudgetAdjustment.goalFromTdee(tdee, pct);
      calorieSubtitle = '$goalKcal kcal · ${l10n.profileNutritionCaloriesSubtitle}';
    }

    return _sectionList([
      FfListRow(
        icon: Icons.local_fire_department_outlined,
        title: l10n.profileNutritionCaloriesTitle,
        subtitle: calorieSubtitle,
        onTap: () => CalorieBudgetEditorSheet.show(
          context,
          profile: profile,
          bodyMetrics: bodyMetrics,
          onSaved: () {
            ref.invalidate(profileProvider);
            ref.invalidate(dailyNutritionProvider);
          },
        ),
      ),
      FfListRow(
        icon: Icons.water_drop_outlined,
        title: l10n.profileNutritionWaterTitle,
        subtitle: waterSubtitle,
        onTap: () => WaterBudgetEditorSheet.show(
          context,
          profile: profile,
          bodyMetrics: bodyMetrics,
          onSaved: () {
            ref.invalidate(profileProvider);
            ref.invalidate(waterEntriesProvider);
          },
        ),
      ),
    ]);
  }

  Widget _trainingSection(UserProfile? profile) {
    final l10n = context.l10n;
    return _sectionList([
      SwitchListTile(
        secondary: Icon(Icons.school_outlined, color: context.accentColor),
        title: Text(l10n.personalTrainerMode),
        subtitle: Text(
          (profile?.subscriptionTier.hasTrainerMode ?? false)
              ? l10n.personalTrainerModeSubtitle
              : l10n.featureGymratProOnly,
        ),
        value: (profile?.isTrainer ?? false) &&
            (profile?.subscriptionTier.hasTrainerMode ?? false),
        activeThumbColor: context.accentColor,
        onChanged: (profile?.subscriptionTier.hasTrainerMode ?? false) && !_trainerModeUpdating
            ? (value) => _setTrainerMode(enabled: value)
            : null,
      ),
      SwitchListTile(
        secondary: Icon(Icons.directions_run, color: context.accentColor),
        title: Text(l10n.hyroxMode),
        subtitle: Text(l10n.hyroxModeSubtitle),
        value: profile?.hyroxMode ?? false,
        activeThumbColor: context.accentColor,
        onChanged: _hyroxModeUpdating ? null : (value) => _setHyroxMode(enabled: value, profile: profile),
      ),
      SwitchListTile(
        secondary: Icon(Icons.nordic_walking, color: context.accentColor),
        title: Text(l10n.runnerMode),
        subtitle: Text(l10n.runnerModeSubtitle),
        value: profile?.runnerMode ?? false,
        activeThumbColor: context.accentColor,
        onChanged: _runnerModeUpdating ? null : (value) => _setRunnerMode(enabled: value, profile: profile),
      ),
      ref.watch(restTimerAlertModeProvider).when(
            skipLoadingOnReload: true,
            data: (mode) => FfListRow(
              icon: Icons.timer_outlined,
              title: l10n.restTimerAlert,
              subtitle: l10n.restTimerAlertModeLabel(mode),
              onTap: () => _editRestTimerAlert(mode),
            ),
            loading: () => FfListRow(
              icon: Icons.timer_outlined,
              title: l10n.restTimerAlert,
              subtitle: l10n.restTimerAlertModeLabel(RestTimerAlertMode.both),
              onTap: () => _editRestTimerAlert(RestTimerAlertMode.both),
            ),
            error: (_, __) => FfListRow(
              icon: Icons.timer_outlined,
              title: l10n.restTimerAlert,
              subtitle: l10n.restTimerAlertModeLabel(RestTimerAlertMode.both),
              onTap: () => _editRestTimerAlert(RestTimerAlertMode.both),
            ),
          ),
    ]);
  }

  Widget _preferencesSection(UserProfile? profile) {
    final l10n = context.l10n;
    final accent = ref.watch(accentProvider);
    final proactiveEnabled = ref.watch(aiProactiveEnabledProvider).valueOrNull ?? false;
    return ListView(
      padding: AppTokens.pagePaddingWithBottomInset(context),
      children: [
        FfSurface(
          child: Column(
            children: [
              _proactiveAiTile(profile, proactiveEnabled),
              FfListRow(
                icon: Icons.auto_awesome,
                title: l10n.coachAi,
                subtitle: l10n.aiCoachSubtitle,
                onTap: () => _leaveSectionAndGo('/ai-coach'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space20),
        FfSectionHeader(
          title: l10n.accentColor,
          subtitle: (profile?.subscriptionTier.hasCustomAccent ?? false)
              ? l10n.accentColorHint
              : l10n.featureGymratPlansOnly,
        ),
        FfSurface(
          child: AccentColorSelector(
            selected: accent,
            lockedMessage: l10n.featureGymratPlansOnly,
            onChanged: (profile?.subscriptionTier.hasCustomAccent ?? false)
                ? (value) async {
                    await ref.read(profileServiceProvider).updateProfile({'accent_color': value.name});
                    ref.invalidate(profileProvider);
                  }
                : null,
          ),
        ),
        if (profile?.subscriptionTier.isFree ?? true) ...[
          const SizedBox(height: AppTokens.space20),
          FfSurface(child: _FreeAdvancedSettings(profile: profile)),
        ],
        const SizedBox(height: AppTokens.space24),
      ],
    );
  }

  Widget _proactiveAiTile(UserProfile? profile, bool enabled) {
    final l10n = context.l10n;
    final canProactive = profile?.canUseProactiveAi ?? false;
    return SwitchListTile(
      secondary: Icon(
        Icons.psychology_outlined,
        color: canProactive ? context.accentColor : AppColors.textMuted,
      ),
      title: Text(l10n.proactiveAi),
      subtitle: Text(l10n.proactiveAiDescription),
      value: canProactive && enabled,
      activeThumbColor: context.accentColor,
      onChanged: canProactive
          ? (value) => _setProactiveAi(enabled: value, currentlyEnabled: enabled)
          : null,
    );
  }

  Widget _offlineSection(BuildContext pageContext) {
    return _sectionList([_buildCloudExerciseDownloadSection(pageContext)]);
  }

  Widget _accountSection() {
    return _sectionList([
      const DeleteAccountSection(),
    ]);
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

  Future<void> _editDateOfBirth(UserProfile? profile) async {
    final now = DateTime.now();
    final initial = profile?.dateOfBirth ??
        (profile?.effectiveAge != null
            ? AgeCalculator.estimateDateOfBirthFromAge(profile!.effectiveAge!)
            : DateTime(now.year - 25, now.month, now.day));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 119, 1, 1),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      helpText: context.l10n.dateOfBirthTitle,
    );
    if (picked == null) return;
    if (!AgeCalculator.isValidDateOfBirth(picked)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.dateOfBirthInvalid)),
      );
      return;
    }
    await ref.read(profileServiceProvider).updateProfile({
      'date_of_birth': AgeCalculator.toDateString(picked),
      'age': AgeCalculator.yearsFromDateOfBirth(picked),
    });
    ref.invalidate(profileProvider);
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
    final accent = context.accentColor;
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardElevated,
        shape: RoundedRectangleBorder(borderRadius: AppTokens.borderRadiusXl),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Text(
                  l10n.fitnessGoalTitle,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Text(
                  l10n.fitnessGoalHint,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.35),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ...l10n.fitnessGoals.map((goal) {
                      final canonical = l10n.canonicalGoal(goal);
                      return FfSelectableTile(
                        title: goal,
                        badge: l10n.fitnessGoalCalorieModeLabel(goal),
                        subtitle:
                            '${l10n.fitnessGoalTrainingLabel}: ${l10n.fitnessGoalTrainingDescription(goal)}\n'
                            '${l10n.fitnessGoalDietLabel}: ${l10n.fitnessGoalDietDescription(goal)}',
                        selected: profile?.fitnessGoal == canonical,
                        accent: accent,
                        onTap: () => Navigator.pop(ctx, goal),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                      child: Text(
                        l10n.fitnessGoalFootnote,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    final accent = context.accentColor;
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardElevated,
        shape: RoundedRectangleBorder(borderRadius: AppTokens.borderRadiusXl),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  l10n.experienceTitle,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: AppTokens.space12),
              ...l10n.experienceLevels.map((level) {
                final canonical = l10n.canonicalExperience(level);
                return FfSelectableTile(
                  title: level,
                  selected: profile?.experienceLevel == canonical,
                  accent: accent,
                  onTap: () => Navigator.pop(ctx, level),
                );
              }),
            ],
          ),
        ),
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
    final accent = context.accentColor;
    final current = profile?.activityLevel ?? DailyActivityLevel.moderate;
    final selected = await showDialog<DailyActivityLevel>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardElevated,
        shape: RoundedRectangleBorder(borderRadius: AppTokens.borderRadiusXl),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  l10n.activityLevelTitle,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: Text(
                  l10n.activityLevelHint,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.35),
                ),
              ),
              ...l10n.activityLevels.map(
                (level) => FfSelectableTile(
                  title: l10n.activityLevelLabel(level),
                  subtitle: l10n.activityLevelDescription(level),
                  selected: current == level,
                  accent: accent,
                  onTap: () => Navigator.pop(ctx, level),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Text(
                  l10n.activityLevelFootnote,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.35),
                ),
              ),
            ],
          ),
        ),
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
                backgroundColor: context.accentColor,
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

  Future<void> _setHyroxMode({
    required bool enabled,
    required UserProfile? profile,
  }) async {
    if (_hyroxModeUpdating || profile == null) return;
    setState(() => _hyroxModeUpdating = true);
    final l10n = context.l10n;

    try {
      await ref.read(hyroxServiceProvider).setHyroxMode(
            enabled: enabled,
            profile: profile,
          );
      ref.invalidate(profileProvider);
      ref.invalidate(routinesProvider);
      ref.invalidate(routineLimitStatusProvider);
      await ref.read(profileProvider.future);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled ? l10n.hyroxModeEnabled : l10n.hyroxModeDisabled),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric('$e'))),
      );
    } finally {
      if (mounted) setState(() => _hyroxModeUpdating = false);
    }
  }

  Future<void> _setRunnerMode({
    required bool enabled,
    required UserProfile? profile,
  }) async {
    if (_runnerModeUpdating || profile == null) return;
    setState(() => _runnerModeUpdating = true);
    final l10n = context.l10n;

    try {
      await ref.read(runnerServiceProvider).setRunnerMode(
            enabled: enabled,
            profile: profile,
          );
      ref.invalidate(profileProvider);
      ref.invalidate(routinesProvider);
      ref.invalidate(routineLimitStatusProvider);
      await ref.read(profileProvider.future);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled ? l10n.runnerModeEnabled : l10n.runnerModeDisabled),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _runnerModeUpdating = false);
    }
  }

  Widget _buildCloudExerciseDownloadSection(BuildContext context) {
    final l10n = context.l10n;
    final download = ref.watch(cloudExerciseDownloadProvider);
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;

    final subtitle = switch (download.cachedCount) {
      > 0 when download.isUpToDate =>
        l10n.offlineDownloadExercisesSubtitleUpToDate(download.cachedCount),
      > 0 when download.pendingUpdateCount > 0 =>
        l10n.offlineDownloadExercisesSubtitleUpdates(
          download.cachedCount,
          download.pendingUpdateCount,
        ),
      > 0 => l10n.offlineDownloadExercisesSubtitleDone(download.cachedCount),
      _ => l10n.offlineDownloadExercisesSubtitleEmpty,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.cloud_download_outlined, color: context.accentColor),
          title: Text(l10n.offlineDownloadExercisesTitle),
          subtitle: Text(subtitle),
          trailing: download.isDownloading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.accentColor,
                  ),
                )
              : const Icon(Icons.chevron_right),
          enabled: online && !download.isDownloading,
          onTap: online && !download.isDownloading
              ? () => _downloadCloudExercises(context)
              : null,
        ),
        if (download.isDownloading) ...[
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: download.progress,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            backgroundColor: AppColors.border,
            color: context.accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _downloadProgressLabel(l10n, download),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Future<void> _downloadCloudExercises(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(cloudExerciseDownloadProvider.notifier);

    CloudExerciseDownloadStatus status;
    try {
      status = await notifier.analyzeStatus();
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.offlineDownloadExercisesFailed('$e'))),
      );
      return;
    }

    if (!context.mounted) return;

    if (status.isUpToDate && status.hasLocalCache) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.offlineDownloadExercisesUpToDate(status.localCount, status.localMediaCount),
          ),
        ),
      );
      await notifier.refreshMeta(checkRemote: true);
      return;
    }

    if (status.hasLocalCache && status.pendingCount > 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.offlineDownloadExercisesConfirmTitle),
          content: Text(
            l10n.offlineDownloadExercisesConfirmBody(
              status.localCount,
              status.missingExerciseCount,
              status.missingMediaCount,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.offlineDownloadExercisesConfirmAction),
            ),
          ],
        ),
      );
      if (proceed != true || !context.mounted) return;
    }

    try {
      final result = await notifier.download();
      if (!context.mounted) return;

      if (result.newlyDownloadedExercises == 0 && result.newlyDownloadedMedia == 0) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.offlineDownloadExercisesUpToDate(result.exerciseCount, result.mediaCount))),
        );
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.offlineDownloadExercisesDoneIncremental(
              result.exerciseCount,
              result.mediaCount,
              result.newlyDownloadedExercises,
              result.newlyDownloadedMedia,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.offlineDownloadExercisesFailed('$e'))),
      );
    }
  }

  String _downloadProgressLabel(AppLocalizations l10n, CloudExerciseDownloadState download) {
    if (download.phase == CloudExerciseDownloadPhase.media) {
      if (download.total != null) {
        return l10n.offlineDownloadExercisesProgressMedia(download.downloaded, download.total!);
      }
      return l10n.offlineDownloadExercisesProgressMediaUnknown(download.downloaded);
    }
    if (download.total != null) {
      return l10n.offlineDownloadExercisesProgress(download.downloaded, download.total!);
    }
    return l10n.offlineDownloadExercisesProgressUnknown(download.downloaded);
  }

  Future<void> _setTrainerMode({
    required bool enabled,
  }) async {
    if (_trainerModeUpdating) return;

    final profile = ref.read(profileProvider).value;
    if (enabled && !(profile?.subscriptionTier.hasTrainerMode ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.featureGymratProOnly)),
      );
      return;
    }

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
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.check, color: context.accentColor, size: 20),
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
      if (def.key == 'weight') {
        await ref.read(healthImportStoreProvider).recordManualWeightEdit();
      }
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
      color: selected ? context.accentColor : Colors.transparent,
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
        childAspectRatio: 1.22,
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

/// Ajustes avanzados visibles solo en plan gratuito (p. ej. API key propia).
class _FreeAdvancedSettings extends StatefulWidget {
  final UserProfile? profile;

  const _FreeAdvancedSettings({required this.profile});

  @override
  State<_FreeAdvancedSettings> createState() => _FreeAdvancedSettingsState();
}

class _FreeAdvancedSettingsState extends State<_FreeAdvancedSettings> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const muted = AppColors.textMuted;
    final profile = widget.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.advancedSettings,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: muted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.advancedSettingsHint,
                        style: TextStyle(color: muted.withValues(alpha: 0.85), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: muted.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: const Icon(Icons.key_outlined, color: muted),
            title: Text(l10n.bringYourOwnAi),
            subtitle: Text(
              profile?.hasAiKey == true
                  ? l10n.apiKeysConfigured(profile?.aiProvider.name ?? '')
                  : l10n.bringYourOwnAiSubtitle,
              style: TextStyle(color: muted.withValues(alpha: 0.85), fontSize: 13),
            ),
            trailing: Icon(Icons.chevron_right, color: muted.withValues(alpha: 0.7)),
            onTap: () => context.push('/api-keys'),
          ),
      ],
    );
  }
}
