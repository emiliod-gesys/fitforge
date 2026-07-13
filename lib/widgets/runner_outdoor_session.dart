import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/runner/runner_standards.dart';
import '../core/runner/runner_models.dart';
import '../core/runner/runner_tracking.dart' as runner_math;
import '../core/theme/app_colors.dart';
import '../core/utils/cardio_format.dart';
import '../l10n/l10n_extensions.dart';
import '../services/runner_tracking_service.dart';

class RunnerOutdoorSession extends StatefulWidget {
  final String workoutId;
  final String unitSystem;
  final RunningSurface? surface;
  final VoidCallback onCancel;
  final Future<void> Function(RunnerTrackingSnapshot snapshot) onFinish;

  const RunnerOutdoorSession({
    super.key,
    required this.workoutId,
    required this.unitSystem,
    this.surface,
    required this.onCancel,
    required this.onFinish,
  });

  @override
  State<RunnerOutdoorSession> createState() => _RunnerOutdoorSessionState();
}

class _RunnerOutdoorSessionState extends State<RunnerOutdoorSession> {
  final _tracking = RunnerTrackingService();
  final _mapController = MapController();
  RunnerTrackingSnapshot? _snapshot;
  bool _starting = true;
  bool _finishing = false;
  String? _gpsError;
  Timer? _uiTimer;
  DateTime? _frozenAt;

  @override
  void initState() {
    super.initState();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _finishing) return;
      if (_snapshot != null) setState(() {});
    });
    unawaited(_initTracking());
  }

  Future<void> _initTracking() async {
    final ok = await _tracking.ensurePermissions();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _gpsError = context.l10n.runnerGpsDenied;
        _starting = false;
      });
      return;
    }
    await _tracking.start(workoutId: widget.workoutId, surface: widget.surface);
    _tracking.stream.listen((snap) {
      if (!mounted || _finishing) return;
      setState(() => _snapshot = snap);
      if (snap.route.isNotEmpty) {
        final last = snap.route.last;
        _mapController.move(LatLng(last.lat, last.lng), _mapController.camera.zoom);
      }
    });
    if (mounted) setState(() => _starting = false);
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _tracking.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _uiTimer?.cancel();
    await _tracking.pause();
    final frozenAt = DateTime.now();
    setState(() {
      _finishing = true;
      _frozenAt = frozenAt;
    });

    final snap = await _tracking.stop();
    if (snap == null || snap.distanceMeters <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.runnerNoDistance)),
        );
        setState(() {
          _finishing = false;
          _frozenAt = null;
        });
        _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted || _finishing) return;
          if (_snapshot != null) setState(() {});
        });
        await _tracking.resume();
      }
      return;
    }
    await widget.onFinish(snap);
  }

  DateTime get _displayNow => _frozenAt ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final snap = _snapshot;
    final now = _displayNow;
    final elapsed = snap?.elapsedSeconds(now) ?? 0;
    final distance = snap?.distanceMeters ?? 0;
    final avgPace = snap?.avgPaceSecPerKm(now);
    final currentPace = runner_math.RunnerTracking.paceSecPerKm(
      distanceMeters: distance,
      elapsedSeconds: elapsed,
    );

    if (_gpsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_gpsError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: widget.onCancel, child: Text(l10n.cancel)),
            ],
          ),
        ),
      );
    }

    if (_starting) {
      return Center(child: Text(l10n.runnerAcquiringGps));
    }

    final points = snap?.route ?? const [];
    final latLngs = points.map((p) => LatLng(p.lat, p.lng)).toList();
    final center = latLngs.isNotEmpty ? latLngs.last : const LatLng(19.4326, -99.1332);

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: latLngs.isEmpty ? 15 : 16,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fitforge.app',
              ),
              if (latLngs.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: latLngs,
                      strokeWidth: 4,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              if (latLngs.isNotEmpty)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: latLngs.last,
                      width: 16,
                      height: 16,
                      child: Icon(
                        Icons.circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Metric(label: l10n.runnerTime, value: CardioFormat.duration(elapsed)),
                  _Metric(
                    label: l10n.runnerDistance,
                    value: CardioFormat.distance(distance, widget.unitSystem),
                  ),
                  _Metric(
                    label: l10n.runnerPace,
                    value: CardioFormat.pace(currentPace ?? avgPace, widget.unitSystem),
                  ),
                ],
              ),
              if (snap != null &&
                  (snap.elevationGainMeters > 0 || snap.elevationLossMeters > 0)) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.terrain, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      l10n.runnerElevationLabel,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CardioFormat.elevationGainLoss(
                        gainMeters: snap.elevationGainMeters,
                        lossMeters: snap.elevationLossMeters,
                        unitSystem: widget.unitSystem,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (snap != null && snap.splits.isNotEmpty)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Text(l10n.runnerSplitsTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...snap.splits.map(
                  (s) => ListTile(
                    dense: true,
                    title: Text(l10n.runnerSplitKm(s.km)),
                    trailing: Text(CardioFormat.duration(s.seconds)),
                  ),
                ),
              ],
            ),
          )
        else
          const Spacer(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _finishing
                      ? null
                      : () async {
                          if (_tracking.status == RunnerTrackingStatus.paused) {
                            await _tracking.resume();
                          } else {
                            await _tracking.pause();
                          }
                          if (mounted) setState(() {});
                        },
                  child: Text(
                    _tracking.status == RunnerTrackingStatus.paused
                        ? l10n.runnerResume
                        : l10n.runnerPause,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _finishing ? null : _finish,
                  child: Text(_finishing ? l10n.finish : l10n.runnerFinish),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
      ],
    );
  }
}
