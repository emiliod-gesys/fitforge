import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/subscription/routine_limit_gate.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../routines/routine_list_screen.dart';
import '../workouts/workout_list_screen.dart';
import '../../core/theme/app_accent.dart';

class TrainingHubScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const TrainingHubScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<TrainingHubScreen> createState() => _TrainingHubScreenState();
}

class _TrainingHubScreenState extends ConsumerState<TrainingHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
    _syncRouteWithTab();
  }

  @override
  void didUpdateWidget(TrainingHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = widget.initialTab.clamp(0, 1);
    if (_tabController.index != nextIndex) {
      _tabController.index = nextIndex;
    }
  }

  void _syncRouteWithTab() {
    if (!mounted) return;
    final target = _tabController.index == 1 ? '/?tab=routines' : '/';
    final current = GoRouterState.of(context).uri.toString();
    if (current != target) {
      context.go(target);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: FitForgeAppBar(
        title: l10n.navTrain,
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: l10n.history,
              onPressed: () => context.push('/workouts/history'),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: l10n.newRoutine,
              onPressed: () async {
                if (await ensureCanCreateRoutine(context, ref)) {
                  if (context.mounted) context.push('/routines/new');
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.auto_awesome_outlined),
              tooltip: l10n.generateWithAi,
              onPressed: () => RoutineListActions.showAiGenerator(context, ref),
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: context.accentColor,
          labelColor: context.accentColor,
          unselectedLabelColor: AppColors.textMuted,
          tabs: [
            Tab(text: l10n.trainTabToday),
            Tab(text: l10n.trainTabRoutines),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          WorkoutTodayTab(),
          RoutinesTab(),
        ],
      ),
    );
  }
}
