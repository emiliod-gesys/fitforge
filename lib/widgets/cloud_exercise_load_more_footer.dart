import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import 'fitforge_loading_indicator.dart';

class CloudExerciseLoadMoreFooter extends StatelessWidget {
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  const CloudExerciseLoadMoreFooter({
    super.key,
    required this.isLoadingMore,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: isLoadingMore
          ? const Center(child: FitForgeLoadingIndicator(size: 28))
          : OutlinedButton.icon(
              onPressed: onLoadMore,
              icon: const Icon(Icons.expand_more),
              label: Text(l10n.cloudCatalogLoadMore),
            ),
    );
  }
}

class CloudExerciseSearchStatus extends StatelessWidget {
  final bool isLoading;
  final String? error;

  const CloudExerciseSearchStatus({
    super.key,
    required this.isLoading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && error == null) return const SizedBox.shrink();
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isLoading) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 4),
          Text(
            l10n.cloudCatalogSearching,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.cloudCatalogSearchError,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}
