import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'fitforge_logo.dart';

class FitForgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Lockup FORGEN en la esquina izquierda.
  static const double _logoHeight = 40;
  static const double _brandLeadingWidth = 56;
  static const double _toolbarHeight = kToolbarHeight;

  final String? title;
  final List<Widget>? actions;
  final bool showWordmark;
  /// Muestra el lockup de marca a la izquierda (pestañas principales).
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
    final Widget? leadingWidget;
    if (showBrandMark) {
      leadingWidget = const Padding(
        padding: EdgeInsets.only(left: 8),
        child: Center(
          child: FitForgeLogo.full(height: _logoHeight),
        ),
      );
    } else {
      leadingWidget = leading;
    }

    final Widget titleWidget;
    if (showWordmark && title == null) {
      titleWidget = const FitForgeLogo.wordmark(height: 22);
    } else {
      titleWidget = Text(
        title ?? '',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }

    return AppBar(
      toolbarHeight: _toolbarHeight,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      automaticallyImplyLeading: !showBrandMark && automaticallyImplyLeading,
      leading: leadingWidget,
      leadingWidth: showBrandMark ? _brandLeadingWidth : null,
      title: titleWidget,
      actions: actions,
      bottom: bottom,
    );
  }
}
