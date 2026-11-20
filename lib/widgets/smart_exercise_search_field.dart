import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Descripción libre que recomienda ejercicios del banco.
class SmartExerciseSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String activeQuery;
  final String label;
  final String hint;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;

  const SmartExerciseSearchField({
    super.key,
    required this.controller,
    required this.activeQuery,
    required this.label,
    required this.hint,
    required this.onSubmit,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeQuery.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          minLines: 1,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.auto_awesome_outlined),
            suffixIcon: active
                ? IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close),
                  )
                : IconButton(
                    onPressed: () => onSubmit(controller.text),
                    icon: const Icon(Icons.arrow_forward),
                  ),
          ),
          onSubmitted: onSubmit,
        ),
      ],
    );
  }
}
