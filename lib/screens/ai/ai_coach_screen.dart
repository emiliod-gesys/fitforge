import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/workout_streak.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/body_metric.dart';
import '../../models/coach_message.dart';
import '../../models/coach_routine_slot.dart';
import '../../models/exercise.dart';
import '../../models/profile.dart';
import '../../models/routine.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
import '../../services/ai_coach_service.dart';
import '../../widgets/ai_routine_preview_card.dart';
import '../../widgets/edit_routine_dialog.dart';
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
    if (text.trim().isEmpty || _loading) return;

    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;

    setState(() {
      _messages.add(CoachMessage(text: text, isUser: true));
      _loading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final profile = await ref.read(profileProvider.future);
      final workouts = await ref.read(workoutsProvider.future);
      final routines = await ref.read(routinesProvider.future);
      final catalog = await ref.read(exercisesProvider.future);
      final bodyMetrics = await ref.read(bodyMetricSnapshotsProvider.future);
      final weeklyStats = await ref.read(workoutWeeklyStatsProvider.future);
      final personalRecords = await ref.read(personalRecordsProvider.future);
      final coach = ref.read(aiCoachServiceProvider);

      if (AiCoachService.isRoutineSaveIntent(text)) {
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
      } else if (AiCoachService.isRoutineCreationRequest(text)) {
        await _handleRoutineGeneration(
          text: text,
          profile: profile,
          workouts: workouts,
          routines: routines,
          catalog: catalog,
          bodyMetrics: bodyMetrics,
          weeklyStats: weeklyStats,
          personalRecords: personalRecords,
          coach: coach,
          languageCode: languageCode,
        );
      } else {
        final response = await coach.getRecommendation(
          userMessage: text,
          recentWorkouts: workouts,
          routines: routines,
          profile: profile,
          bodyMetrics: bodyMetrics,
          weeklyStats: weeklyStats,
          personalRecords: personalRecords,
          languageCode: languageCode,
        );

        final muscles = AiCoachService.parseTargetMuscles(text);
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
                text: l10n.coachRoutineReady,
                routineSlots: [CoachRoutineSlot(routine: parsedRoutine)],
              ),
            );
          } else {
            _messages.add(CoachMessage(text: response, isUser: false));
          }
        });
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
    required UserProfile? profile,
    required List<Workout> workouts,
    required List<Routine> routines,
    required List<Exercise> catalog,
    required Map<String, BodyMetricSnapshot> bodyMetrics,
    required WorkoutWeeklyStats weeklyStats,
    required List<PersonalRecord> personalRecords,
    required AiCoachService coach,
    required String languageCode,
  }) async {
    final l10n = context.l10n;
    final isProgram = AiCoachService.isMultiRoutineProgramRequest(text);

    if (isProgram) {
      final generated = await coach.generateRoutineProgramFromMessage(
        userMessage: text,
        catalog: catalog,
        profile: profile,
        recentWorkouts: workouts,
        bodyMetrics: bodyMetrics,
        weeklyStats: weeklyStats,
        personalRecords: personalRecords,
        routines: routines,
        languageCode: languageCode,
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
              text: l10n.coachRoutineReady,
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
      profile: profile,
      recentWorkouts: workouts,
      bodyMetrics: bodyMetrics,
      weeklyStats: weeklyStats,
      personalRecords: personalRecords,
      routines: routines,
      languageCode: languageCode,
    );

    if (!mounted) return;
    setState(() {
      if (routine != null && routine.exercises.length >= 2) {
        _messages.add(
          CoachMessage(
            text: l10n.coachRoutineReady,
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

    setState(() {
      _savingMessageIndex = messageIndex;
      _savingSlotIndex = slotIndex;
    });

    try {
      await ref.read(routineServiceProvider).createRoutine(slot.routine);
      ref.invalidate(routinesProvider);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saveFailed('$e'))),
        );
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

    return Scaffold(
      appBar: FitForgeAppBar(title: l10n.coachTitle),
      body: Column(
        children: [
          if (_messages.isEmpty)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Icon(Icons.auto_awesome_outlined, size: 64, color: AppColors.orange),
                  const SizedBox(height: 16),
                  Text(
                    l10n.coachWelcome,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.coachWelcomeHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  ...suggestions.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ActionChip(
                        label: Text(s),
                        onPressed: () => _send(s),
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
                      decoration: InputDecoration(
                        hintText: l10n.coachAskHint,
                      ),
                      onSubmitted: _send,
                      enabled: !_loading,
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : () => _send(_controller.text),
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
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: message.isError
              ? AppColors.error.withValues(alpha: 0.2)
              : message.isUser
                  ? AppColors.orange.withValues(alpha: 0.2)
                  : AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message.text ?? ''),
      ),
    );
  }
}
