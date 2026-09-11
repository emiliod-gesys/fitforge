import 'package:flutter/material.dart';

import '../core/utils/superset_groups.dart';
import '../l10n/l10n_extensions.dart';

abstract final class SupersetRoundsSheet {
  static List<int> get options => [
        for (var i = SupersetGroups.minRounds; i <= SupersetGroups.maxRounds; i++) i,
      ];

  static Future<int?> show(
    BuildContext context, {
    required int selected,
    int min = SupersetGroups.minRounds,
  }) {
    final l10n = context.l10n;
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.supersetRounds,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final count in options)
                      ChoiceChip(
                        label: Text(l10n.supersetRoundsCount(count)),
                        selected: selected == count,
                        onSelected: count < min
                            ? null
                            : (_) => Navigator.pop(ctx, count),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
