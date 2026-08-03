import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_locale.dart';
import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/age_calculator.dart';
import '../../core/utils/unit_converter.dart';
import '../../data/avatar_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../../providers/cloud_exercise_download_provider.dart';
import '../../providers/onboarding_progress_provider.dart';
import '../../services/offline/cloud_exercise_download_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/avatar_picker_sheet.dart';
import '../../widgets/fitforge_logo.dart';
import '../../widgets/profile_avatar.dart';
import 'onboarding_plan_step.dart';

enum _OnboardingStepKind {
  language,
  aboutYou,
  body,
  goals,
  modes,
  offlineCatalog,
  plan,
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _nameController;

  late int _pageIndex;
  late final PageController _pageController;
  Gender? _gender;
  DateTime? _dateOfBirth;
  String _unitSystem = 'kg';
  String? _fitnessGoal;
  String? _experienceLevel;
  DailyActivityLevel _activityLevel = DailyActivityLevel.moderate;
  bool _hyroxMode = false;
  bool _runnerMode = false;
  bool _busy = false;
  String _preferredLanguage = AppLocale.defaultCode;
  late String _selectedAvatarId;
  SubscriptionTier _selectedPlan = SubscriptionTier.gymratPro;
  bool _offlineDecisionMade = false;

  final _formKeyBasics = GlobalKey<FormState>();
  final _formKeyBody = GlobalKey<FormState>();

  List<_OnboardingStepKind> get _steps {
    final profile = ref.read(profileProvider).valueOrNull;
    final isTrainer = profile?.isTrainer ?? false;
    return [
      _OnboardingStepKind.language,
      _OnboardingStepKind.aboutYou,
      _OnboardingStepKind.body,
      _OnboardingStepKind.goals,
      if (!isTrainer) _OnboardingStepKind.modes,
      _OnboardingStepKind.offlineCatalog,
      _OnboardingStepKind.plan,
    ];
  }

  _OnboardingStepKind get _currentStep => _steps[_pageIndex];

