import 'package:flutter/material.dart';

/// Muestra [label] en un SnackBar al tocar [child].
class TappableBadge extends StatelessWidget {
  final String label;
  final Widget child;

  const TappableBadge({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(label, textAlign: TextAlign.center),
              duration: const Duration(milliseconds: 2000),
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      child: child,
    );
  }
}
