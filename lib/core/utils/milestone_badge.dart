/// Medallas de milestones por tier (compartidas entre categorías).
abstract final class MilestoneBadge {
  static String assetPathForTier(int tier) {
    return 'assets/images/milestones/transparent/tier_$tier.png';
  }
}
