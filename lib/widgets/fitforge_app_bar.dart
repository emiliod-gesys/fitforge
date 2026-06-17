import 'package:flutter/material.dart';
import 'fitforge_logo.dart';

class FitForgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showWordmark;
  final Widget? leading;

  const FitForgeAppBar({
    super.key,
    this.title,
    this.actions,
    this.showWordmark = true,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
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
    );
  }
}
