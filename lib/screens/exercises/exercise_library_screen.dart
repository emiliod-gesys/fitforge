import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../widgets/exercise_card.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  String _search = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: const FitForgeAppBar(title: 'Ejercicios'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar ejercicio...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          exercisesAsync.when(
            data: (exercises) {
              final categories = ref.read(exerciseServiceProvider).getCategories(exercises);
              final filtered = exercises.where((e) {
                if (_search.isNotEmpty && !e.name.toLowerCase().contains(_search.toLowerCase())) {
                  return false;
                }
                if (_category != null && e.category != _category) return false;
                return true;
              }).toList();

              return Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${filtered.length} ejercicios',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          FilterChip(
                            label: const Text('Todos'),
                            selected: _category == null,
                            onSelected: (_) => setState(() => _category = null),
                          ),
                          ...categories.map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: FilterChip(
                                label: Text(c),
                                selected: _category == c,
                                onSelected: (_) => setState(() => _category = c),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => ExerciseCard(
                          exercise: filtered[i],
                          onTap: () => context.push('/exercises/${filtered[i].id}'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Expanded(child: FitForgeLoadingScreen()),
            error: (e, _) => Expanded(child: Center(child: Text('Error: $e'))),
          ),
        ],
      ),
    );
  }
}
