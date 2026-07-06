import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/leaderboard.dart';
import '../../models/social.dart';
import '../../providers/app_providers.dart';
import '../../widgets/fitforge_app_bar.dart';
import '../../widgets/leaderboards_section.dart';
import '../../widgets/social_notifications_sheet.dart';
import 'social_friends_tab.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _query = '';
  Timer? _searchDebounce;
  late TabController _tabController;

  static const _friendsRankKey = (
    scope: LeaderboardScope.friends,
    metric: LeaderboardMetric.level,
    period: LeaderboardPeriod.all,
    limit: LeaderboardPagination.pageSize,
  );

  static const _globalRankKey = (
    scope: LeaderboardScope.global,
    metric: LeaderboardMetric.level,
    period: LeaderboardPeriod.all,
    limit: LeaderboardPagination.pageSize,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _onSearchClear() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _query = '');
  }

  Future<void> _sendRequest(String userId) async {
    final l10n = context.l10n;
    try {
      await ref.read(socialServiceProvider).sendFriendRequest(userId);
      ref.invalidate(friendshipsProvider);
      ref.invalidate(leaderboardProvider);
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
    ref.invalidate(leaderboardProvider);
  }

  Future<void> _remove(Friendship f) async {
    await ref.read(socialServiceProvider).removeFriendship(f.id);
    ref.invalidate(friendshipsProvider);
    ref.invalidate(leaderboardProvider);
    ref.invalidate(friendFavoriteRoutinesProvider);
    ref.invalidate(mutedFriendsProvider);
  }

  int? _userRank(LeaderboardResult? result) {
    if (result == null) return null;
    for (final entry in result.entries) {
      if (entry.isCurrentUser) return entry.rank;
    }
    return result.currentUserOutsideTop?.rank;
  }

  Future<void> _onFriendsRefresh() async {
    HapticFeedback.lightImpact();
    ref.invalidate(friendshipsProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(leaderboardProvider);
    ref.invalidate(socialNotificationsProvider);
    ref.invalidate(socialUnreadCountProvider);
    ref.invalidate(mutedFriendsProvider);
    if (_query.length >= 2) ref.invalidate(userSearchProvider(_query));
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rankAsync = ref.watch(leaderboardProvider(_friendsRankKey));
    final globalRankAsync = ref.watch(leaderboardProvider(_globalRankKey));

    return Scaffold(
      appBar: FitForgeAppBar(
        title: l10n.socialTitle,
        automaticallyImplyLeading: false,
        actions: const [
          SocialNotificationsBellButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.orange,
          labelColor: AppColors.orange,
          unselectedLabelColor: AppColors.textMuted,
          tabs: [
            Tab(text: l10n.socialTabFriends),
            Tab(text: l10n.socialTabLeaderboards),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SocialFriendsTab(
            searchController: _searchController,
            query: _query,
            onSearchChanged: _onSearchChanged,
            onSearchClear: _onSearchClear,
            friendsRank: _userRank(rankAsync.valueOrNull),
            globalRank: _userRank(globalRankAsync.valueOrNull),
            onRefresh: _onFriendsRefresh,
            onSendRequest: _sendRequest,
            onAccept: _accept,
            onRemove: _remove,
            onConfirmRemove: _confirmRemove,
          ),
          const LeaderboardsSection(),
        ],
      ),
    );
  }
}
