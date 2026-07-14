import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_locale.dart';
import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/unit_converter.dart';
import '../../data/avatar_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/food_entry.dart';
import '../../models/profile.dart';
import '../../providers/app_providers.dart';
import '../../providers/onboarding_progress_provider.dart';
import '../../screens/food/food_add_screen.dart';
import '../../services/supabase_service.dart';
import '../../widgets/avatar_picker_sheet.dart';
import '../../widgets/fitforge_logo.dart';
import '../../widgets/profile_avatar.dart';

enum _OnboardingStepKind {
  welcome,
  language,
  aboutYou,
  body,
  goals,
  modes,
  routine,
  food,
  done,
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  late int _pageIndex;
  late final PageController _pageController;
  Gender? _gender;
  String _unitSystem = 'kg';
  String? _fitnessGoal;
  String? _experienceLevel;
  DailyActivityLevel _activityLevel = DailyActivityLevel.moderate;
  bool _hyroxMode = false;
  bool _runnerMode = false;
  bool _busy = false;
  String _preferredLanguage = AppLocale.defaultCode;
  late String _selectedAvatarId;

  final _formKeyBasics = GlobalKey<FormState>();
  final _formKeyBody = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;

  List<_OnboardingStepKind> get _steps {
    final profile = ref.read(profileProvider).valueOrNull;
    final isTrainer = profile?.isTrainer ?? false;
    return [
      _OnboardingStepKind.welcome,
      _OnboardingStepKind.language,
      _OnboardingStepKind.aboutYou,
      _OnboardingStepKind.body,
      _OnboardingStepKind.goals,
      if (!isTrainer) _OnboardingStepKind.modes,
      _OnboardingStepKind.routine,
      _OnboardingStepKind.food,
      _OnboardingStepKind.done,
    ];
  }

  _OnboardingStepKind get _currentStep => _steps[_pageIndex];

  @override
  void initState() {
    super.initState();
    _pageIndex = ref.read(onboardingProgressProvider).stepIndex;
    _pageController = PageController(initialPage: _pageIndex);
    _selectedAvatarId = AvatarCatalog.toStorageId(AvatarCatalog.defaultOption().id);
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
  }

  bool _seededFromProfile = false;

