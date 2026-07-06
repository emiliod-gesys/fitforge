import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../providers/app_providers.dart';

class HomeScreen extends ConsumerWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  int _currentIndex(BuildContext context, {required bool isTrainer}) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/ai-coach')) return 1;
    if (location.startsWith('/food')) return 2;
    if (location.startsWith('/progress')) return 3;
    if (location.startsWith('/social')) return 4;
    if (isTrainer && location.startsWith('/students')) return 5;
    if (location.startsWith('/profile')) return isTrainer ? 6 : 5;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index, {required bool isTrainer}) {
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
        if (isTrainer) {
          context.go('/students');
        } else {
          context.go('/profile');
        }
      case 6:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final unread = ref.watch(socialUnreadCountProvider).valueOrNull ?? 0;
    final isTrainer = ref.watch(isTrainerProvider);

    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.fitness_center_outlined),
        selectedIcon: const Icon(Icons.fitness_center),
        label: l10n.navTrain,
      ),
      NavigationDestination(
        icon: _NavAiIcon(color: AppColors.textMuted.withValues(alpha: 0.85)),
        selectedIcon: const _NavAiIcon(color: AppColors.orange),
        label: l10n.navCoach,
      ),
      NavigationDestination(
        icon: const Icon(Icons.restaurant_outlined),
        selectedIcon: const Icon(Icons.restaurant),
        label: l10n.navFood,
      ),
      NavigationDestination(
        icon: const Icon(Icons.show_chart_outlined),
        selectedIcon: const Icon(Icons.show_chart),
        label: l10n.navProgress,
      ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: unread > 0,
          label: Text(unread > 9 ? '9+' : '$unread'),
          child: const Icon(Icons.people_outline),
        ),
        selectedIcon: Badge(
          isLabelVisible: unread > 0,
          label: Text(unread > 9 ? '9+' : '$unread'),
          child: const Icon(Icons.people),
        ),
        label: l10n.navSocial,
      ),
      if (isTrainer)
        NavigationDestination(
          icon: const Icon(Icons.school_outlined),
          selectedIcon: const Icon(Icons.school),
          label: l10n.navStudents,
        ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: l10n.navProfile,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.black,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          backgroundColor: AppColors.card,
          selectedIndex: _currentIndex(context, isTrainer: isTrainer),
          onDestinationSelected: (index) =>
              _onDestinationSelected(context, index, isTrainer: isTrainer),
          destinations: destinations,
        ),
      ),
    );
  }
}

class _NavAiIcon extends StatelessWidget {
  final Color color;

  const _NavAiIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      'AI',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1,
        color: color,
      ),
    );
  }
}
