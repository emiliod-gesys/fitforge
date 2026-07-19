import 'package:fitforge/core/utils/catalog_muscle_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fixUtf8Mojibake repairs corrupted Spanish accents', () {
    expect(CatalogMuscleLabels.fixUtf8Mojibake('TrÃ­ceps'), 'Tríceps');
    expect(CatalogMuscleLabels.fixUtf8Mojibake('BÃ­ceps'), 'Bíceps');
    expect(CatalogMuscleLabels.fixUtf8Mojibake('GlÃºteos'), 'Glúteos');
  });

  test('canonicalMuscleKey normalizes English and typo variants', () {
    expect(CatalogMuscleLabels.canonicalMuscleKey('triceps'), 'Tríceps');
    expect(CatalogMuscleLabels.canonicalMuscleKey('Triceps'), 'Tríceps');
    expect(CatalogMuscleLabels.canonicalMuscleKey('Pechos'), 'Pecho');
    expect(CatalogMuscleLabels.canonicalMuscleKey('pectorals'), 'Pecho');
  });

  test('englishMuscleLabel returns English labels', () {
    expect(CatalogMuscleLabels.englishMuscleLabel('Tríceps'), 'Triceps');
    expect(CatalogMuscleLabels.englishMuscleLabel('Pecho'), 'Chest');
  });
}
