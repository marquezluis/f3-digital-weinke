// lib/widgets/self_avatar.dart
// The signed-in PAX's own avatar: local photo → F3 Nation avatar URL →
// initial → shield. Shared by Home's header and Settings' profile card,
// which previously reimplemented this same fallback chain separately.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_profile_service.dart';
import '../theme/app_theme.dart';

class SelfAvatar extends StatelessWidget {
  final double size;
  const SelfAvatar({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProfileService>(
      builder: (context, profile, _) {
        final name = profile.displayName;
        final initial =
            name.isNotEmpty ? name.characters.first.toUpperCase() : '';
        ImageProvider? img;
        if (profile.localAvatarPath.isNotEmpty &&
            File(profile.localAvatarPath).existsSync()) {
          img = FileImage(File(profile.localAvatarPath));
        } else if (profile.avatarUrl.isNotEmpty) {
          img = NetworkImage(profile.avatarUrl);
        }
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: F3Colors.accent.withValues(alpha: 0.14),
            border: Border.all(
                color: F3Colors.accent.withValues(alpha: 0.5), width: 2),
            image: img != null
                ? DecorationImage(image: img, fit: BoxFit.cover)
                : null,
          ),
          alignment: Alignment.center,
          child: img != null
              ? null
              : (initial.isNotEmpty
                  ? Text(initial,
                      style: TextStyle(
                          color: F3Colors.accent,
                          fontWeight: FontWeight.w900,
                          fontSize: size * 0.42))
                  : Icon(Icons.shield_rounded,
                      color: F3Colors.accent, size: size * 0.5)),
        );
      },
    );
  }
}
