import 'profile.dart';
import '../core/utils/milestones.dart';
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
  final DateTime createdAt;
  final DateTime? readAt;
  final FriendUser? actor;

  const SocialNotification({
    required this.id,
    required this.actorId,
    this.type = 'workout_completed',
    this.referenceId,
    required this.message,
    required this.createdAt,
    this.readAt,
    this.actor,
  });

  bool get isUnread => readAt == null;
  bool get isRoutineShare => type == 'routine_share';

  factory SocialNotification.fromJson(Map<String, dynamic> json) {
    return SocialNotification(
      id: json['id'] as String,
      actorId: json['actor_id'] as String,
      type: json['type'] as String? ?? 'workout_completed',
      referenceId: json['reference_id'] as String?,
      message: json['message'] as String,
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
  final String message;

  const SocialRealtimeEvent({
    required this.notificationId,
    required this.actorId,
    required this.message,
  });

  factory SocialRealtimeEvent.fromRecord(Map<String, dynamic> record) {
    return SocialRealtimeEvent(
      notificationId: record['id'] as String,
      actorId: record['actor_id'] as String? ?? '',
      message: record['message'] as String? ?? '',
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
