// lib/widgets/intensity_badge.dart
import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';

class IntensityBadge extends StatelessWidget {
  final Intensity intensity;
  final bool small;

  const IntensityBadge({super.key, required this.intensity, this.small = false});

  @override
  Widget build(BuildContext context) {
    final color = F3Colors.forIntensity(intensity.name);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 5 : 7, vertical: small ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        intensity.label,
        style: TextStyle(
          color: color,
          fontSize: small ? 9 : 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
