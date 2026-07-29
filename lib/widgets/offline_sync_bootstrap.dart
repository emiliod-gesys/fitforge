import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../services/supabase_service.dart';

/// Inicializa conectividad, sincroniza la cola offline y precarga datos locales al arrancar.
class OfflineSyncBootstrap extends ConsumerStatefulWidget {
  final Widget child;

  const OfflineSyncBootstrap({super.key, required this.child});

  @override
  ConsumerState<OfflineSyncBootstrap> createState() => _OfflineSyncBootstrapState();
}

class _OfflineSyncBootstrapState extends ConsumerState<OfflineSyncBootstrap> {
  StreamSubscription<bool>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _prefetchOfflineData() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      await ref.read(offlinePrepServiceProvider).prepare(userId: userId);
      await ref.read(exerciseServiceProvider).warmCloudExerciseCache();
    } catch (_) {
      // La caché local se usa en el siguiente intento offline.
    }
  }

  Future<void> _bootstrap() async {
    final connectivity = ref.read(connectivityServiceProvider);
    await connectivity.initialize();
    await ref.read(cloudExerciseCacheStoreProvider).ensureLoaded();
    await ref.read(exerciseServiceProvider).warmCloudExerciseCache();

    _subscription = connectivity.onConnectivityChanged.listen((online) {
      if (online && SupabaseService.currentUser != null) {
        unawaited(ref.read(workoutSyncServiceProvider).syncPending());
        unawaited(_prefetchOfflineData());
        ref.invalidate(pendingSyncCountProvider);
        ref.invalidate(profileProvider);
        ref.invalidate(routinesProvider);
      }
    });

    if (connectivity.isOnline && SupabaseService.currentUser != null) {
      await ref.read(workoutSyncServiceProvider).syncPending();
      ref.invalidate(pendingSyncCountProvider);
      unawaited(_prefetchOfflineData());
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
