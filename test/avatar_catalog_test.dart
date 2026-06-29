import 'package:fitforge/data/avatar_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

      expect(forOwner.any((o) => o.id == 'admin'), isTrue);
      expect(forOther.any((o) => o.id == 'admin'), isFalse);
    });
  });
}
