import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_glass.dart';
import 'fitforge_logo.dart';

class FitForgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const double _logoHeight = 36;
  static const double _toolbarHeight = kToolbarHeight;

  final String? title;
  final List<Widget>? actions;
  final bool showWordmark;
  /// Marca/isotipo a la izquierda. En pantallas de tarea conviene `false`.
  final bool showBrandMark;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  const FitForgeAppBar({
    super.key,
    this.title,
    this.actions,
    this.showWordmark = false,
    this.showBrandMark = false,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        _toolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final Widget titleWidget;
    if (showBrandMark || showWordmark) {
      titleWidget = Row(
        children: [
          if (showBrandMark)
            SizedBox(
              height: _toolbarHeight,
              child: const Center(
                child: FitForgeLogo.icon(height: _logoHeight),
              ),
            ),
          if (showWordmark || title != null) ...[
            if (showBrandMark) const SizedBox(width: 10),
            if (title != null)
              Flexible(
                child: Text(
                  title!,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              )
            else if (showWordmark)
              const FitForgeLogo.wordmark(height: 22),
          ],
        ],
      );
    } else {
      titleWidget = Text(
        title ?? '',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }

    return AppBar(
      toolbarHeight: _toolbarHeight,
      titleSpacing: leading == null && automaticallyImplyLeading ? 16 : 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: titleWidget,
      actions: actions,
      bottom: bottom,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.07),
              AppColors.surface.withValues(alpha: 0.82),
            ],
          ),
          border: Border(
            bottom: BorderSide(color: AppGlass.border(0.10)),
          ),
        ),
      ),
    );
  }
}
