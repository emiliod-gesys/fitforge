import '../core/referrals/referral_rules.dart';
import '../models/referral.dart';
import 'supabase_service.dart';

class ReferralService {
  final _client = SupabaseService.client;

  Future<ApplyReferralOutcome> applyCode(String raw) async {
    final code = ReferralCode.normalize(raw);
    if (code.isEmpty) {
      return const ApplyReferralOutcome(ApplyReferralResult.ok);
    }
    if (!ReferralCode.isValid(code)) {
      return const ApplyReferralOutcome(ApplyReferralResult.invalid);
    }

    try {
      final data = await _client.rpc(
        'apply_referral_code',
        params: {'p_code': code},
      );
      if (data is! Map) {
        return const ApplyReferralOutcome(ApplyReferralResult.error);
      }
      final map = Map<String, dynamic>.from(data);
      if (map['ok'] == true) {
        return ApplyReferralOutcome(
          ApplyReferralResult.ok,
          already: map['already'] == true,
        );
      }
      return ApplyReferralOutcome(_errorFrom(map['error']));
    } catch (_) {
      return const ApplyReferralOutcome(ApplyReferralResult.error);
    }
  }

  Future<List<ReferralEntry>> listMine() async {
    final data = await _client.rpc('list_my_referrals');
    if (data is! List) return const [];
    return [
      for (final row in data)
        if (row is Map) ReferralEntry.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  static ApplyReferralResult _errorFrom(Object? code) {
    return switch (code) {
      'invalid' => ApplyReferralResult.invalid,
      'not_found' => ApplyReferralResult.notFound,
      'self' => ApplyReferralResult.self,
      'unauthenticated' => ApplyReferralResult.unauthenticated,
      _ => ApplyReferralResult.error,
    };
  }
}