  @override
  void initState() {
    super.initState();
    final saved = ref.read(onboardingProgressProvider).stepIndex;
    _pageIndex = saved.clamp(0, _steps.length - 1);
    if (saved != _pageIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(onboardingProgressProvider.notifier).setStepIndex(_pageIndex);
      });
    }
    _pageController = PageController(initialPage: _pageIndex);
    _selectedAvatarId = AvatarCatalog.toStorageId(AvatarCatalog.defaultOption().id);
    _nameController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
  }

  bool _seededFromProfile = false;

  void _seedFromProfile(UserProfile? profile) {
    if (_seededFromProfile || profile == null) return;
    _seededFromProfile = true;
    _nameController.text = profile.displayName ?? '';
    _dateOfBirth = profile.dateOfBirth ??
        (profile.age != null ? AgeCalculator.estimateDateOfBirthFromAge(profile.age!) : null);
    _heightController.text =
        profile.heightCm != null ? profile.heightCm!.toStringAsFixed(0) : '';
    _unitSystem = profile.unitSystem;
    _gender = profile.gender;
    if (profile.bodyWeight != null) {
      _weightController.text =
          UnitConverter.kgToDisplay(profile.bodyWeight!, _unitSystem).toStringAsFixed(1);
    }
    if (profile.fitnessGoal != null) _fitnessGoal = profile.fitnessGoal;
    if (profile.experienceLevel != null) _experienceLevel = profile.experienceLevel;
    _activityLevel = profile.activityLevel;
    _preferredLanguage = profile.preferredLanguage;
    _hyroxMode = profile.hyroxMode;
    _runnerMode = profile.runnerMode;
    if (AvatarCatalog.isCatalogValue(profile.avatarUrl)) {
      _selectedAvatarId = profile.avatarUrl!;
    }
  }

  Future<void> _pickAvatar() async {
    if (_busy) return;
    final email = SupabaseService.currentUser?.email;
    final selected = await showAvatarPickerSheet(
      context,
      selectedId: _selectedAvatarId,
      userEmail: email,
    );
    if (selected == null || !mounted) return;
    if (!AvatarCatalog.canSelect(selected, email)) return;
    setState(() => _selectedAvatarId = selected);
  }

  Future<void> _setLanguage(String code) async {
    if (_preferredLanguage == code) return;
    setState(() => _preferredLanguage = code);
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(profileServiceProvider).updateProfile({'preferred_language': code});
      ref.read(exerciseServiceProvider).configure(language: code);
      ref.invalidate(profileProvider);
      ref.invalidate(exercisesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onUnitChanged(String unit) {
    final currentKg = _parseWeightKg();
    setState(() => _unitSystem = unit);
    if (currentKg != null) {
      _weightController.text = UnitConverter.kgToDisplay(currentKg, unit).toStringAsFixed(1);
    }
  }

  double? _parseWeightKg() {
    final display = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (display == null) return null;
    return UnitConverter.displayToKg(display, _unitSystem);
  }

  Future<void> _goNextPage() async {
    if (_pageIndex >= _steps.length - 1) return;
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _next() async {
    final l10n = context.l10n;
    final step = _currentStep;

    if (step == _OnboardingStepKind.aboutYou) {
      if (_gender == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genderRequired)));
        return;
      }
      if (_dateOfBirth == null || !AgeCalculator.isValidDateOfBirth(_dateOfBirth!)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dateOfBirthInvalid)));
        return;
      }
      if (!_formKeyBasics.currentState!.validate()) return;
      await _goNextPage();
      return;
    }

    if (step == _OnboardingStepKind.body) {
      if (!_formKeyBody.currentState!.validate()) return;
      await _goNextPage();
      return;
    }

    if (step == _OnboardingStepKind.goals) {
      if (_fitnessGoal == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.onboardingSelectGoal)));
        return;
      }
      if (_experienceLevel == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.onboardingSelectExperience)));
        return;
      }
      try {
        await _saveProfileDraft();
      } catch (_) {
        return;
      }
      await _goNextPage();
      return;
    }

    if (step == _OnboardingStepKind.offlineCatalog) {
      setState(() => _offlineDecisionMade = true);
      await _goNextPage();
      return;
    }

    if (step == _OnboardingStepKind.plan) {
      await _finishOnboarding();
      return;
    }

    await _goNextPage();
  }

  void _back() {
    if (_pageIndex == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _saveProfileDraft() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final name = _nameController.text.trim();
      final dob = _dateOfBirth!;
      final heightCm = double.parse(_heightController.text.replaceAll(',', '.'));
      final weightKg = _parseWeightKg()!;

      final profileService = ref.read(profileServiceProvider);
      await profileService.updateProfile({
        'display_name': name,
        'search_name': name.toLowerCase(),
        'date_of_birth': AgeCalculator.toDateString(dob),
        'age': AgeCalculator.yearsFromDateOfBirth(dob),
        'gender': _gender!.code,
        'height_cm': heightCm,
        'unit_system': _unitSystem,
        'fitness_goal': _fitnessGoal,
        'experience_level': _experienceLevel,
        'activity_level': _activityLevel.code,
        'preferred_language': _preferredLanguage,
        'avatar_url': _selectedAvatarId,
      });
      await profileService.saveBodyMetric(
        type: 'weight',
        displayValue: UnitConverter.kgToDisplay(weightKg, _unitSystem),
        unitSystem: _unitSystem,
      );

      ref.invalidate(profileProvider);
      ref.invalidate(bodyMetricSnapshotsProvider);
      ref.invalidate(dailyNutritionProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric('$e'))),
        );
      }
      rethrow;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startOfflineDownload() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final online = ref.read(isOnlineProvider).valueOrNull ?? true;
    if (!online) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric(l10n.onboardingOfflineSkip))));
      return;
    }

    final notifier = ref.read(cloudExerciseDownloadProvider.notifier);
    if (ref.read(cloudExerciseDownloadProvider).isDownloading) {
      setState(() => _offlineDecisionMade = true);
      await _goNextPage();
      return;
    }

    setState(() => _busy = true);
    try {
      final status = await notifier.analyzeStatus();
      if (!mounted) return;
      if (!(status.isUpToDate && status.hasLocalCache)) {
        // Fire-and-forget so the user can continue onboarding.
        unawaited(() async {
          try {
            await notifier.download();
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.offlineDownloadExercisesFailed('$e'))),
            );
          }
        }());
      }
      setState(() => _offlineDecisionMade = true);
      await _goNextPage();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.offlineDownloadExercisesFailed('$e'))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishOnboarding() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    try {
      // Re-save in case the user edited fields after the goals step.
      if (_dateOfBirth != null && _gender != null && _fitnessGoal != null) {
        await _saveProfileDraftQuiet();
      }

      await ref.read(profileServiceProvider).updateProfile({
        'onboarding_completed_at': DateTime.now().toUtc().toIso8601String(),
        // Paid tiers require IAP — keep free until billing ships.
        'subscription_tier': SubscriptionTier.free.code,
      });

      ref.invalidate(profileProvider);
      final profile = await ref.read(profileProvider.future);
      if (profile != null) {
        if (_hyroxMode && !profile.hyroxMode) {
          await ref.read(hyroxServiceProvider).setHyroxMode(enabled: true, profile: profile);
        }
        if (_runnerMode && !profile.runnerMode) {
          await ref.read(runnerServiceProvider).setRunnerMode(enabled: true, profile: profile);
        }
      }

      ref.invalidate(profileProvider);
      ref.invalidate(routinesProvider);
      ref.invalidate(dailyNutritionProvider);
      ref.invalidate(leaderboardProvider);
      ref.invalidate(bodyMetricSnapshotsProvider);
      ref.read(onboardingProgressProvider.notifier).reset();

      if (!mounted) return;
      if (!_selectedPlan.isFree) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.onboardingPlanPaidSoon)),
        );
      }
      context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveProfileDraftQuiet() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _dateOfBirth == null || _gender == null) return;
    final heightCm = double.tryParse(_heightController.text.replaceAll(',', '.'));
    final weightKg = _parseWeightKg();
    if (heightCm == null || weightKg == null) return;

    final profileService = ref.read(profileServiceProvider);
    await profileService.updateProfile({
      'display_name': name,
      'search_name': name.toLowerCase(),
      'date_of_birth': AgeCalculator.toDateString(_dateOfBirth!),
      'age': AgeCalculator.yearsFromDateOfBirth(_dateOfBirth!),
      'gender': _gender!.code,
      'height_cm': heightCm,
      'unit_system': _unitSystem,
      'fitness_goal': _fitnessGoal,
      'experience_level': _experienceLevel,
      'activity_level': _activityLevel.code,
      'preferred_language': _preferredLanguage,
      'avatar_url': _selectedAvatarId,
    });
    await profileService.saveBodyMetric(
      type: 'weight',
      displayValue: UnitConverter.kgToDisplay(weightKg, _unitSystem),
      unitSystem: _unitSystem,
    );
  }

  String _planCtaLabel(AppLocalizations l10n) {
    return switch (_selectedPlan) {
      SubscriptionTier.free => l10n.onboardingPlanSelectFree,
      SubscriptionTier.gymrat => l10n.onboardingPlanSelectGymrat,
      SubscriptionTier.gymratPro => l10n.onboardingPlanSelectGymratPro,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = context.accentColor;
    final profile = ref.watch(profileProvider).valueOrNull;
    _seedFromProfile(profile);
    final steps = _steps;
    if (_pageIndex >= steps.length) {
      _pageIndex = steps.length - 1;
    }
    final isPlan = _currentStep == _OnboardingStepKind.plan;
    final isOffline = _currentStep == _OnboardingStepKind.offlineCatalog;
    final showBack = _pageIndex > 0;
    final download = ref.watch(cloudExerciseDownloadProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF121316),
                AppColors.black,
                Color(0xFF0A0A0C),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      const FitForgeLogo(height: 28),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.cardElevated,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
                        ),
                        child: Text(
                          l10n.onboardingStepOf(_pageIndex + 1, steps.length),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (_pageIndex + 1) / steps.length,
                      backgroundColor: AppColors.border.withValues(alpha: 0.45),
                      color: accent,
                      minHeight: 5,
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: steps.length,
                    onPageChanged: (index) {
                      setState(() => _pageIndex = index);
                      ref.read(onboardingProgressProvider.notifier).setStepIndex(index);
                    },
                    itemBuilder: (context, index) {
                      return switch (steps[index]) {
                        _OnboardingStepKind.language => _LanguageStep(
                            l10n: l10n,
                            accent: accent,
                            preferredLanguage: _preferredLanguage,
                            onLanguageChanged: _setLanguage,
                          ),
                        _OnboardingStepKind.aboutYou => _AboutYouStep(
                            l10n: l10n,
                            accent: accent,
                            formKey: _formKeyBasics,
                            nameController: _nameController,
                            dateOfBirth: _dateOfBirth,
                            gender: _gender,
                            selectedAvatarId: _selectedAvatarId,
                            onGenderChanged: (g) => setState(() => _gender = g),
                            onDateOfBirthChanged: (d) => setState(() => _dateOfBirth = d),
                            onPickAvatar: _pickAvatar,
                          ),
                        _OnboardingStepKind.body => _BodyStep(
                            l10n: l10n,
                            formKey: _formKeyBody,
                            heightController: _heightController,
                            weightController: _weightController,
                            unitSystem: _unitSystem,
                            onUnitChanged: _onUnitChanged,
                          ),
                        _OnboardingStepKind.goals => _GoalsStep(
                            l10n: l10n,
                            accent: accent,
                            fitnessGoal: _fitnessGoal,
                            experienceLevel: _experienceLevel,
                            activityLevel: _activityLevel,
                            onGoalChanged: (g) => setState(() => _fitnessGoal = l10n.canonicalGoal(g)),
                            onExperienceChanged: (e) =>
                                setState(() => _experienceLevel = l10n.canonicalExperience(e)),
                            onActivityChanged: (a) => setState(() => _activityLevel = a),
                          ),
                        _OnboardingStepKind.modes => _ModesStep(
                            l10n: l10n,
                            accent: accent,
                            hyroxMode: _hyroxMode,
                            runnerMode: _runnerMode,
                            onHyroxChanged: (v) => setState(() => _hyroxMode = v),
                            onRunnerChanged: (v) => setState(() => _runnerMode = v),
                          ),
                        _OnboardingStepKind.offlineCatalog => _OfflineCatalogStep(
                            l10n: l10n,
                            accent: accent,
                            download: download,
                            busy: _busy,
                            decisionMade: _offlineDecisionMade,
                            onDownload: _startOfflineDownload,
                            onSkip: () async {
                              setState(() => _offlineDecisionMade = true);
                              await _goNextPage();
                            },
                          ),
                        _OnboardingStepKind.plan => OnboardingPlanStep(
                            l10n: l10n,
                            accent: accent,
                            selected: _selectedPlan,
                            onSelected: (tier) => setState(() => _selectedPlan = tier),
                          ),
                      };
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_currentStep == _OnboardingStepKind.modes)
                        TextButton(
                          onPressed: _busy ? null : _next,
                          child: Text(l10n.onboardingSkipModes, textAlign: TextAlign.center),
                        ),
                      if (!isOffline)
                        Row(
                          children: [
                            if (showBack)
                              TextButton(
                                onPressed: _busy ? null : _back,
                                child: Text(l10n.onboardingBack),
                              )
                            else
                              const SizedBox(width: 8),
                            const Spacer(),
                            FilledButton(
                              onPressed: _busy ? null : _next,
                              style: FilledButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(148, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _busy && isPlan
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      isPlan ? _planCtaLabel(l10n) : l10n.onboardingNext,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ],
                        ),
                      if (isOffline)
                        Row(
                          children: [
                            if (showBack)
                              TextButton(
                                onPressed: _busy ? null : _back,
                                child: Text(l10n.onboardingBack),
                              ),
                            const Spacer(),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () async {
                                      setState(() => _offlineDecisionMade = true);
                                      await _goNextPage();
                                    },
                              child: Text(l10n.onboardingOfflineSkip),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: AppColors.textMuted, height: 1.45)),
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}

class _LanguageStep extends StatelessWidget {
  final AppLocalizations l10n;
  final Color accent;
  final String preferredLanguage;
  final ValueChanged<String> onLanguageChanged;

  const _LanguageStep({
    required this.l10n,
    required this.accent,
    required this.preferredLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: l10n.onboardingLanguageTitle,
      subtitle: l10n.onboardingLanguageSubtitle,
      child: Column(
        children: AppLocale.supportedCodes.map((code) {
          return _SelectableTile(
            title: l10n.languageLabel(code),
            subtitle: code == 'es' ? 'Español · Spanish' : 'English · Inglés',
            selected: preferredLanguage == code,
            accent: accent,
            onTap: () => onLanguageChanged(code),
          );
        }).toList(),
      ),
    );
  }
}

class _AboutYouStep extends StatelessWidget {
  final AppLocalizations l10n;
  final Color accent;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final String selectedAvatarId;
  final ValueChanged<Gender> onGenderChanged;
  final ValueChanged<DateTime> onDateOfBirthChanged;
  final VoidCallback onPickAvatar;

  const _AboutYouStep({
    required this.l10n,
    required this.accent,
    required this.formKey,
    required this.nameController,
    required this.dateOfBirth,
    required this.gender,
    required this.selectedAvatarId,
    required this.onGenderChanged,
    required this.onDateOfBirthChanged,
    required this.onPickAvatar,
  });

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = dateOfBirth ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 119, 1, 1),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      helpText: l10n.dateOfBirthTitle,
    );
    if (picked != null) onDateOfBirthChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final age = dateOfBirth != null ? AgeCalculator.yearsFromDateOfBirth(dateOfBirth!) : null;
    final dateLabel = dateOfBirth != null
        ? DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(dateOfBirth!)
        : l10n.dateOfBirthHint;

    return _StepScaffold(
      title: l10n.onboardingAboutYouTitle,
      subtitle: l10n.onboardingAboutYouSubtitle,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: onPickAvatar,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [accent, accent.withValues(alpha: 0.35)],
                            ),
                          ),
                          child: ProfileAvatar(
                            avatarUrl: selectedAvatarId,
                            radius: 46,
                            fallbackLetter: nameController.text,
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.surface, width: 2),
                            ),
                            child: const Icon(Icons.edit, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(onPressed: onPickAvatar, child: Text(l10n.chooseAvatar)),
                  Text(
                    l10n.chooseAvatarHint,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.profileOnboardingNickname),
              validator: (v) => v == null || v.trim().isEmpty ? l10n.displayNameRequired : null,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickDate(context),
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.dateOfBirthTitle,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  dateLabel,
                  style: TextStyle(color: dateOfBirth != null ? null : AppColors.textMuted),
                ),
              ),
            ),
            if (age != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.dateOfBirthAgePreview(age),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            Text(l10n.genderTitle, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Gender.values.map((g) {
                return ChoiceChip(
                  label: Text(l10n.genderLabel(g)),
                  selected: gender == g,
                  onSelected: (_) => onGenderChanged(g),
                  selectedColor: context.accentColor.withValues(alpha: 0.25),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyStep extends StatelessWidget {
  final AppLocalizations l10n;
  final GlobalKey<FormState> formKey;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final String unitSystem;
  final ValueChanged<String> onUnitChanged;

  const _BodyStep({
    required this.l10n,
    required this.formKey,
    required this.heightController,
    required this.weightController,
    required this.unitSystem,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: l10n.onboardingBodyTitle,
      subtitle: l10n.onboardingBodySubtitle,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.heightTitle, suffixText: 'cm'),
              validator: (v) {
                final h = double.tryParse(v?.replaceAll(',', '.') ?? '');
                if (h == null || h < 50 || h > 280) return l10n.heightInvalid;
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(l10n.unitSystem, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            _UnitToggle(unitSystem: unitSystem, onChanged: onUnitChanged),
            const SizedBox(height: 12),
            TextFormField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.metricWeight,
                suffixText: UnitConverter.massLabel(unitSystem),
              ),
              validator: (v) {
                final display = double.tryParse(v?.replaceAll(',', '.') ?? '');
                if (display == null) return l10n.weightInvalid;
                final kg = UnitConverter.displayToKg(display, unitSystem);
                if (kg < 20 || kg > 500) return l10n.weightInvalid;
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalsStep extends StatelessWidget {
  final AppLocalizations l10n;
  final Color accent;
  final String? fitnessGoal;
  final String? experienceLevel;
  final DailyActivityLevel activityLevel;
  final ValueChanged<String> onGoalChanged;
  final ValueChanged<String> onExperienceChanged;
  final ValueChanged<DailyActivityLevel> onActivityChanged;

  const _GoalsStep({
    required this.l10n,
    required this.accent,
    required this.fitnessGoal,
    required this.experienceLevel,
    required this.activityLevel,
    required this.onGoalChanged,
    required this.onExperienceChanged,
    required this.onActivityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: l10n.onboardingGoalsTitle,
      subtitle: l10n.onboardingGoalsSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.fitnessGoalTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...l10n.fitnessGoals.map((goal) {
            final canonical = l10n.canonicalGoal(goal);
            return _SelectableTile(
              title: goal,
              badge: l10n.fitnessGoalCalorieModeLabel(goal),
              subtitle:
                  '${l10n.fitnessGoalTrainingDescription(goal)}\n${l10n.fitnessGoalDietLabel}: ${l10n.fitnessGoalDietDescription(goal)}',
              selected: fitnessGoal == canonical,
              accent: accent,
              onTap: () => onGoalChanged(goal),
            );
          }),
          const SizedBox(height: 16),
          Text(l10n.experienceLevel, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: l10n.experienceLevels.map((level) {
              final canonical = l10n.canonicalExperience(level);
              return ChoiceChip(
                label: Text(level),
                selected: experienceLevel == canonical,
                onSelected: (_) => onExperienceChanged(level),
                selectedColor: accent.withValues(alpha: 0.25),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(l10n.activityLevel, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...l10n.activityLevels.map((level) {
            return _SelectableTile(
              title: l10n.activityLevelLabel(level),
              subtitle: l10n.activityLevelDescription(level),
              selected: activityLevel == level,
              accent: accent,
              onTap: () => onActivityChanged(level),
            );
          }),
        ],
      ),
    );
  }
}

class _ModesStep extends StatelessWidget {
  final AppLocalizations l10n;
  final Color accent;
  final bool hyroxMode;
  final bool runnerMode;
  final ValueChanged<bool> onHyroxChanged;
  final ValueChanged<bool> onRunnerChanged;

  const _ModesStep({
    required this.l10n,
    required this.accent,
    required this.hyroxMode,
    required this.runnerMode,
    required this.onHyroxChanged,
    required this.onRunnerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: l10n.onboardingModesTitle,
      subtitle: l10n.onboardingModesSubtitle,
      child: Column(
        children: [
          _ModeCard(
            icon: Icons.fitness_center,
            title: 'Gym',
            subtitle: l10n.navTrain,
            enabled: true,
            accent: accent,
            onChanged: null,
          ),
          const SizedBox(height: 12),
          _ModeCard(
            icon: Icons.timer_outlined,
            title: l10n.hyroxMode,
            subtitle: l10n.hyroxModeSubtitle,
            enabled: hyroxMode,
            accent: const Color(0xFFFF6B00),
            onChanged: onHyroxChanged,
          ),
          const SizedBox(height: 12),
          _ModeCard(
            icon: Icons.directions_run,
            title: l10n.runnerMode,
            subtitle: l10n.runnerModeSubtitle,
            enabled: runnerMode,
            accent: const Color(0xFF00A884),
            onChanged: onRunnerChanged,
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final Color accent;
  final ValueChanged<bool>? onChanged;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: enabled ? accent.withValues(alpha: 0.08) : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: enabled ? accent.withValues(alpha: 0.4) : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          if (onChanged != null)
            Switch(value: enabled, onChanged: onChanged, activeThumbColor: accent)
          else
            Icon(Icons.check_circle, color: accent, size: 22),
        ],
      ),
    );
  }
}

class _OfflineCatalogStep extends StatelessWidget {
  final AppLocalizations l10n;
  final Color accent;
  final CloudExerciseDownloadState download;
  final bool busy;
  final bool decisionMade;
  final VoidCallback onDownload;
  final VoidCallback onSkip;

  const _OfflineCatalogStep({
    required this.l10n,
    required this.accent,
    required this.download,
    required this.busy,
    required this.decisionMade,
    required this.onDownload,
    required this.onSkip,
  });

  String _progressLabel() {
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

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: l10n.onboardingOfflineTitle,
      subtitle: l10n.onboardingOfflineSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.16),
                  AppColors.cardElevated,
                ],
              ),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud_download_outlined, color: accent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.onboardingOfflineSize,
                        style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _OfflineBullet(text: l10n.onboardingOfflineBenefit1, accent: accent),
                _OfflineBullet(text: l10n.onboardingOfflineBenefit2, accent: accent),
                _OfflineBullet(text: l10n.onboardingOfflineBenefit3, accent: accent),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (download.isDownloading) ...[
            Text(
              l10n.onboardingOfflineDownloading,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: download.progress,
              minHeight: 7,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: AppColors.border,
              color: accent,
            ),
            const SizedBox(height: 8),
            Text(_progressLabel(), style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy ? null : onSkip,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(l10n.onboardingOfflineContinue),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: busy ? null : onDownload,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(l10n.onboardingOfflineDownload),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: busy ? null : onSkip,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(l10n.onboardingOfflineSkip),
            ),
            if (decisionMade && download.cachedCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                l10n.offlineDownloadExercisesSubtitleDone(download.cachedCount),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _OfflineBullet extends StatelessWidget {
  final String text;
  final Color accent;

  const _OfflineBullet({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_rounded, size: 18, color: accent),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35, fontSize: 13.5))),
        ],
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _SelectableTile({
    required this.title,
    required this.subtitle,
    this.badge,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? accent.withValues(alpha: 0.12) : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? accent : AppColors.border.withValues(alpha: 0.7),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (badge != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: accent.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.35),
                      ),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check_circle, color: accent, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final String unitSystem;
  final ValueChanged<String> onChanged;

  const _UnitToggle({required this.unitSystem, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _UnitChip(
            label: l10n.kilograms,
            selected: unitSystem == 'kg',
            onTap: () => onChanged('kg'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _UnitChip(
            label: l10n.pounds,
            selected: unitSystem == 'lb',
            onTap: () => onChanged('lb'),
          ),
        ),
      ],
    );
  }
}

class _UnitChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UnitChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? context.accentColor.withValues(alpha: 0.2) : AppColors.card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? context.accentColor : AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? context.accentColor : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
