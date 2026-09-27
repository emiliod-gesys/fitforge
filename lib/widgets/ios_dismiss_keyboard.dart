import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// En iOS, un toque fuera del campo con foco oculta el teclado.
class IosDismissKeyboard extends StatelessWidget {
  const IosDismissKeyboard({super.key, required this.child});

  final Widget child;

  static void unfocusIfTapOutside(PointerUpEvent event) {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    final focus = FocusManager.instance.primaryFocus;
    final context = focus?.context;
    if (focus == null || context == null) return;
    final box = context.findRenderObject();
    if (box is RenderBox && box.attached && box.hasSize) {
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (rect.contains(event.position)) return;
    }
    focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerUp: unfocusIfTapOutside,
      child: child,
    );
  }
}
