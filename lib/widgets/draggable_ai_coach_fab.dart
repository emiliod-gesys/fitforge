import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';
import '../core/theme/app_accent.dart';

/// FAB del AI Coach arrastrable. Debe ser hijo directo de un [Stack].
class DraggableAiCoachFab extends StatefulWidget {
  const DraggableAiCoachFab({
    super.key,
    required this.areaSize,
  });

  /// Área disponible sobre la que se puede mover el botón (body del shell).
  final Size areaSize;

  static const _prefsNormX = 'ai_coach_fab_norm_x';
  static const _prefsNormY = 'ai_coach_fab_norm_y';
  static const _tapSlop = 12.0;
  static const _fabEstimate = Size(132, 48);

  @override
  State<DraggableAiCoachFab> createState() => _DraggableAiCoachFabState();
}

class _DraggableAiCoachFabState extends State<DraggableAiCoachFab> {
  final _fabKey = GlobalKey();
  Offset? _position;
  double? _normX;
  double? _normY;
  double _dragAccum = 0;

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  Future<void> _loadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble(DraggableAiCoachFab._prefsNormX);
    final y = prefs.getDouble(DraggableAiCoachFab._prefsNormY);
    if (!mounted) return;
    if (x != null && y != null) {
      setState(() {
        _normX = x.clamp(0.0, 1.0);
        _normY = y.clamp(0.0, 1.0);
      });
    }
  }

  Future<void> _saveNormalized(Offset norm) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(DraggableAiCoachFab._prefsNormX, norm.dx);
    await prefs.setDouble(DraggableAiCoachFab._prefsNormY, norm.dy);
  }

  void _openCoach() => context.push('/ai-coach');

  Size _fabSize() {
    final box = _fabKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.hasSize) return box.size;
    return DraggableAiCoachFab._fabEstimate;
  }

  _FabBounds _bounds(MediaQueryData media) {
    const edge = 16.0;
    final topInset = media.padding.top + edge;
    final bottomInset = media.padding.bottom + 68 + edge;
    final fab = _fabSize();
    final w = widget.areaSize.width;
    final h = widget.areaSize.height;

    final maxX = (w - fab.width - edge).clamp(edge, w);
    final maxY = (h - fab.height - bottomInset).clamp(topInset, h);

    return _FabBounds(edge: edge, topInset: topInset, maxX: maxX, maxY: maxY);
  }

  Offset _resolvePosition(_FabBounds bounds) {
    final defaultPos = Offset(bounds.maxX, bounds.maxY);
    if (_position != null) return _clamp(_position!, bounds);
    if (_normX != null && _normY != null) {
      return _clamp(
        Offset(
          bounds.edge + _normX! * (bounds.maxX - bounds.edge),
          bounds.topInset + _normY! * (bounds.maxY - bounds.topInset),
        ),
        bounds,
      );
    }
    return defaultPos;
  }

  Offset _clamp(Offset pos, _FabBounds bounds) {
    return Offset(
      pos.dx.clamp(bounds.edge, bounds.maxX),
      pos.dy.clamp(bounds.topInset, bounds.maxY),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final media = MediaQuery.of(context);
    final bounds = _bounds(media);
    final pos = _resolvePosition(bounds);

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onPanStart: (_) => _dragAccum = 0,
        onPanUpdate: (details) {
          _dragAccum += details.delta.distance;
          final current = _position ?? pos;
          setState(() {
            _position = _clamp(
              Offset(current.dx + details.delta.dx, current.dy + details.delta.dy),
              bounds,
            );
            _normX = null;
            _normY = null;
          });
        },
        onPanEnd: (_) {
          final current = _position ?? pos;
          if (_dragAccum < DraggableAiCoachFab._tapSlop) {
            _openCoach();
            return;
          }
          final norm = Offset(
            bounds.maxX > bounds.edge
                ? (current.dx - bounds.edge) / (bounds.maxX - bounds.edge)
                : 0,
            bounds.maxY > bounds.topInset
                ? (current.dy - bounds.topInset) / (bounds.maxY - bounds.topInset)
                : 0,
          );
          _saveNormalized(norm);
        },
        child: Material(
          key: _fabKey,
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          color: context.accentColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_outlined, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  l10n.coachAi,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FabBounds {
  final double edge;
  final double topInset;
  final double maxX;
  final double maxY;

  const _FabBounds({
    required this.edge,
    required this.topInset,
    required this.maxX,
    required this.maxY,
  });
}
