import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Exercise catalog bundled media', () {
    late List<Map<String, dynamic>> exercises;

    setUpAll(() async {
      final raw = await rootBundle.loadString('assets/data/exercise_catalog.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      exercises = (decoded['exercises'] as List)
          .cast<Map<String, dynamic>>();
    });

    test('every exercise uses a local asset path', () {
      for (final entry in exercises) {
        final id = entry['id'] as String;
        final imageUrl = entry['imageUrl'] as String?;
        expect(imageUrl, isNotNull, reason: 'missing imageUrl for $id');
        expect(
          imageUrl!.startsWith('assets/'),
          isTrue,
          reason: '$id still points to remote URL: $imageUrl',
        );
      }
    });

    test('every imageUrl file exists on disk', () {
      for (final entry in exercises) {
        final id = entry['id'] as String;
        final imageUrl = entry['imageUrl'] as String;
        final file = File(imageUrl);
        expect(file.existsSync(), isTrue, reason: 'missing file for $id');
        expect(
          file.lengthSync(),
          greaterThan(512),
          reason: 'tiny or empty file for $id',
        );
      }
    });

    test('every imageUrl loads from the asset bundle', () async {
      for (final entry in exercises) {
        final id = entry['id'] as String;
        final imageUrl = entry['imageUrl'] as String;
        final data = await rootBundle.load(imageUrl);
        expect(
          data.lengthInBytes,
          greaterThan(512),
          reason: 'bundle asset too small for $id',
        );
      }
    });
  });
}
