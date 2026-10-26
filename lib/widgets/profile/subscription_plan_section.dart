import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../subscription/plan_upgrade_sheet.dart';

class SubscriptionPlanSection extends StatelessWidget {
  final UserProfile? profile;

  const SubscriptionPlanSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return PlanOfferBody(fallbackProfile: profile);
  }
}
