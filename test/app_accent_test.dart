import 'package:fitforge/core/theme/app_accent.dart';
import 'package:fitforge/core/theme/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cobalt is the default application accent', () {
    expect(AppAccent.defaultAccent, AppAccent.cobalt);
    expect(AppAccent.fromCode(null), AppAccent.cobalt);
    expect(AppColors.orange, AppAccent.cobalt.primary);
    expect(FitForgeAccent.cobalt.accent, AppAccent.cobalt);
    expect(FitForgeAccent.cobalt.accentColor, AppAccent.cobalt.primary);
  });

  test('all accent codes round-trip and use distinct palettes', () {
    expect(AppAccent.values, hasLength(12));

    final primaryColors = <int>{};
    for (final accent in AppAccent.values) {
      expect(AppAccent.fromCode(accent.name), accent);
      expect(accent.heroGradientColors, hasLength(4));
      expect(accent.heroGradientColors, contains(accent.primary));
      primaryColors.add(accent.primary.toARGB32());
    }

    expect(primaryColors, hasLength(AppAccent.values.length));
  });
}
