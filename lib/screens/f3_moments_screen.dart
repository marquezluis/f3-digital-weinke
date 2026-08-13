// lib/screens/f3_moments_screen.dart
// "F3 Moments" — a single chronological timeline of every Pic-o-Rama photo
// across every AO, newest first. Previously photos only lived scattered
// across each AO's own photo wall (browse_aos_screen.dart's _AoPhotoWall) —
// no single place to look back at the whole run of them.
//
// Deliberately photos-only, not the full "photos/achievements/chat" the
// original audit item envisioned: achievements have no persisted unlock
// timestamp (AchievementService.compute() derives current state fresh each
// time, nothing records *when* a badge first unlocked), and local chat
// messages are all self-authored (no relay yet — see chat_service.dart),
// so neither has an honest date to place on a timeline yet.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import 'history_screen.dart';

class F3MomentsScreen extends StatelessWidget {
  const F3MomentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryService>();
    final withPhotos = history.all
        .where((h) => h.photoPaths.isNotEmpty)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: const Text('F3 Moments'),
        backgroundColor: context.f3bg,
      ),
      body: withPhotos.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library_outlined,
                        color: context.f3textMuted, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'Photos from your saved beatdowns show up here — add one next time you save a session.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.f3textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: withPhotos.length,
              itemBuilder: (_, i) {
                final entry = withPhotos[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BackblastScreen(entry: entry)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.file(
                              File(entry.photoPaths.first),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: context.f3elevated,
                                alignment: Alignment.center,
                                child: Icon(Icons.broken_image_rounded,
                                    color: context.f3textMuted),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(entry.ao,
                            style: TextStyle(
                                color: context.f3textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                        Text(
                          shortMonthDayYear(entry.date,
                              Localizations.localeOf(context).languageCode),
                          style:
                              TextStyle(color: context.f3textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
