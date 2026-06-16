import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/routines')) return 1;
    if (location.startsWith('/exercises')) return 2;
    if (location.startsWith('/progress')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ai-coach'),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Coach IA'),
      ),
      bottomNavigationBar: NavigationBar(
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
              context.go('/profile');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Entreno'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Rutinas'),
          NavigationDestination(icon: Icon(Icons.sports_gymnastics), label: 'Ejercicios'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Progreso'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
