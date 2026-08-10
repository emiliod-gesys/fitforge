import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/subscription/routine_limit_gate.dart';
import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/l10n_extensions.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../routines/routine_list_screen.dart';
import '../workouts/workout_list_screen.dart';

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
        showBrandMark: true,
        automaticallyImplyLeading: false,
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.history_rounded),
              tooltip: l10n.history,
              onPressed: () => context.push('/workouts/history'),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: l10n.newRoutine,
              onPressed: () async {
                if (await ensureCanCreateRoutine(context, ref)) {
                  if (context.mounted) context.push('/routines/new');
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.auto_awesome_rounded),
              tooltip: l10n.generateWithAi,
              onPressed: () => RoutineListActions.showAiGenerator(context, ref),
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space16,
              AppTokens.space8,
              AppTokens.space16,
              AppTokens.space8,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.cardElevated,
                borderRadius: AppTokens.borderRadiusMd,
                border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: context.accentColor.withValues(alpha: 0.18),
                  borderRadius: AppTokens.borderRadiusSm,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: context.accentColor,
                unselectedLabelColor: AppColors.textMuted,
                tabs: [
                  Tab(text: l10n.trainTabToday),
                  Tab(text: l10n.trainTabRoutines),
                ],
              ),
            ),
          ),
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
