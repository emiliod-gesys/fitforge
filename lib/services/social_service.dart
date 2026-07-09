import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/feed_reactions.dart';
import '../core/constants/social_feed.dart';
import '../core/utils/feed_personal_record.dart';
import '../core/utils/milestones.dart';
import '../core/utils/player_level.dart';
import '../core/utils/supabase_datetime.dart';
import '../core/utils/workout_streak.dart';
import '../models/feed_reaction.dart';
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

  Future<Set<String>> getMutedFriendIds() async {
    final uid = _userId;
    if (uid == null) return {};

    final data = await _client
        .from('friend_mutes')
        .select('muted_user_id')
        .eq('user_id', uid);

    return (data as List)
        .map((row) => (row as Map)['muted_user_id'] as String)
        .toSet();
  }

  Future<void> setFriendMuted(String friendId, bool muted) async {
    final uid = _userId;
    if (uid == null) return;

    if (muted) {
      await _client.from('friend_mutes').upsert({
        'user_id': uid,
        'muted_user_id': friendId,
      });
    } else {
      await _client.from('friend_mutes').delete().match({
        'user_id': uid,
        'muted_user_id': friendId,
      });
    }
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
        .not('type', 'in', _feedTypes)
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
            type: n.type,
            referenceId: n.referenceId,
            message: n.message,
            metadata: n.metadata,
            createdAt: n.createdAt,
            readAt: n.readAt,
            actor: actors[n.actorId],
          ),
        )
        .toList();
  }

  static const _feedTypes = SocialFeed.feedTypes;

  Future<List<SocialNotification>> getFeed({int limit = 50}) async {
    final uid = _userId;
    if (uid == null) return [];

    final cutoff = SocialFeed.cutoffSince().toIso8601String();

    final data = await _client
        .from('social_notifications')
        .select()
        .eq('user_id', uid)
        .inFilter('type', _feedTypes)
        .gte('created_at', cutoff)
        .order('created_at', ascending: false)
        .limit(limit);

    final rows = (data as List)
        .map((r) => SocialNotification.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();

    final actorIds = rows.map((n) => n.actorId).toSet().toList();
    if (actorIds.isEmpty) return rows;

    final actorsData = await _client
        .from('profiles')
        .select('id, display_name, avatar_url, email, total_xp')
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
            type: n.type,
            referenceId: n.referenceId,
            message: n.message,
            metadata: n.metadata,
            createdAt: n.createdAt,
            readAt: n.readAt,
            actor: actors[n.actorId],
          ),
        )
        .toList();
  }

  Future<List<FeedPost>> getFeedWithReactions({int limit = 50}) async {
    final notifications = await getFeed(limit: limit);
    if (notifications.isEmpty) return [];

    final reactions = await getFeedReactions(notifications.map((n) => n.id).toList());
    return notifications
        .map(
          (n) => FeedPost(
            notification: n,
            reactions: reactions[n.id] ?? FeedReactionSummary.empty,
          ),
        )
        .toList();
  }

  Future<Map<String, FeedReactionSummary>> getFeedReactions(List<String> notificationIds) async {
    if (_userId == null || notificationIds.isEmpty) return {};

    final data = await _client
        .from('feed_reactions')
        .select('notification_id, user_id, emoji')
        .inFilter('notification_id', notificationIds);

    final rows = (data as List)
        .map((r) => FeedReactionRow.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();

    return FeedReactionSummary.aggregate(rows, currentUserId: _userId);
  }

  Future<void> toggleFeedReaction({
    required String notificationId,
    required String emoji,
  }) async {
    final uid = _userId;
    if (uid == null) return;
    if (!FeedReactions.isAllowed(emoji)) return;

    final existing = await _client
        .from('feed_reactions')
        .select('id, emoji')
        .eq('notification_id', notificationId)
        .eq('user_id', uid)
        .maybeSingle();

    if (existing != null) {
      final currentEmoji = existing['emoji'] as String;
      if (currentEmoji == emoji) {
        await _client.from('feed_reactions').delete().eq('id', existing['id'] as String);
      } else {
        await _client
            .from('feed_reactions')
            .update({'emoji': emoji})
            .eq('id', existing['id'] as String);
      }
      return;
    }

    await _client.from('feed_reactions').insert({
      'notification_id': notificationId,
      'user_id': uid,
      'emoji': emoji,
    });
  }

  Future<void> publishMilestoneUnlock(MilestoneUnlock unlock) async {
    if (_userId == null) return;

    await _client.rpc('notify_friends_feed_event', params: {
      'p_type': 'milestone_unlocked',
      'p_message': 'milestone:${unlock.category.name}:${unlock.tier}',
      'p_metadata': {
        'category': unlock.category.name,
        'tier': unlock.tier,
      },
    });
  }

  Future<void> publishLevelUp(int level) async {
    if (_userId == null) return;

    await _client.rpc('notify_friends_feed_event', params: {
      'p_type': 'level_up',
      'p_message': 'level:$level',
      'p_metadata': {'level': level},
    });
  }

  Future<void> publishPersonalRecord(PersonalRecord record) async {
    final uid = _userId;
    if (uid == null) {
      throw StateError('not_authenticated');
    }

    final metadata = FeedPersonalRecord.toMetadata(record);
    await _client.rpc('notify_friends_feed_event', params: {
      'p_type': 'pr_unlocked',
      'p_message': 'pr:${record.exerciseId}:${record.recordType.toJson()}',
      'p_metadata': metadata,
    });
  }

  Future<int> publishPersonalRecords(List<PersonalRecord> records) async {
    if (records.isEmpty) return 0;
    for (final record in records) {
      await publishPersonalRecord(record);
    }
    return records.length;
  }

  Future<void> publishPostWorkoutFeedEvents({
    required List<MilestoneUnlock> newMilestones,
    XpAwardResult? xpAward,
  }) async {
    for (final unlock in newMilestones) {
      await publishMilestoneUnlock(unlock);
    }

    if (xpAward != null && xpAward.leveledUp) {
      for (var level = xpAward.before.level + 1; level <= xpAward.after.level; level++) {
        await publishLevelUp(level);
      }
    }
  }

  Future<int> getUnreadCount() async {
    final uid = _userId;
    if (uid == null) return 0;

    final data = await _client
        .from('social_notifications')
        .select('id')
        .eq('user_id', uid)
        .not('type', 'in', _feedTypes)
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
