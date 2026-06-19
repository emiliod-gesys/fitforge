import 'package:flutter_test/flutter_test.dart';
import 'package:fitforge/core/utils/milestone_badge.dart';

void main() {
  test('assetPathForTier apunta a transparent/', () {
    expect(
      MilestoneBadge.assetPathForTier(1),
      'assets/images/milestones/transparent/tier_1.png',
    );
  });
}
