import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/milestones.dart';
import '../core/utils/supabase_datetime.dart';
import '../core/utils/workout_streak.dart';
import '../models/leaderboard.dart';
import '../models/profile.dart';
import '../models/social.dart';
import 'supabase_service.dart';

class SocialService {
  final _client = SupabaseService.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<FriendUser>> searchUsers(String query) async {
    if (_userId == null) return [];
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final data = await _client.rpc('search_users_for_friend', params: {'p_query': trimmed});
    return (data as List)
        .map((row) => FriendUser.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> sendFriendRequest(String addresseeId) async {
    final uid = _userId;
    if (uid == null) return;

    await _client.from('friendships').insert({
      'requester_id': uid,
      'addressee_id': addresseeId,
      'status': 'pending',
    });
  }

  Future<void> acceptFriendRequest(String friendshipId) async {
    await _client.from('friendships').update({'status': 'accepted'}).eq('id', friendshipId);
  }

  Future<void> removeFriendship(String friendshipId) async {
    await _client.from('friendships').delete().eq('id', friendshipId);
  }

  Future<List<Friendship>> getFriendships() async {
    final uid = _userId;
    if (uid == null) return [];

    final data = await _client
        .from('friendships')
        .select()
        .or('requester_id.eq.$uid,addressee_id.eq.$uid')
        .order('created_at', ascending: false);

    final rows = data as List;
    final friendships = rows
        .map((r) => Friendship.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();

    final profileIds = <String>{};
    for (final f in friendships) {
      profileIds.add(f.requesterId);
      profileIds.add(f.addresseeId);
    }
    profileIds.remove(uid);

    if (profileIds.isEmpty) return friendships;

    final profilesData = await _client
        .from('profiles')
        .select('id, display_name, avatar_url, email, total_xp')
        .inFilter('id', profileIds.toList());

    final profiles = {
      for (final p in profilesData as List)
        (p as Map)['id'] as String: FriendUser.fromJson(Map<String, dynamic>.from(p)),
    };

    return friendships.map((f) {
      return Friendship(
        id: f.id,
        requesterId: f.requesterId,
        addresseeId: f.addresseeId,
        status: f.status,
        createdAt: f.createdAt,
        requester: profiles[f.requesterId],
        addressee: profiles[f.addresseeId],
      );
    }).toList();
  }

  Future<FriendProfileView?> getFriendProfile(String friendId) async {
    final uid = _userId;
    if (uid == null) return null;

    final friendships = await getFriendships();
    final accepted = friendships.where(
      (f) =>
          f.status == FriendshipStatus.accepted &&
          (f.requesterId == friendId || f.addresseeId == friendId),
    );
    if (accepted.isEmpty) return null;

    final profileData = await _client
        .from('profiles')
        .select()
        .eq('id', friendId)
        .maybeSingle();

    if (profileData == null) return null;

    final prData = await _client
        .from('personal_records')
        .select()
        .eq('user_id', friendId)
        .order('one_rep_max', ascending: false);

    final datesData = await _client.rpc(
      'get_friend_workout_completion_dates',
      params: {'p_friend_id': friendId},
    );
    final completedDates = (datesData as List)
        .map((d) => SupabaseDateTime.parse(d as String))
        .toList();
    final weeklyStats = WorkoutStreakCalculator.fromCompletedDates(completedDates);

    final profile = UserProfile.fromJson(Map<String, dynamic>.from(profileData));

    final milestoneRaw = await _client.rpc(
      'get_friend_milestone_data',
      params: {'p_friend_id': friendId},
    );
    final milestoneTotals = milestoneRaw != null
        ? MilestonesCalculator.fromFriendData(
            Map<String, dynamic>.from(milestoneRaw as Map),
            profile: profile,
          )
        : MilestoneTotals.empty;

    final user = FriendUser.fromJson({
      'id': friendId,
      'display_name': profileData['display_name'],
      'avatar_url': profileData['avatar_url'],
      'email': profileData['email'],
      'total_xp': profileData['total_xp'],
    });

    return FriendProfileView(
      user: user,
      profile: profile,
      personalRecords: (prData as List)
          .map((r) => PersonalRecord.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList(),
      weeklyStats: weeklyStats,
      milestoneTotals: milestoneTotals,
    );
  }

  Future<LeaderboardResult> getLeaderboard({
    required LeaderboardMetric metric,
    required LeaderboardScope scope,
    required LeaderboardPeriod period,
    int limit = LeaderboardPagination.pageSize,
  }) async {
    final uid = _userId;
    if (uid == null) {
      return const LeaderboardResult(entries: []);
    }

    final data = await _client.rpc(
      'get_leaderboard',
      params: {
        'p_metric': metric.apiValue,
        'p_scope': scope.name,
        'p_period': period.apiValue,
        'p_limit': limit.clamp(1, LeaderboardPagination.maxLimit),
      },
    );

    if (data == null) {
      return const LeaderboardResult(entries: []);
    }

    return LeaderboardResult.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<SocialNotification>> getNotifications({int limit = 50}) async {
    final uid = _userId;
    if (uid == null) return [];

    final data = await _client
        .from('social_notifications')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(limit);

    final rows = (data as List)
        .map((r) => SocialNotification.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();

    final actorIds = rows.map((n) => n.actorId).toSet().toList();
    if (actorIds.isEmpty) return rows;

    final actorsData = await _client
        .from('profiles')
        .select('id, display_name, avatar_url, email')
        .inFilter('id', actorIds);

    final actors = {
      for (final a in actorsData as List)
        (a as Map)['id'] as String: FriendUser.fromJson(Map<String, dynamic>.from(a)),
    };

    return rows
        .map(
          (n) => SocialNotification(
            id: n.id,
            actorId: n.actorId,
            message: n.message,
            createdAt: n.createdAt,
            readAt: n.readAt,
            actor: actors[n.actorId],
          ),
        )
        .toList();
  }

  Future<int> getUnreadCount() async {
    final uid = _userId;
    if (uid == null) return 0;

    final data = await _client
        .from('social_notifications')
        .select('id')
        .eq('user_id', uid)
        .isFilter('read_at', null);

    return (data as List).length;
  }

  Future<void> markNotificationRead(String id) async {
    await _client
        .from('social_notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  Future<void> markAllNotificationsRead() async {
    final uid = _userId;
    if (uid == null) return;

    await _client
        .from('social_notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', uid)
        .isFilter('read_at', null);
  }

  RealtimeChannel subscribeToNotifications(void Function(PostgresChangePayload) onInsert) {
    final uid = _userId!;
    final channel = _client
        .channel('social_notifications_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'social_notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: (payload) => onInsert(payload),
        )
        .subscribe();
    return channel;
  }
}
