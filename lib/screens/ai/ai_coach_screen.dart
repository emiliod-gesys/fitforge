import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/coach_message.dart';
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
      final coach = ref.read(aiCoachServiceProvider);

      if (AiCoachService.isRoutineCreationRequest(text)) {
        final routine = await coach.generateRoutineFromMessage(
          userMessage: text,
          catalog: catalog,
          profile: profile,
          recentWorkouts: workouts,
        );

        setState(() {
          if (routine != null) {
            _messages.add(
              CoachMessage(
                text: l10n.coachRoutineReady,
                routinePreview: routine,
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
      } else {
        final response = await coach.getRecommendation(
          userMessage: text,
          recentWorkouts: workouts,
          routines: routines,
          profile: profile,
        );

        setState(() {
          _messages.add(CoachMessage(text: response, isUser: false));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(CoachMessage(text: l10n.errorGeneric('$e'), isError: true));
      });
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  Future<void> _saveRoutine(int messageIndex) async {
    final l10n = context.l10n;
    final message = _messages[messageIndex];
    final routine = message.routinePreview;
    if (routine == null || message.isRoutineSaved) return;

    try {
      await ref.read(routineServiceProvider).createRoutine(routine);
      ref.invalidate(routinesProvider);

      setState(() {
        _messages[messageIndex] = message.copyWith(isRoutineSaved: true);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.routineSavedNamed(routine.name))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saveFailed('$e'))),
        );
      }
    }
  }

  void _discardRoutine(int messageIndex) {
    setState(() {
      _messages[messageIndex] = _messages[messageIndex].copyWith(isRoutineDiscarded: true);
    });
  }

  Future<void> _editRoutine(int messageIndex) async {
    final message = _messages[messageIndex];
    final routine = message.routinePreview;
    if (routine == null) return;

    final updated = await EditRoutineDialog.show(context, routine);

    if (updated != null && mounted) {
      setState(() {
        _messages[messageIndex] = message.copyWith(routinePreview: updated);
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
  final void Function(int index) onSaveRoutine;
  final void Function(int index) onEditRoutine;
  final void Function(int index) onDiscardRoutine;

  const _MessageBubble({
    required this.message,
    required this.index,
    required this.onSaveRoutine,
    required this.onEditRoutine,
    required this.onDiscardRoutine,
  });

  @override
  Widget build(BuildContext context) {
    if (message.routinePreview != null) {
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
              AiRoutinePreviewCard(
                routine: message.routinePreview!,
                isSaved: message.isRoutineSaved,
                isDiscarded: message.isRoutineDiscarded,
                onSave: () => onSaveRoutine(index),
                onEdit: () => onEditRoutine(index),
                onDiscard: () => onDiscardRoutine(index),
              ),
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