  void _seedFromProfile(UserProfile? profile) {
    if (_seededFromProfile || profile == null) return;
    _seededFromProfile = true;
    _nameController.text = profile.displayName ?? '';
    _ageController.text = profile.age?.toString() ?? '';
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
    _ageController.dispose();
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

  Future<void> _next() async {
    final l10n = context.l10n;
    final step = _currentStep;

    if (step == _OnboardingStepKind.aboutYou) {
      if (_gender == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genderRequired)));
        return;
      }
      if (!_formKeyBasics.currentState!.validate()) return;
    }

    if (step == _OnboardingStepKind.body) {
      if (!_formKeyBody.currentState!.validate()) return;
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
    }

    if (step == _OnboardingStepKind.routine &&
        !ref.read(onboardingProgressProvider).routineCompleted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.onboardingRoutineExerciseRequired)));
      return;
    }

    if (step == _OnboardingStepKind.food &&
        !ref.read(onboardingProgressProvider).foodTutorialCompleted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.onboardingFoodDeleteHint)));
      return;
    }

    if (step == _OnboardingStepKind.done) {
      await _finishOnboarding();
      return;
    }

    if (_pageIndex >= _steps.length - 1) return;
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
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
      final age = int.parse(_ageController.text.trim());
      final heightCm = double.parse(_heightController.text.replaceAll(',', '.'));
      final weightKg = _parseWeightKg()!;

      final profileService = ref.read(profileServiceProvider);
      await profileService.updateProfile({
        'display_name': name,
        'search_name': name.toLowerCase(),
        'age': age,
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

  Future<void> _openRoutineEditor() async {
    if (_busy || ref.read(onboardingProgressProvider).routineCompleted) return;
    await context.push<bool>('/routines/new?onboarding=1');
    if (mounted) setState(() {});
  }

  Future<void> _openFoodQuickAdd() async {
    if (_busy) return;
    final progress = ref.read(onboardingProgressProvider);
    if (progress.foodTutorialCompleted) return;
    await context.push(
      '/food/add',
      extra: {
        'meal': MealType.breakfast,
        'day': DateTime.now(),
        'onboarding': true,
        'initialMode': FoodAddMode.quick,
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _openFoodDiary() async {
    if (_busy) return;
    final progress = ref.read(onboardingProgressProvider);
    if (!progress.foodLogged || progress.foodTutorialCompleted) return;
    ref.read(foodSelectedDayProvider.notifier).state = DateTime.now();
    await context.push('/food');
    if (mounted) setState(() {});
  }

  Future<void> _finishOnboarding() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(profileServiceProvider).updateProfile({
        'onboarding_completed_at': DateTime.now().toUtc().toIso8601String(),
      });

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
      ref.read(onboardingProgressProvider.notifier).reset();

      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.errorGeneric('$e'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = context.accentColor;
    final profile = ref.watch(profileProvider).valueOrNull;
    final onboardingProgress = ref.watch(onboardingProgressProvider);
    _seedFromProfile(profile);
    final steps = _steps;
    final isLast = _pageIndex >= steps.length - 1;
    final showBack = _pageIndex > 0 && _currentStep != _OnboardingStepKind.done;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    if (_currentStep != _OnboardingStepKind.welcome)
                      const FitForgeLogo(height: 28),
                    const Spacer(),
                    Text(
                      l10n.onboardingStepOf(_pageIndex + 1, steps.length),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_pageIndex + 1) / steps.length,
                backgroundColor: AppColors.border.withValues(alpha: 0.4),
                color: accent,
                minHeight: 4,
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
                      _OnboardingStepKind.welcome => _WelcomeStep(l10n: l10n, accent: accent),
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
                          ageController: _ageController,
                          gender: _gender,
                          selectedAvatarId: _selectedAvatarId,
                          onGenderChanged: (g) => setState(() => _gender = g),
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
                      _OnboardingStepKind.routine => _RoutineStep(
                          l10n: l10n,
                          accent: accent,
                          routineCompleted: onboardingProgress.routineCompleted,
                          onOpenEditor: _openRoutineEditor,
                        ),
                      _OnboardingStepKind.food => _FoodStep(
                          l10n: l10n,
                          accent: accent,
                          foodLogged: onboardingProgress.foodLogged,
                          foodTutorialCompleted: onboardingProgress.foodTutorialCompleted,
                          onOpenQuickAdd: _openFoodQuickAdd,
                          onOpenDiary: _openFoodDiary,
                        ),
                      _OnboardingStepKind.done => _DoneStep(l10n: l10n, accent: accent),
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
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: TextButton(
                          onPressed: _busy ? null : _next,
                          child: Text(
                            l10n.onboardingSkipModes,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        if (showBack)
                          TextButton(onPressed: _busy ? null : _back, child: Text(l10n.onboardingBack))
                        else
                          const SizedBox(width: 8),
                        const Spacer(),
                        FilledButton(
                          onPressed: _busy ? null : _next,
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 48),
                          ),
                          child: _busy && _currentStep == _OnboardingStepKind.done
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  isLast ? l10n.onboardingDoneAction : l10n.onboardingNext,
                                ),
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: AppColors.textMuted, height: 1.4)),
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final AppLocalizations l10n;
  final Color accent;

  const _WelcomeStep({required this.l10n, required this.accent});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Center(child: FitForgeLogo(height: 56)),
        const SizedBox(height: 32),
        Text(
          l10n.onboardingWelcomeTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.onboardingWelcomeSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: 32),
        _Bullet(icon: Icons.fitness_center, text: l10n.onboardingWelcomeBulletTrain, accent: accent),
        _Bullet(icon: Icons.restaurant, text: l10n.onboardingWelcomeBulletFood, accent: accent),
        _Bullet(icon: Icons.insights, text: l10n.onboardingWelcomeBulletProgress, accent: accent),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color accent;

  const _Bullet({required this.icon, required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
        ],
      ),
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
  final TextEditingController ageController;
  final Gender? gender;
  final String selectedAvatarId;
  final ValueChanged<Gender> onGenderChanged;
  final VoidCallback onPickAvatar;

  const _AboutYouStep({
    required this.l10n,
    required this.accent,
    required this.formKey,
    required this.nameController,
    required this.ageController,
    required this.gender,
    required this.selectedAvatarId,
    required this.onGenderChanged,
    required this.onPickAvatar,
  });

  @override
  Widget build(BuildContext context) {
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
                        ProfileAvatar(
                          avatarUrl: selectedAvatarId,
                          radius: 44,
                          fallbackLetter: nameController.text,
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(6),
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
                  TextButton(
                    onPressed: onPickAvatar,
                    child: Text(l10n.chooseAvatar),
                  ),
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
            TextFormField(
              controller: ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: InputDecoration(labelText: l10n.ageTitle, suffixText: l10n.years),
              validator: (v) {
                final age = int.tryParse(v?.trim() ?? '');
                if (age == null || age < 13 || age >= 120) return l10n.ageInvalid;
                return null;
              },
            ),
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
          Text(l10n.fitnessGoalTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
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
          Text(l10n.experienceLevel, style: const TextStyle(fontWeight: FontWeight.w600)),
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
          Text(l10n.activityLevel, style: const TextStyle(fontWeight: FontWeight.w600)),
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
        borderRadius: BorderRadius.circular(14),
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

class _RoutineStep extends StatelessWidget {
  final AppLocalizations l10n;
  final Color accent;
  final bool routineCompleted;
  final VoidCallback onOpenEditor;

  const _RoutineStep({
    required this.l10n,
    required this.accent,
    required this.routineCompleted,
    required this.onOpenEditor,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: l10n.onboardingRoutineTitle,
      subtitle: l10n.onboardingRoutineSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_note, color: accent, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.onboardingRoutineOpenHint,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!routineCompleted)
            FilledButton.icon(
              onPressed: onOpenEditor,
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.onboardingRoutineOpenAction),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: accent),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l10n.onboardingRoutineCreated)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FoodStep extends StatelessWidget {
  final AppLocalizations l10n;
  final Color accent;
  final bool foodLogged;
  final bool foodTutorialCompleted;
  final VoidCallback onOpenQuickAdd;
  final VoidCallback onOpenDiary;

  const _FoodStep({
    required this.l10n,
    required this.accent,
    required this.foodLogged,
    required this.foodTutorialCompleted,
    required this.onOpenQuickAdd,
    required this.onOpenDiary,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: l10n.onboardingFoodTitle,
      subtitle: l10n.onboardingFoodSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!foodLogged && !foodTutorialCompleted) ...[
            FilledButton.icon(
              onPressed: onOpenQuickAdd,
              icon: const Icon(Icons.bolt),
              label: Text(l10n.onboardingFoodOpenAction),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
          if (foodLogged && !foodTutorialCompleted) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: accent),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l10n.onboardingFoodRegistered)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.onboardingFoodDeleteHint,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onOpenDiary,
              icon: Icon(Icons.restaurant, color: accent),
              label: Text(l10n.onboardingFoodOpenDiary),
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.5)),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
          if (foodTutorialCompleted)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: accent),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l10n.onboardingFoodDeleted)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DoneStep extends StatelessWidget {
  final AppLocalizations l10n;
  final Color accent;

  const _DoneStep({required this.l10n, required this.accent});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        Icon(Icons.celebration_outlined, size: 72, color: accent),
        const SizedBox(height: 24),
        Text(
          l10n.onboardingDoneTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.onboardingDoneSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, height: 1.4),
        ),
      ],
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
        color: selected ? accent.withValues(alpha: 0.1) : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? accent : AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                      Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.35)),
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
  const _UnitToggle({required this.unitSystem, required this.onChanged});

  final String unitSystem;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(child: _UnitChip(label: l10n.kilograms, selected: unitSystem == 'kg', onTap: () => onChanged('kg'))),
        const SizedBox(width: 8),
        Expanded(child: _UnitChip(label: l10n.pounds, selected: unitSystem == 'lb', onTap: () => onChanged('lb'))),
      ],
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

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
