import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/fitforge_loading_indicator.dart';

/// GoRouter infers map literals as `Map<String, Object>`, and `extra` is
/// dropped when the router refreshes (auth/profile/connectivity).
Map<String, dynamic>? foodRouteExtraMap(Object? extra) {
  if (extra is Map<String, dynamic>) return extra;
  if (extra is Map) return Map<String, dynamic>.from(extra);
  return null;
}

/// Avoids a blank/error screen when add/detail extras are lost.
class FoodRouteFallbackScreen extends StatefulWidget {
  const FoodRouteFallbackScreen({super.key});

  @override
  State<FoodRouteFallbackScreen> createState() => _FoodRouteFallbackScreenState();
}

class _FoodRouteFallbackScreenState extends State<FoodRouteFallbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go('/food');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: FitForgeLoadingScreen(),
    );
  }
}
