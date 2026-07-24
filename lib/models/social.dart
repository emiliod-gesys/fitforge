import 'profile.dart';
import '../core/utils/milestones.dart';
import '../core/constants/social_feed.dart';
import '../core/utils/feed_personal_record.dart';
import '../core/utils/player_level.dart';
import '../core/utils/workout_streak.dart';

enum FriendshipStatus { pending, accepted }

class FriendUser {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String? email;
  final int totalXp;

  const FriendUser({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.email,
    this.totalXp = 0,
  });

  String get label => displayName ?? email?.split('@').first ?? 'Usuario';

  int get level => PlayerLevelCalculator.fromTotalXp(totalXp).level;

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    return FriendUser(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
    );
  }
}

class Friendship {
  final String id;
  final String requesterId;
  final String addresseeId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final FriendUser? requester;
  final FriendUser? addressee;

  const Friendship({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
    this.requester,
    this.addressee,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      addresseeId: json['addressee_id'] as String,
      status: (json['status'] as String) == 'accepted'
          ? FriendshipStatus.accepted
          : FriendshipStatus.pending,
      createdAt: DateTime.parse(json['created_at'] as String),
      requester: json['requester'] != null
          ? FriendUser.fromJson(Map<String, dynamic>.from(json['requester'] as Map))
          : null,
      addressee: json['addressee'] != null
          ? FriendUser.fromJson(Map<String, dynamic>.from(json['addressee'] as Map))
          : null,
    );
  }

  FriendUser friendFor(String currentUserId) {
    if (requesterId == currentUserId) {
      return addressee ?? FriendUser(id: addresseeId);
    }
    return requester ?? FriendUser(id: requesterId);
  }

  bool isIncoming(String currentUserId) =>
      status == FriendshipStatus.pending && addresseeId == currentUserId;
}

class SocialNotification {
  final String id;
  final String actorId;
  final String type;
  final String? referenceId;
  final String message;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? readAt;
  final FriendUser? actor;

  const SocialNotification({
    required this.id,
    required this.actorId,
    this.type = 'workout_completed',
    this.referenceId,
    required this.message,
    this.metadata,
    required this.createdAt,
    this.readAt,
    this.actor,
  });

  bool get isUnread => readAt == null;
  bool get isRoutineShare => type == 'routine_share';
  bool get isTrainerRequest => type == 'trainer_request';
  bool get isFriendRequest => type == 'friend_request';
  bool get isFeedComment => type == 'feed_comment';
  bool get isFeedReaction => type == 'feed_reaction';
  bool get isFeedCommentReaction => type == 'feed_comment_reaction';
  bool get isWorkoutCompleted => type == 'workout_completed';
  bool get isMilestoneUnlock => type == 'milestone_unlocked';
  bool get isLevelUp => type == 'level_up';
  bool get isPrUnlock => type == 'pr_unlocked';
  bool get isUserPost => type == 'user_post';

  bool get isFeedItem =>
      isWorkoutCompleted || isMilestoneUnlock || isLevelUp || isPrUnlock || isUserPost;

  bool get isBellItem => SocialFeed.bellTypes.contains(type);

  static const feedTypes = SocialFeed.feedTypes;
  static const bellTypes = SocialFeed.bellTypes;

  bool isOwnPost(String? currentUserId) =>
      currentUserId != null && currentUserId.isNotEmpty && actorId == currentUserId;

  String? get feedWorkoutName => metadata?['workout_name'] as String?;

  PersonalRecord? get feedPersonalRecord {
    if (isUserPost) return feedAttachedPersonalRecord;
    return FeedPersonalRecord.fromMetadata(metadata);
  }

  PersonalRecord? get feedAttachedPersonalRecord {
    final prRaw = metadata?['pr'];
    if (prRaw is Map) {
      return FeedPersonalRecord.fromMetadata(Map<String, dynamic>.from(prRaw));
    }
    return FeedPersonalRecord.fromMetadata(metadata);
  }

  String? get feedPostText {
    final fromMeta = metadata?['text'] as String?;
    if (fromMeta != null && fromMeta.trim().isNotEmpty) return fromMeta.trim();
    if (isUserPost && message.trim().isNotEmpty) return message.trim();
    return null;
  }

  String? get feedImagePath => metadata?['image_path'] as String?;

  String? get feedPostId => metadata?['post_id'] as String?;

  String? get bellPostId {
    final fromMeta = metadata?['post_id'] as String?;
    if (fromMeta != null && fromMeta.isNotEmpty) return fromMeta;
    if (referenceId != null && referenceId!.isNotEmpty) return referenceId;
    return null;
  }

  MilestoneCategory? get milestoneCategory {
    final raw = metadata?['category'] as String?;
    if (raw == null) return null;
    for (final category in MilestoneCategory.values) {
      if (category.name == raw) return category;
    }
    return null;
  }

  int? get milestoneTier => (metadata?['tier'] as num?)?.toInt();

  int? get levelReached => (metadata?['level'] as num?)?.toInt();

  factory SocialNotification.fromJson(Map<String, dynamic> json) {
    final metadataRaw = json['metadata'];
    Map<String, dynamic>? metadata;
    if (metadataRaw is Map) {
      metadata = Map<String, dynamic>.from(metadataRaw);
    }

    return SocialNotification(
      id: json['id'] as String,
      actorId: json['actor_id'] as String,
      type: json['type'] as String? ?? 'workout_completed',
      referenceId: json['reference_id'] as String?,
      message: json['message'] as String,
      metadata: metadata,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      actor: json['actor'] != null
          ? FriendUser.fromJson(Map<String, dynamic>.from(json['actor'] as Map))
          : null,
    );
  }
}

/// Evento en tiempo real al insertar una fila en social_notifications.
class SocialRealtimeEvent {
  final String notificationId;
  final String actorId;
  final String type;
  final String message;
  final Map<String, dynamic>? metadata;

  const SocialRealtimeEvent({
    required this.notificationId,
    required this.actorId,
    required this.type,
    required this.message,
    this.metadata,
  });

  bool get isFeedItem => SocialNotification.feedTypes.contains(type);

  bool get isBellItem => SocialNotification.bellTypes.contains(type);

  factory SocialRealtimeEvent.fromRecord(Map<String, dynamic> record) {
    final metadataRaw = record['metadata'];
    Map<String, dynamic>? metadata;
    if (metadataRaw is Map) {
      metadata = Map<String, dynamic>.from(metadataRaw);
    }

    return SocialRealtimeEvent(
      notificationId: record['id'] as String,
      actorId: record['actor_id'] as String? ?? '',
      type: record['type'] as String? ?? 'workout_completed',
      message: record['message'] as String? ?? '',
      metadata: metadata,
    );
  }
}

class FriendProfileView {
  final FriendUser user;
  final UserProfile profile;
  final List<PersonalRecord> personalRecords;
  final WorkoutWeeklyStats weeklyStats;
  final MilestoneTotals milestoneTotals;

  const FriendProfileView({
    required this.user,
    required this.profile,
    required this.personalRecords,
    required this.weeklyStats,
    required this.milestoneTotals,
  });
}
