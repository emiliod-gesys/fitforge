import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';

class HomeScreen extends ConsumerWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/routines')) return 1;
    if (location.startsWith('/exercises')) return 2;
    if (location.startsWith('/progress')) return 3;
    if (location.startsWith('/social')) return 4;
    if (location.startsWith('/profile')) return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(socialUnreadCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: child,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ai-coach'),
        icon: const Icon(Icons.auto_awesome_outlined),
        label: const Text('Coach IA'),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          backgroundColor: AppColors.card,
          selectedIndex: _currentIndex(context),
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.go('/');
              case 1:
                context.go('/routines');
              case 2:
                context.go('/exercises');
              case 3:
                context.go('/progress');
              case 4:
                context.go('/social');
              case 5:
                context.go('/profile');
            }
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center),
              label: 'Entreno',
            ),
            const NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'Rutinas',
            ),
            const NavigationDestination(
              icon: Icon(Icons.sports_gymnastics_outlined),
              selectedIcon: Icon(Icons.sports_gymnastics),
              label: 'Ejercicios',
            ),
            const NavigationDestination(
              icon: Icon(Icons.show_chart_outlined),
              selectedIcon: Icon(Icons.show_chart),
              label: 'Progreso',
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
              label: 'Social',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
