// lib/widgets/category_chip.dart
import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';

class CategoryChip extends StatelessWidget {
  final ExerciseCategory category;
  final bool small;

  const CategoryChip({super.key, required this.category, this.small = false});

  @override
  Widget build(BuildContext context) {
    final color = F3Colors.forCategory(category.name);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 7 : 10, vertical: small ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        category.shortName,
        style: TextStyle(
          color: color,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
