import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/exercise.dart';
import 'exercise_thumbnail.dart';

enum ExercisePickerFilter { all, inRoutine }

class ExercisePickerSheet extends StatefulWidget {
  final List<Exercise> exercises;
  final Set<String> selectedExerciseIds;

  const ExercisePickerSheet({
    super.key,
    required this.exercises,
    required this.selectedExerciseIds,
  });

  @override
  State<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<ExercisePickerSheet> {
  final _searchController = TextEditingController();
  String _search = '';
  String? _category;
  ExercisePickerFilter _filter = ExercisePickerFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    return widget.exercises.map((e) => e.category).toSet().toList()..sort();
  }

  List<Exercise> get _filtered {
    Iterable<Exercise> list = widget.exercises;

    if (_filter == ExercisePickerFilter.inRoutine) {
      list = list.where((e) => widget.selectedExerciseIds.contains(e.id));
    }

    if (_category != null) {
      list = list.where((e) => e.category == _category);
    }

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where(
        (e) =>
            e.name.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q) ||
            e.muscles.any((m) => m.toLowerCase().contains(q)),
      );
    }

    return list.toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final inRoutineCount = widget.selectedExerciseIds.length;

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Añadir ejercicio', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, músculo o categoría…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Todos'),
                      selected: _filter == ExercisePickerFilter.all,
                      onSelected: (_) => setState(() => _filter = ExercisePickerFilter.all),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text('En rutina ($inRoutineCount)'),
                      selected: _filter == ExercisePickerFilter.inRoutine,
                      onSelected: (_) => setState(() => _filter = ExercisePickerFilter.inRoutine),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Todos los grupos'),
                      selected: _category == null,
                      onSelected: (_) => setState(() => _category = null),
                    ),
                    ..._categories.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text(c),
                          selected: _category == c,
                          onSelected: (_) => setState(() => _category = _category == c ? null : c),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${filtered.length} ejercicios',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _filter == ExercisePickerFilter.inRoutine
                          ? 'Ningún ejercicio coincide con la búsqueda en tu rutina.'
                          : 'No se encontraron ejercicios.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final ex = filtered[i];
                    final inRoutine = widget.selectedExerciseIds.contains(ex.id);
                    return ListTile(
                      leading: ExerciseThumbnail(
                        imageUrl: ex.imageUrl,
                        exerciseId: ex.id,
                        exerciseName: ex.name,
                        category: ex.category,
                        muscles: ex.muscles,
                        width: 48,
                        height: 48,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      title: Text(ex.name),
                      subtitle: Text(
                        [
                          ex.category,
                          if (ex.muscles.isNotEmpty) ex.muscles.first,
                        ].join(' · '),
                      ),
                      trailing: inRoutine
                          ? const Icon(Icons.check_circle, color: AppColors.orange)
                          : const Icon(Icons.add_circle_outline),
                      onTap: () => Navigator.pop(context, ex),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
