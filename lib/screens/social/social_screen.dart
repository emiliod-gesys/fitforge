import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/social.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/fitforge_loading_indicator.dart';

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
  }

  Future<void> _remove(Friendship f) async {
    await ref.read(socialServiceProvider).removeFriendship(f.id);
    ref.invalidate(friendshipsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final friendshipsAsync = ref.watch(friendshipsProvider);
    final searchAsync = _query.length >= 2 ? ref.watch(userSearchProvider(_query)) : null;
    final notificationsAsync = ref.watch(socialNotificationsProvider);
    final uid = ref.watch(authStateProvider).valueOrNull?.session?.user.id;

    return Scaffold(
      appBar: FitForgeAppBar(title: l10n.socialTitle),
      body: friendshipsAsync.when(
        loading: () => const Center(child: FitForgeLoadingIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorGeneric('$e'))),
        data: (friendships) {
          final pending = friendships.where((f) => f.status == FriendshipStatus.pending).toList();
          final friends = friendships.where((f) => f.status == FriendshipStatus.accepted).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(friendshipsProvider);
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
                                leading: CircleAvatar(
                                  backgroundImage: u.avatarUrl != null ? NetworkImage(u.avatarUrl!) : null,
                                  child: u.avatarUrl == null ? Text(u.label[0].toUpperCase()) : null,
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
                const SizedBox(height: 24),
                _SectionHeader(
                  title: l10n.notifications,
                  trailing: notificationsAsync.maybeWhen(
                    data: (list) {
                      if (list.any((n) => n.isUnread)) {
                        return TextButton(
                          onPressed: () async {
                            await ref.read(socialServiceProvider).markAllNotificationsRead();
                            ref.invalidate(socialNotificationsProvider);
                            ref.invalidate(socialUnreadCountProvider);
                          },
                          child: Text(l10n.markRead),
                        );
                      }
                      return null;
                    },
                    orElse: () => null,
                  ),
                ),
                notificationsAsync.when(
                  loading: () => const FitForgeLoadingIndicator(size: 32),
                  error: (e, _) => Text(l10n.errorGeneric('$e')),
                  data: (notifications) {
                    if (notifications.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          l10n.friendWorkoutNotify,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      );
                    }
                    return Column(
                      children: notifications.take(10).map((n) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: n.isUnread ? AppColors.orange.withValues(alpha: 0.2) : AppColors.cardElevated,
                            child: Icon(
                              Icons.fitness_center,
                              color: n.isUnread ? AppColors.orange : AppColors.textMuted,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            n.message,
                            style: TextStyle(
                              fontWeight: n.isUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            l10n.timeAgo(n.createdAt),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          onTap: () async {
                            if (n.isUnread) {
                              await ref.read(socialServiceProvider).markNotificationRead(n.id);
                              ref.invalidate(socialNotificationsProvider);
                              ref.invalidate(socialUnreadCountProvider);
                            }
                            if (n.actorId.isNotEmpty && context.mounted) {
                              context.push('/social/friend/${n.actorId}');
                            }
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                if (pending.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionHeader(title: l10n.pendingRequests),
                  ...pending.map((f) {
                    final friend = uid != null ? f.friendFor(uid) : FriendUser(id: f.addresseeId);
                    final incoming = uid != null && f.isIncoming(uid);
                    return Card(
                      color: AppColors.card,
                      child: ListTile(
                        leading: CircleAvatar(child: Text(friend.label[0].toUpperCase())),
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
                        leading: CircleAvatar(
                          backgroundImage: friend.avatarUrl != null ? NetworkImage(friend.avatarUrl!) : null,
                          child: friend.avatarUrl == null ? Text(friend.label[0].toUpperCase()) : null,
                        ),
                        title: Text(friend.label),
                        subtitle: friend.email != null
                            ? Text(friend.email!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))
                            : null,
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
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          if (trailing != null) trailing!,
        ],
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
