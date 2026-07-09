import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../data/avatar_catalog.dart';
import '../l10n/l10n_extensions.dart';
import '../core/theme/app_accent.dart';

Future<String?> showAvatarPickerSheet(
  BuildContext context, {
  String? selectedId,
  String? userEmail,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _AvatarPickerSheet(
      selectedId: selectedId,
      userEmail: userEmail,
    ),
  );
}

class _AvatarPickerSheet extends StatelessWidget {
  final String? selectedId;
  final String? userEmail;

  const _AvatarPickerSheet({
    this.selectedId,
    this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentKey = AvatarCatalog.isCatalogValue(selectedId)
        ? selectedId!.substring(AvatarCatalog.prefix.length)
        : null;
    final availableOptions = AvatarCatalog.pickerOptionsForUser(
      userEmail,
      selectedStorageId: selectedId,
    );
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

    return SafeArea(
      child: SizedBox(
        height: maxHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.chooseAvatar,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${l10n.chooseAvatarHint} (${availableOptions.length})',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: availableOptions.length,
                    itemBuilder: (context, index) {
                      final option = availableOptions[index];
                      final isSelected = option.id == currentKey;

                      return InkWell(
                        onTap: () => Navigator.pop(context, AvatarCatalog.toStorageId(option.id)),
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: ColoredBox(
                                  color: AppColors.surface,
                                  child: Image.asset(
                                    option.assetPath,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    gaplessPlayback: true,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: AppColors.textMuted.withValues(alpha: 0.6),
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (isSelected)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: context.accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, size: 14, color: Colors.white),
                              ),
                            ),
                          if (isSelected)
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: context.accentColor, width: 2.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
