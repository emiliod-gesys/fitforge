import 'package:flutter/material.dart';
import 'package:flutter_body_heatmap/flutter_body_heatmap.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/profile.dart';
import 'body_mannequin_mapper.dart';

/// Maniquí anatómico con músculos coloreados según fatiga (tonos rojos).
class BodyMannequin extends StatefulWidget {
  final Map<String, double> recovery;
  final Gender? gender;

  const BodyMannequin({
    super.key,
    required this.recovery,
    this.gender,
  });

  @override
  State<BodyMannequin> createState() => _BodyMannequinState();
}

class _BodyMannequinState extends State<BodyMannequin> {
  bool _showBack = false;

  bool get _isFemale => widget.gender == Gender.female;

  static const _fatigueColors = [
    Color(0xFF5C3A42),
    Color(0xFF8B4555),
    Color(0xFFC23B4A),
    Color(0xFFE82E45),
  ];

  void _toggleView() => setState(() => _showBack = !_showBack);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final heatmapData = BodyMannequinMapper.toHeatmapData(widget.recovery);

    return AspectRatio(
      aspectRatio: 0.50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final rotate = Tween(begin: 0.5, end: 0.0).animate(animation);
              return AnimatedBuilder(
                animation: rotate,
                child: child,
                builder: (_, child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(rotate.value * 3.14159),
                    child: child,
                  );
                },
              );
            },
            child: BodyHeatmap(
              key: ValueKey('${_showBack}_$_isFemale'),
              side: _showBack ? BodySide.back : BodySide.front,
              gender: _isFemale ? BodyGender.female : BodyGender.male,
              data: heatmapData,
              colors: _fatigueColors,
              bodyColor: const Color(0xFF343A42),
              borderColor: const Color(0xFF252A30),
              showBorder: true,
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Material(
              color: AppColors.cardElevated.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: _toggleView,
                borderRadius: BorderRadius.circular(24),
                child: Tooltip(
                  message: l10n.rotateBody,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.rotate_90_degrees_ccw,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Text(
              _showBack ? l10n.bodyBack : l10n.bodyFront,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
