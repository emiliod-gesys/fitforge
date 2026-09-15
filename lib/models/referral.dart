import '../core/utils/json_parsing.dart';

class ReferralEntry {
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final bool isActive;

  const ReferralEntry({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    required this.isActive,
  });

  factory ReferralEntry.fromJson(Map<String, dynamic> json) {
    return ReferralEntry(
      userId: parseJsonString(json['user_id']) ?? '',
      displayName: parseJsonString(json['display_name']),
      avatarUrl: parseJsonString(json['avatar_url']),
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: parseJsonBool(json['is_active']),
    );
  }
}

enum ApplyReferralResult {
  ok,
  invalid,
  notFound,
  self,
  unauthenticated,
  error,
}

class ApplyReferralOutcome {
  final ApplyReferralResult result;
  final bool already;

  const ApplyReferralOutcome(this.result, {this.already = false});

  bool get succeeded => result == ApplyReferralResult.ok || already;
}
