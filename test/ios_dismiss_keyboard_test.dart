import 'package:fitforge/widgets/ios_dismiss_keyboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('en iOS un toque fuera del campo oculta el teclado', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final focus = FocusNode();
      addTearDown(focus.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: IosDismissKeyboard(
            child: Scaffold(
              body: Column(
                children: [
                  TextField(focusNode: focus),
                  const Text('fuera'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(focus.hasFocus, isTrue);

      await tester.tap(find.text('fuera'));
      await tester.pump();
      expect(focus.hasFocus, isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('en Android un toque fuera no quita el foco', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final focus = FocusNode();
      addTearDown(focus.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: IosDismissKeyboard(
            child: Scaffold(
              body: Column(
                children: [
                  TextField(focusNode: focus),
                  const Text('fuera'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.tap(find.text('fuera'));
      await tester.pump();
      expect(focus.hasFocus, isTrue);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
