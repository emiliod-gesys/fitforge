import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/social.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';
import '../../widgets/friends_ranking_card.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/social_notifications_sheet.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest(String userId) async {
    final l10n = context.l10n;
    try {
      await ref.read(socialServiceProvider).sendFriendRequest(userId);
      ref.invalidate(friendshipsProvider);
      ref.invalidate(friendRankingProvider);
      ref.invalidate(userSearchProvider(_query));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.requestSent)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.requestFailed('$e'))),
        );
      }
    }
  }

  Future<void> _accept(Friendship f) async {
    await ref.read(socialServiceProvider).acceptFriendRequest(f.id);
    ref.invalidate(friendshipsProvider);
    ref.invalidate(friendRankingProvider);
  }

  Future<void> _remove(Friendship f) async {
    await ref.read(socialServiceProvider).removeFriendship(f.id);
    ref.invalidate(friendshipsProvider);
    ref.invalidate(friendRankingProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final friendshipsAsync = ref.watch(friendshipsProvider);
    final rankingAsync = ref.watch(friendRankingProvider);
    final searchAsync = _query.length >= 2 ? ref.watch(userSearchProvider(_query)) : null;
    final uid = ref.watch(authStateProvider).valueOrNull?.session?.user.id;

    return Scaffold(
      appBar: FitForgeAppBar(
        title: l10n.socialTitle,
        automaticallyImplyLeading: false,
        actions: const [
          SocialNotificationsBellButton(),
        ],
      ),
      body: friendshipsAsync.when(
        loading: () => const Center(child: FitForgeLoadingIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorGeneric('$e'))),
        data: (friendships) {
          final pending = friendships.where((f) => f.status == FriendshipStatus.pending).toList();
          final friends = friendships.where((f) => f.status == FriendshipStatus.accepted).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(friendshipsProvider);
              ref.invalidate(friendRankingProvider);
              ref.invalidate(socialNotificationsProvider);
              ref.invalidate(socialUnreadCountProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SearchCard(
                  hintText: l10n.searchFriendsHint,
                  controller: _searchController,
                  showClear: _query.isNotEmpty,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
                if (searchAsync != null) ...[
                  const SizedBox(height: 12),
                  searchAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: FitForgeLoadingIndicator(size: 32)),
                    ),
                    error: (e, _) => Text(l10n.searchFailed('$e'), style: const TextStyle(color: AppColors.error)),
                    data: (users) {
                      if (users.isEmpty) {
                        return Text(l10n.noResults, style: const TextStyle(color: AppColors.textMuted));
                      }
                      return Column(
                        children: users
                            .map(
                              (u) => ListTile(
                                leading: ProfileAvatar(
                                  avatarUrl: u.avatarUrl,
                                  radius: 20,
                                  fallbackLetter: u.label,
                                ),
                                title: Text(u.label),
                                subtitle: u.email != null ? Text(u.email!, style: const TextStyle(color: AppColors.textMuted)) : null,
                                trailing: IconButton(
                                  icon: const Icon(Icons.person_add_outlined, color: AppColors.orange),
                                  onPressed: () => _sendRequest(u.id),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
                if (friends.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionHeader(title: l10n.friendsRanking),
                  rankingAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: FitForgeLoadingIndicator(size: 32)),
                    ),
                    error: (e, _) => Text(l10n.errorGeneric('$e')),
                    data: (entries) => FriendsRankingCard(entries: entries, l10n: l10n),
                  ),
                ],
                if (pending.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionHeader(title: l10n.pendingRequests),
                  ...pending.map((f) {
                    final friend = uid != null ? f.friendFor(uid) : FriendUser(id: f.addresseeId);
                    final incoming = uid != null && f.isIncoming(uid);
                    return Card(
                      color: AppColors.card,
                      child: ListTile(
                        leading: ProfileAvatar(
                          avatarUrl: friend.avatarUrl,
                          radius: 20,
                          fallbackLetter: friend.label,
                        ),
                        title: Text(friend.label),
                        subtitle: Text(incoming ? l10n.wantsToBeFriend : l10n.requestSentLabel),
                        trailing: incoming
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check, color: AppColors.orange),
                                    onPressed: () => _accept(f),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                                    onPressed: () => _remove(f),
                                  ),
                                ],
                              )
                            : IconButton(
                                icon: const Icon(Icons.close, color: AppColors.textMuted),
                                onPressed: () => _remove(f),
                              ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 24),
                _SectionHeader(title: l10n.friendsCount(friends.length)),
                if (friends.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l10n.searchFriendsEmpty,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  )
                else
                  ...friends.map((f) {
                    final friend = uid != null ? f.friendFor(uid) : FriendUser(id: f.requesterId);
                    return Card(
                      color: AppColors.card,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: ProfileAvatar(
                          avatarUrl: friend.avatarUrl,
                          radius: 20,
                          fallbackLetter: friend.label,
                        ),
                        title: Text(friend.label),
                        subtitle: Text(
                          l10n.playerLevelTitle(friend.level),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/social/friend/${friend.id}'),
                        onLongPress: () => _confirmRemove(context, friend.label, () => _remove(f)),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmRemove(BuildContext context, String name, VoidCallback onConfirm) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeFriendTitle),
        content: Text(l10n.removeFriendBody(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool showClear;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchCard({
    required this.hintText,
    required this.controller,
    required this.showClear,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
            suffixIcon: showClear
                ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
                : null,
          ),
        ),
      ),
    );
  }
}
