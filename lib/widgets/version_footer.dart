// lib/widgets/version_footer.dart
// A tappable footer widget displaying the app version and creator.
// Tapping it opens a detailed release log and contact info.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/app_version.dart';

class VersionFooter extends StatelessWidget {
  const VersionFooter({super.key});

  void _showReleaseLog(BuildContext context) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: F3Colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Column(
          children: [
            Icon(Icons.history_edu_rounded, color: F3Colors.accent, size: 32),
            SizedBox(height: 8),
            Text('Release Log',
                style: TextStyle(
                    color: F3Colors.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: AppVersion.changelog.length + 1, // +1 for Contact block
            itemBuilder: (context, index) {
              if (index == AppVersion.changelog.length) {
                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: F3Colors.elevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: F3Colors.divider),
                  ),
                  child: const Column(
                    children: [
                      Text('Created by: PermVac',
                          style: TextStyle(
                              color: F3Colors.textPrimary,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Contact via Slack: @PermVac (F3 Nation)',
                          style: TextStyle(
                              color: F3Colors.textSecondary, fontSize: 12)),
                    ],
                  ),
                );
              }

              final release = AppVersion.changelog[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'v${release['version']} - ${release['title']}',
                      style: const TextStyle(
                          color: F3Colors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    ...List<Widget>.from((release['changes'] as List<String>)
                        .map((change) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ',
                                      style:
                                          TextStyle(color: F3Colors.textMuted)),
                                  Expanded(
                                      child: Text(change,
                                          style: const TextStyle(
                                              color: F3Colors.textSecondary,
                                              fontSize: 13,
                                              height: 1.3))),
                                ],
                              ),
                            ))),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('DISMISS',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showReleaseLog(context),
      behavior: HitTestBehavior.opaque,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Digital Weinke v${AppVersion.current}',
              style: TextStyle(
                color: F3Colors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Created by: PermVac',
              style: TextStyle(
                color: F3Colors.textMuted,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Contact via Slack: @PermVac (F3 Nation)',
              style: TextStyle(
                color: F3Colors.textMuted,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}