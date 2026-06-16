import 'package:flutter/material.dart';
import 'fitforge_logo.dart';

class FitForgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showWordmark;

  const FitForgeAppBar({
    super.key,
    this.title,
    this.actions,
    this.showWordmark = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FitForgeLogo.icon(height: 32),
          if (showWordmark || title != null) ...[
            const SizedBox(width: 10),
            if (title != null)
              Text(title!)
            else
              const FitForgeLogo.wordmark(height: 22),
          ],
        ],
      ),
      actions: actions,
    );
  }
}
