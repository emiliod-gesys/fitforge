import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/player_level.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/social.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/social/friend_tile.dart';
import '../../widgets/social/pending_request_tile.dart';
import '../../widgets/social/social_hero_card.dart';
import '../../widgets/social/social_search_bar.dart';
import '../../widgets/social/social_section_header.dart';

class SocialFriendsTab extends ConsumerWidget {
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final int? friendsRank;
  final int? globalRank;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String userId) onSendRequest;
  final Future<void> Function(Friendship friendship) onAccept;
  final Future<void> Function(Friendship friendship) onRemove;
  final void Function(BuildContext context, String name, VoidCallback onConfirm) onConfirmRemove;

  const SocialFriendsTab({
    super.key,
    required this.searchController,
    required this.query,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.friendsRank,
    required this.globalRank,
    required this.onRefresh,
    required this.onSendRequest,
    required this.onAccept,
    required this.onRemove,
    required this.onConfirmRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final friendshipsAsync = ref.watch(friendshipsProvider);
    final mutedAsync = ref.watch(mutedFriendsProvider);
    final profileAsync = ref.watch(profileProvider);
    final searchAsync = query.length >= 2 ? ref.watch(userSearchProvider(query)) : null;
    final uid = ref.watch(authStateProvider).valueOrNull?.session?.user.id;

    final friendships = friendshipsAsync.valueOrNull ?? [];
    final mutedIds = mutedAsync.valueOrNull ?? const <String>{};
    final pending = friendships.where((f) => f.status == FriendshipStatus.pending).toList();
    final friends = friendships.where((f) => f.status == FriendshipStatus.accepted).toList();
    final incomingPending = uid == null
        ? 0
        : pending.where((f) => f.isIncoming(uid)).length;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          profileAsync.when(
            data: (profile) {
              final progress = profile == null
                  ? null
                  : PlayerLevelCalculator.fromTotalXp(profile.totalXp);
              return SocialHeroCard(
                progress: progress,
                friendsCount: friends.length,
                pendingCount: incomingPending,
                friendsRank: friendsRank,
                globalRank: globalRank,
                isLoading: friendshipsAsync.isLoading,
                l10n: l10n,
              );
            },
            loading: () => SocialHeroCard(
              progress: null,
              friendsCount: 0,
              pendingCount: 0,
              friendsRank: null,
              globalRank: null,
              isLoading: true,
              l10n: l10n,
            ),
            error: (_, __) => SocialHeroCard(
              progress: null,
              friendsCount: friends.length,
              pendingCount: incomingPending,
              friendsRank: friendsRank,
              globalRank: globalRank,
              isLoading: false,
              l10n: l10n,
            ),
          ),
          const SizedBox(height: 16),
          SocialSearchBar(
            hintText: l10n.searchFriendsHint,
            controller: searchController,
            showClear: searchController.text.isNotEmpty,
            onChanged: onSearchChanged,
            onClear: onSearchClear,
          ),
          if (searchAsync != null) ...[
            const SizedBox(height: 12),
            searchAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: FitForgeLoadingIndicator(size: 32)),
              ),
              error: (e, _) => Text(
                l10n.searchFailed('$e'),
                style: const TextStyle(color: AppColors.error),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return Text(
                    l10n.noResults,
                    style: const TextStyle(color: AppColors.textMuted),
                  );
                }
                return Column(
                  children: users
                      .map(
                        (user) => FriendTile(
                          friend: user,
                          trailing: IconButton(
                            icon: const Icon(Icons.person_add_outlined, color: AppColors.orange),
                            onPressed: () => onSendRequest(user.id),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 20),
            SocialSectionHeader(title: l10n.pendingRequests),
            ...pending.map((f) {
              final friend = uid != null ? f.friendFor(uid) : FriendUser(id: f.addresseeId);
              final incoming = uid != null && f.isIncoming(uid);
              return PendingRequestTile(
                friend: friend,
                subtitle: incoming ? l10n.wantsToBeFriend : l10n.requestSentLabel,
                incoming: incoming,
                onAccept: incoming ? () => onAccept(f) : null,
                onDecline: () => onRemove(f),
              );
            }),
          ],
          const SizedBox(height: 20),
          SocialSectionHeader(title: l10n.friendsCount(friends.length)),
          friendshipsAsync.when(
            loading: () => const _FriendsSkeleton(),
            error: (e, _) => Text(l10n.errorGeneric('$e')),
            data: (_) {
              if (friends.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.searchFriendsEmpty,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                );
              }
              return Column(
                children: friends.map((f) {
                  final friend = uid != null ? f.friendFor(uid) : FriendUser(id: f.requesterId);
                  final isMuted = mutedIds.contains(friend.id);
                  return FriendTile(
                    friend: friend,
                    isMuted: isMuted,
                    onTap: () => context.push('/social/friend/${friend.id}'),
                    onLongPress: () => onConfirmRemove(
                      context,
                      friend.label,
                      () => onRemove(f),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                      onSelected: (value) async {
                        if (value == 'remove') {
                          onConfirmRemove(
                            context,
                            friend.label,
                            () => onRemove(f),
                          );
                        } else if (value == 'mute' || value == 'unmute') {
                          await ref.read(socialServiceProvider).setFriendMuted(
                                friend.id,
                                value == 'mute',
                              );
                          ref.invalidate(mutedFriendsProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value == 'mute'
                                      ? l10n.friendMuted(friend.label)
                                      : l10n.friendUnmuted(friend.label),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: isMuted ? 'unmute' : 'mute',
                          child: Text(isMuted ? l10n.unmuteFriend : l10n.muteFriend),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Text(
                            l10n.removeFriendTitle,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FriendsSkeleton extends StatelessWidget {
  const _FriendsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardElevated,
      highlightColor: AppColors.card,
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
