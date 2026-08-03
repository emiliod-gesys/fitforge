import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/online_only_routes.dart';
import '../../l10n/l10n_extensions.dart';
import '../../providers/app_providers.dart';
import '../../widgets/ff/ff_nav_spinner.dart';

class HomeScreen extends ConsumerWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  int _currentIndex(
    BuildContext context, {
    required bool isOnline,
    required bool isTrainer,
  }) {
    final location = GoRouterState.of(context).matchedLocation;

    if (!isOnline) {
      if (location.startsWith('/profile')) return 1;
      return 0;
    }

    if (location.startsWith('/ai-coach')) return 1;
    if (location.startsWith('/food')) return 2;
    if (location.startsWith('/progress')) return 3;
    if (location.startsWith('/social')) return 4;
    if (location.startsWith('/students')) return 5;
    if (location.startsWith('/profile')) return isTrainer ? 6 : 5;
    return 0;
  }

  void _onDestinationSelected(
    BuildContext context,
    int index, {
    required bool isOnline,
    required bool isTrainer,
  }) {
    if (!isOnline) {
      switch (index) {
        case 0:
          context.go('/');
        case 1:
          context.go('/profile');
      }
      return;
    }

    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/ai-coach');
      case 2:
        context.go('/food');
      case 3:
        context.go('/progress');
      case 4:
        context.go('/social');
      case 5:
        context.go(isTrainer ? '/students' : '/profile');
      case 6:
        if (isTrainer) context.go('/profile');
    }
  }

  List<FfNavSpinnerItem> _items({
    required dynamic l10n,
    required bool isOnline,
    required bool isTrainer,
    required int unread,
  }) {
    final train = FfNavSpinnerItem(
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center,
      label: l10n.navTrain,
    );
    final profile = FfNavSpinnerItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: l10n.navProfile,
    );

    if (!isOnline) {
      return [train, profile];
    }

    return [
      train,
      FfNavSpinnerItem(
        icon: Icons.auto_awesome_outlined,
        selectedIcon: Icons.auto_awesome,
        label: l10n.navCoach,
      ),
      FfNavSpinnerItem(
        icon: Icons.restaurant_outlined,
        selectedIcon: Icons.restaurant,
        label: l10n.navFood,
      ),
      FfNavSpinnerItem(
        icon: Icons.show_chart_outlined,
        selectedIcon: Icons.show_chart,
        label: l10n.navProgress,
      ),
      FfNavSpinnerItem(
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        label: l10n.navSocial,
        badgeCount: unread,
      ),
      if (isTrainer)
        FfNavSpinnerItem(
          icon: Icons.school_outlined,
          selectedIcon: Icons.school,
          label: l10n.navStudents,
        ),
      profile,
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final unread = ref.watch(socialUnreadCountProvider).valueOrNull ?? 0;
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final isTrainer = ref.watch(isTrainerProvider);
    final location = GoRouterState.of(context).matchedLocation;

    if (!isOnline && isOnlineOnlyShellRoute(location)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/');
      });
    }

    final items = _items(
      l10n: l10n,
      isOnline: isOnline,
      isTrainer: isTrainer,
      unread: unread,
    );
    final selected = _currentIndex(
      context,
      isOnline: isOnline,
      isTrainer: isTrainer,
    ).clamp(0, items.length - 1);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: child,
      bottomNavigationBar: FfNavSpinner(
        items: items,
        selectedIndex: selected,
        onSelected: (index) => _onDestinationSelected(
          context,
          index,
          isOnline: isOnline,
          isTrainer: isTrainer,
        ),
      ),
    );
  }
}
