import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_glass.dart';
import '../../core/theme/app_tokens.dart';
import 'ff_glass.dart';

class FfNavSpinnerItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badgeCount;

  const FfNavSpinnerItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
  });
}

/// Barra inferior tipo spinner horizontal: se desplaza y centra el ítem activo.
class FfNavSpinner extends StatefulWidget {
  final List<FfNavSpinnerItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const FfNavSpinner({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<FfNavSpinner> createState() => _FfNavSpinnerState();
}

class _FfNavSpinnerState extends State<FfNavSpinner> {
  final _scrollController = ScrollController();
  final _keys = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
    _syncKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerSelected(animated: false));
  }

  @override
  void didUpdateWidget(covariant FfNavSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncKeys();
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.items.length != widget.items.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerSelected(animated: true));
    }
  }

  void _syncKeys() {
    while (_keys.length < widget.items.length) {
      _keys.add(GlobalKey());
    }
    if (_keys.length > widget.items.length) {
      _keys.removeRange(widget.items.length, _keys.length);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _centerSelected({required bool animated}) async {
    if (!mounted || widget.selectedIndex < 0 || widget.selectedIndex >= _keys.length) {
      return;
    }
    final key = _keys[widget.selectedIndex];
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: animated ? const Duration(milliseconds: 280) : Duration.zero,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return FfGlass.bar(
      blur: true,
      blurSigma: AppGlass.blurSigma,
      fillOpacity: 0.72,
      showBorder: false,
      showShadow: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppGlass.border(0.16)),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: AppTokens.navBarHeight,
            child: Stack(
              children: [
                ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space20,
                    vertical: AppTokens.space12,
                  ),
                  itemCount: widget.items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppTokens.space8),
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    final selected = index == widget.selectedIndex;
                    return KeyedSubtree(
                      key: _keys[index],
                      child: _NavChip(
                        item: item,
                        selected: selected,
                        accent: accent,
                        onTap: () {
                          if (index == widget.selectedIndex) return;
                          HapticFeedback.selectionClick();
                          widget.onSelected(index);
                        },
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 28,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.card.withValues(alpha: 0.85),
                            AppColors.card.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 28,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.card.withValues(alpha: 0),
                            AppColors.card.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  final FfNavSpinnerItem item;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _NavChip({
    required this.item,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? accent : AppColors.textMuted;
    final icon = selected ? item.selectedIcon : item.icon;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 16 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.50)
                  : AppGlass.border(0.12),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: item.badgeCount > 0,
                label: Text(item.badgeCount > 9 ? '9+' : '${item.badgeCount}'),
                child: Icon(icon, size: selected ? 22 : 20, color: fg),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: -0.1,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
