import 'package:flutter/material.dart';
import 'fitforge_logo.dart';

class FitForgeAppBar extends StatelessWidget implements PreferredSizeWidget {
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
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: Row(
        children: [
          const FitForgeLogo.icon(height: 32),
          if (showWordmark || title != null) ...[
            const SizedBox(width: 10),
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
