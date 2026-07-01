import 'package:flutter/material.dart';
import 'fitforge_logo.dart';

class FitForgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const double _logoHeight = 50;
  static const double _toolbarHeight = kToolbarHeight;

  final String? title;
  final List<Widget>? actions;
  final bool showWordmark;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  const FitForgeAppBar({
    super.key,
    this.title,
    this.actions,
    this.showWordmark = true,
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
    return AppBar(
      toolbarHeight: _toolbarHeight,
      titleSpacing: leading == null && automaticallyImplyLeading ? 16 : 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: Row(
        children: [
          SizedBox(
            height: _toolbarHeight,
            child: const Center(
              child: FitForgeLogo.icon(height: _logoHeight),
            ),
          ),
          if (showWordmark || title != null) ...[
            const SizedBox(width: 8),
            if (title != null)
              Flexible(
                child: Text(
                  title!,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              )
            else
              const FitForgeLogo.wordmark(height: 22),
          ],
        ],
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}
