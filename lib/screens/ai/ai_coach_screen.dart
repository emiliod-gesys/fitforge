import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/workout_streak.dart';
import '../../core/subscription/routine_limit_gate.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/body_metric.dart';
import '../../models/coach_chat_turn.dart';
import '../../models/coach_message.dart';
import '../../models/coach_nutrition_snapshot.dart';
import '../../models/coach_routine_slot.dart';
import '../../models/exercise.dart';
import '../../models/profile.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
import '../../services/ai_coach_service.dart';
import '../../services/routine_limit_service.dart';
import '../../core/theme/app_accent.dart';
import '../../core/theme/app_tokens.dart';
import '../../widgets/ai_routine_preview_card.dart';
import '../../widgets/edit_routine_dialog.dart';
import '../../widgets/ff/ff_surface.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <CoachMessage>[];
  bool _loading = false;
  int? _savingMessageIndex;
  int? _savingSlotIndex;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  /// Chat turns before the just-added user message (for LLM context).
  List<CoachChatTurn> _conversationHistoryBeforeCurrent() {
    if (_messages.length <= 1) return const [];
    return AiCoachService.trimChatHistory(
      _messages
          .sublist(0, _messages.length - 1)
          .where((m) => !m.isError && (m.text?.trim().isNotEmpty ?? false))
          .map(
            (m) => CoachChatTurn(
              isUser: m.isUser,
              content: m.text!.trim(),
            ),
          )
          .toList(),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading) return;
    if (trimmed.length > AiCoachService.maxUserMessageLength) return;

    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isSaveOnly = AiCoachService.isRoutineSaveIntent(trimmed);

    if (!isSaveOnly) {
      final profile = await ref.read(profileProvider.future);
      final usageService = ref.read(coachUsageServiceProvider);
      final profileService = ref.read(profileServiceProvider);
      final canSend = await usageService.canSendMessage(profile, profileService);
      if (!canSend) {
        if (!mounted) return;
        final status = await usageService.getStatus(profile, profileService);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.coachDailyLimitReached(status.limit ?? 0)),
          ),
        );
        return;
      }
    }

    setState(() {
      _messages.add(CoachMessage(text: trimmed, isUser: true));
      _loading = true;
    });
    _controller.clear();
    _scrollToBottom();

    var coachUsageRecorded = false;

    Future<void> recordCoachUsage() async {
      if (isSaveOnly || coachUsageRecorded) return;
      coachUsageRecorded = true;
      await ref.read(coachUsageServiceProvider).recordMessage();
      ref.invalidate(coachUsageStatusProvider);
    }

    try {
      final profile = await ref.read(profileProvider.future);
      final workouts = await ref.read(workoutsProvider.future);
      final routines = await ref.read(routinesProvider.future);
      final bodyMetrics = await ref.read(bodyMetricSnapshotsProvider.future);
      final weeklyStats = await ref.read(workoutWeeklyStatsProvider.future);
      final personalRecords = await ref.read(personalRecordsProvider.future);
      final nutrition = await ref.read(coachNutritionServiceProvider).load(
            profile: profile,
            bodyMetrics: bodyMetrics,
          );
      final routineLimit = await ref.read(routineLimitStatusProvider.future);
      final coach = ref.read(aiCoachServiceProvider);

      if (AiCoachService.isRoutineSaveIntent(trimmed)) {
        final pendingIndex = _messages.lastIndexWhere((m) => m.hasActiveRoutinePreview);
        if (pendingIndex >= 0) {
          final slots = _messages[pendingIndex].allRoutineSlots;
          final activeSlot = slots.indexWhere((slot) => slot.isActive);
          if (activeSlot >= 0) {
            await _saveRoutine(pendingIndex, activeSlot);
          } else {
            setState(() {
              _messages.add(
                CoachMessage(
                  text: l10n.coachNoRoutineToSave,
                  isError: true,
                ),
              );
            });
          }
        } else {
          setState(() {
            _messages.add(
              CoachMessage(
                text: l10n.coachNoRoutineToSave,
                isError: true,
              ),
            );
          });
        }
        return;
      }

      final history = _conversationHistoryBeforeCurrent();
      final muscles = AiCoachService.resolveTargetMuscles(
        currentMessage: trimmed,
        history: history,
      );
      final lang = ref.read(preferredLanguageProvider);
      final exerciseService = ref.read(exerciseServiceProvider);
      exerciseService.configure(language: lang);
      final catalog = await exerciseService.fetchAiCoachCatalog(targetMuscles: muscles);

      if (AiCoachService.shouldGenerateStructuredRoutine(trimmed)) {
        await _handleRoutineGeneration(
          text: trimmed,
          history: history,
          profile: profile,
          workouts: workouts,
          routines: routines,
          catalog: catalog,
          bodyMetrics: bodyMetrics,
          weeklyStats: weeklyStats,
          personalRecords: personalRecords,
          coach: coach,
          languageCode: languageCode,
          nutrition: nutrition,
          routineLimit: routineLimit,
        );
        await recordCoachUsage();
      } else {
        final response = await coach.getRecommendation(
          userMessage: trimmed,
          conversationHistory: history,
          recentWorkouts: workouts,
          routines: routines,
          profile: profile,
          bodyMetrics: bodyMetrics,
          weeklyStats: weeklyStats,
          personalRecords: personalRecords,
          languageCode: languageCode,
          nutrition: nutrition,
          routineLimit: routineLimit,
        );

        final parsedRoutine = coach.tryParseRoutineFromResponse(
          response,
          targetMuscles: muscles,
          profile: profile,
          catalog: catalog,
        );

        setState(() {
          if (parsedRoutine != null && parsedRoutine.exercises.isNotEmpty) {
            _messages.add(
              CoachMessage(
                text: _routineReadyMessage(routineLimit),
                routineSlots: [CoachRoutineSlot(routine: parsedRoutine)],
              ),
            );
          } else {
            _messages.add(CoachMessage(text: response, isUser: false));
          }
        });
        await recordCoachUsage();
      }
    } catch (e) {
      setState(() {
        _messages.add(CoachMessage(text: l10n.friendlyAiError(e), isError: true));
      });
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  Future<void> _handleRoutineGeneration({
    required String text,
    required List<CoachChatTurn> history,
    required UserProfile? profile,
    required List<Workout> workouts,
    required List<Routine> routines,
    required List<Exercise> catalog,
    required Map<String, BodyMetricSnapshot> bodyMetrics,
    required WorkoutWeeklyStats weeklyStats,
    required List<PersonalRecord> personalRecords,
    required AiCoachService coach,
    required String languageCode,
    CoachNutritionSnapshot? nutrition,
    required RoutineLimitStatus routineLimit,
  }) async {
    final l10n = context.l10n;
    final readyMessage = _routineReadyMessage(routineLimit);
    final isProgram = AiCoachService.isMultiRoutineProgramRequest(text);

    if (isProgram) {
      final generated = await coach.generateRoutineProgramFromMessage(
        userMessage: text,
        catalog: catalog,
        conversationHistory: history,
        profile: profile,
        recentWorkouts: workouts,
        bodyMetrics: bodyMetrics,
        weeklyStats: weeklyStats,
        personalRecords: personalRecords,
        routines: routines,
        languageCode: languageCode,
        nutrition: nutrition,
        routineLimit: routineLimit,
      );

      if (!mounted) return;
      setState(() {
        if (generated.length >= 2) {
          _messages.add(
            CoachMessage(
              text: l10n.coachRoutinesReady(generated.length),
              routineSlots: generated
                  .map((routine) => CoachRoutineSlot(routine: routine))
                  .toList(),
            ),
          );
        } else if (generated.length == 1) {
          _messages.add(
            CoachMessage(
              text: readyMessage,
              routineSlots: [CoachRoutineSlot(routine: generated.first)],
            ),
          );
        } else {
          _messages.add(
            CoachMessage(
              text: l10n.coachRoutineFailed,
              isError: true,
            ),
          );
        }
      });
      return;
    }

    final routine = await coach.generateRoutineFromMessage(
      userMessage: text,
      catalog: catalog,
      conversationHistory: history,
      profile: profile,
      recentWorkouts: workouts,
      bodyMetrics: bodyMetrics,
      weeklyStats: weeklyStats,
      personalRecords: personalRecords,
      routines: routines,
      languageCode: languageCode,
      nutrition: nutrition,
    );

    if (!mounted) return;
    setState(() {
      if (routine != null && routine.exercises.length >= 2) {
        _messages.add(
          CoachMessage(
            text: readyMessage,
            routineSlots: [CoachRoutineSlot(routine: routine)],
          ),
        );
      } else if (routine != null) {
        _messages.add(
          CoachMessage(
            text: l10n.coachRoutineTooFewExercises,
            isError: true,
          ),
        );
      } else {
        _messages.add(
          CoachMessage(
            text: l10n.coachRoutineFailed,
            isError: true,
          ),
        );
      }
    });
  }

  String _routineReadyMessage(RoutineLimitStatus status) {
    final l10n = context.l10n;
    final base = l10n.coachRoutineReady;
    if (!status.canCreate) {
      return '$base\n\n${l10n.routineLimitReached(status.limit)}';
    }
    if (status.remaining <= 2) {
      return '$base\n\n${l10n.routineLimitUsage(status.used, status.limit)}';
    }
    return base;
  }

  Future<void> _saveRoutine(int messageIndex, int slotIndex) async {
    final l10n = context.l10n;
    final message = _messages[messageIndex];
    final slots = message.allRoutineSlots;
    if (slotIndex < 0 || slotIndex >= slots.length) return;

    final slot = slots[slotIndex];
    if (!slot.isActive ||
        (_savingMessageIndex == messageIndex && _savingSlotIndex == slotIndex)) {
      return;
    }

    if (!await ensureCanCreateRoutine(context, ref)) return;

    setState(() {
      _savingMessageIndex = messageIndex;
      _savingSlotIndex = slotIndex;
    });

    try {
      await ref.read(routineServiceProvider).createRoutine(slot.routine);
      ref.invalidate(routinesProvider);
      ref.invalidate(routineLimitStatusProvider);

      if (!mounted) return;
      setState(() {
        _messages[messageIndex] = message.withSlotAt(
          slotIndex,
          slot.copyWith(isSaved: true),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.routineSavedNamed(slot.routine.name))),
      );
    } catch (e) {
      if (mounted) {
        showRoutineSaveErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          if (_savingMessageIndex == messageIndex && _savingSlotIndex == slotIndex) {
            _savingMessageIndex = null;
            _savingSlotIndex = null;
          }
        });
      }
    }
  }

  void _discardRoutine(int messageIndex, int slotIndex) {
    final message = _messages[messageIndex];
    final slots = message.allRoutineSlots;
    if (slotIndex < 0 || slotIndex >= slots.length) return;

    setState(() {
      _messages[messageIndex] = message.withSlotAt(
        slotIndex,
        slots[slotIndex].copyWith(isDiscarded: true),
      );
    });
  }

  Future<void> _editRoutine(int messageIndex, int slotIndex) async {
    final message = _messages[messageIndex];
    final slots = message.allRoutineSlots;
    if (slotIndex < 0 || slotIndex >= slots.length) return;

    final slot = slots[slotIndex];
    final updated = await EditRoutineDialog.show(context, slot.routine);

    if (updated != null && mounted) {
      setState(() {
        _messages[messageIndex] = message.withSlotAt(
          slotIndex,
          slot.copyWith(routine: updated),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final suggestions = l10n.coachSuggestions;
    final usageAsync = ref.watch(coachUsageStatusProvider);
    final usage = usageAsync.value;
    final inputBlocked = usage != null && !usage.canSend;

    return Scaffold(
      appBar: FitForgeAppBar(title: l10n.coachTitle),
      body: Column(
        children: [
          usageAsync.when(
            data: (status) {
              if (status.isUnlimited) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: status.canSend
                    ? context.accentColor.withValues(alpha: 0.12)
                    : AppColors.error.withValues(alpha: 0.12),
                child: Text(
                  status.canSend
                      ? l10n.coachDailyLimitRemaining(status.remaining, status.limit!)
                      : l10n.coachDailyLimitReached(status.limit!),
                  style: TextStyle(
                    fontSize: 13,
                    color: status.canSend ? context.accentColor : AppColors.error,
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (_messages.isEmpty)
            Expanded(
              child: ListView(
                padding: AppTokens.pagePadding,
                children: [
                  FfSurface(
                    elevated: true,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.accentColor.withValues(alpha: 0.22),
                        AppColors.cardElevated,
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.accentColor.withValues(alpha: 0.18),
                            border: Border.all(
                              color: context.accentColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 34,
                            color: context.accentColor,
                          ),
                        ),
                        const SizedBox(height: AppTokens.space16),
                        Text(
                          l10n.coachWelcomeTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                        ),
                        const SizedBox(height: AppTokens.space8),
                        Text(
                          l10n.coachWelcomeSubtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.space24),
                  ...suggestions.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: AppTokens.space8),
                      child: FfSurface(
                        onTap: inputBlocked ? null : () => _send(s),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.space16,
                          vertical: AppTokens.space14,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bolt_rounded, color: context.accentColor, size: 20),
                            const SizedBox(width: AppTokens.space12),
                            Expanded(
                              child: Text(
                                s,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (_, i) {
                  if (_loading && i == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: FitForgeLoadingIndicator(size: 48)),
                    );
                  }
                  return _MessageBubble(
                    message: _messages[i],
                    index: i,
                    savingMessageIndex: _savingMessageIndex,
                    savingSlotIndex: _savingSlotIndex,
                    onSaveRoutine: _saveRoutine,
                    onEditRoutine: _editRoutine,
                    onDiscardRoutine: _discardRoutine,
                  );
                },
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLength: AiCoachService.maxUserMessageLength,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: l10n.coachAskHint,
                        counterText: '',
                      ),
                      buildCounter: (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) {
                        if (maxLength == null) return null;
                        final nearLimit = currentLength >= maxLength - 100;
                        if (!nearLimit && !isFocused) return null;
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              l10n.coachMessageCharCounter(currentLength, maxLength),
                              style: TextStyle(
                                fontSize: 11,
                                color: currentLength >= maxLength
                                    ? Theme.of(context).colorScheme.error
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        );
                      },
                      enabled: !_loading && !inputBlocked,
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ||
                            inputBlocked ||
                            _controller.text.trim().isEmpty
                        ? null
                        : () => _send(_controller.text),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _MessageBubble extends StatelessWidget {
  final CoachMessage message;
  final int index;
  final int? savingMessageIndex;
  final int? savingSlotIndex;
  final void Function(int messageIndex, int slotIndex) onSaveRoutine;
  final void Function(int messageIndex, int slotIndex) onEditRoutine;
  final void Function(int messageIndex, int slotIndex) onDiscardRoutine;

  const _MessageBubble({
    required this.message,
    required this.index,
    required this.savingMessageIndex,
    required this.savingSlotIndex,
    required this.onSaveRoutine,
    required this.onEditRoutine,
    required this.onDiscardRoutine,
  });

  @override
  Widget build(BuildContext context) {
    if (message.hasRoutinePreviews) {
      final slots = message.allRoutineSlots;
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.92),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.text != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    message.text!,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              for (var slotIndex = 0; slotIndex < slots.length; slotIndex++) ...[
                if (slotIndex > 0) const SizedBox(height: 10),
                AiRoutinePreviewCard(
                  routine: slots[slotIndex].routine,
                  isSaved: slots[slotIndex].isSaved,
                  isDiscarded: slots[slotIndex].isDiscarded,
                  isSaving: savingMessageIndex == index && savingSlotIndex == slotIndex,
                  onSave: () => onSaveRoutine(index, slotIndex),
                  onEdit: () => onEditRoutine(index, slotIndex),
                  onDiscard: () => onDiscardRoutine(index, slotIndex),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: message.isError
              ? AppColors.error.withValues(alpha: 0.2)
              : message.isUser
                  ? context.accentColor.withValues(alpha: 0.2)
                  : AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message.text ?? ''),
      ),
    );
  }
}
