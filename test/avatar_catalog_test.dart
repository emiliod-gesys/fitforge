import 'dart:io';

import 'package:fitforge/data/avatar_catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AvatarCatalog assets', () {
    test('every catalog entry has a PNG on disk', () {
      for (final option in AvatarCatalog.options) {
        expect(
          File(option.assetPath).existsSync(),
          isTrue,
          reason: 'missing file for ${option.id}',
        );
      }
    });

    test('every catalog entry loads from the asset bundle', () async {
      for (final option in AvatarCatalog.options) {
        final data = await rootBundle.load(option.assetPath);
        expect(
          data.lengthInBytes,
          greaterThan(1024),
          reason: 'empty or tiny asset for ${option.id}',
        );
      }
    });

    test('catalog ids are unique', () {
      final ids = AvatarCatalog.options.map((o) => o.id).toList();
      expect(ids.length, ids.toSet().length);
    });
  });

  group('AvatarCatalog exclusives', () {
    test('admin avatar only visible to exclusive email', () {
      const adminId = 'catalog:admin';

      expect(AvatarCatalog.canSelect(adminId, 'emiliodiaz@gesys.gt'), isTrue);
      expect(AvatarCatalog.canSelect(adminId, 'EmilioDiaz@gesys.gt'), isTrue);
      expect(AvatarCatalog.canSelect(adminId, 'other@gesys.gt'), isFalse);
      expect(AvatarCatalog.canSelect(adminId, null), isFalse);
    });

    test('optionsForUser hides exclusive avatars from others', () {
      final forOwner = AvatarCatalog.optionsForUser('emiliodiaz@gesys.gt');
      final forOther = AvatarCatalog.optionsForUser('other@gesys.gt');

      expect(forOwner.length, AvatarCatalog.options.length);
      expect(forOther.length, AvatarCatalog.options.length - 1);
      expect(forOwner.any((o) => o.id == 'admin'), isTrue);
      expect(forOther.any((o) => o.id == 'admin'), isFalse);
    });
  });
}
