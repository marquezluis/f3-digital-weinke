// lib/screens/home_screen.dart
// Digital Weinke — home dashboard.
// Branding: F3 "Badass Black" + red-orange accent.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';
import '../models/exercise.dart';
import '../models/workout_history.dart';
import '../models/workout_plan.dart';
import '../models/workout_settings.dart';
import '../services/app_profile_service.dart' hide AppRole;
import '../services/current_workout_service.dart';
import '../services/exercise_service.dart';
import '../services/history_service.dart';
import '../services/notification_service.dart';
import '../utils/greeting.dart';
import '../services/settings_service.dart';
import '../services/f3_api_service.dart';
import '../models/f3_api_models.dart';
import 'schedule_screen.dart' show MineFilter;
import '../widgets/exercise_detail_sheet.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'workout_screen.dart';
import 'qsource_screen.dart';
import 'browse_aos_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsSvc = context.watch<SettingsService>();
    final myF3Name = settingsSvc.myF3Name;
    final now = DateTime.now();
    final isGloom = now.hour < 9;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.f3bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Hero header ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand wordmark
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: 'DIGITAL ',
                          style: TextStyle(
                              color: context.f3textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              height: 1),
                        ),
                        const TextSpan(
                          text: 'WEINKE',
                          style: TextStyle(
                              color: F3Colors.accent,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              height: 1),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    // Welcome card — the personal hello, front and center.
                    Builder(builder: (context) {
                      final profileName =
                          context.watch<AppProfileService>().displayName;
                      final region =
                          context.watch<AppProfileService>().region;
                      final name =
                          myF3Name.isNotEmpty ? myF3Name : profileName;
                      final greeting =
                          greetingFor(AppLocalizations.of(context)!, now);
                      return Material(
                        color: context.f3card,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: context.f3divider),
                            ),
                            child: Row(children: [
                              const _HomeAvatar(size: 68),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$greeting,',
                                        style: TextStyle(
                                            color: context.f3textSecondary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(name.isEmpty ? l10n.homeWelcomeFallback : name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: context.f3textPrimary,
                                            fontSize: 26,
                                            fontWeight: FontWeight.w900,
                                            height: 1.1)),
                                    const SizedBox(height: 4),
                                    Text(
                                        region.isNotEmpty
                                            ? '$region · ${_formatDate(now)}'
                                            : _formatDate(now),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: context.f3textMuted,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ]),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    Text(
                      // The rotating daily mottos (_dailyMotto) are
                      // deliberately left English-only for now — 25 short
                      // motivational lines is a large translation surface on
                      // its own, scoped out of this pass.
                      isGloom
                          ? l10n.homeSyitg
                          : _dailyMotto(now),
                      style: TextStyle(
                        color: context.f3textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Upcoming beatdowns (F3 Nation API) ───────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
              sliver: SliverToBoxAdapter(
                child: Consumer<F3ApiService>(
                  builder: (context, api, _) =>
                      api.isConfigured ? const _UpcomingBeatdownsSection() : const SizedBox.shrink(),
                ),
              ),
            ),

            // Home is a launchpad: the 50-min timeline preview and the Exicon
            // exercise-count stats moved off here — that content belongs on
            // the Plan/Exicon surfaces, not the daily home screen.

            // ── Insight cards ─────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Consumer2<HistoryService, ExerciseService>(
                  builder: (context, historySvc, exerciseSvc, _) {
                    final sessions = historySvc.all
                        .where((e) => e.completed && !e.isTemplate)
                        .toList();
                    final exercises = exerciseSvc.all;
                    final streak = _streakWeeks(sessions);
                    final featured = exercises.isEmpty
                        ? null
                        : exercises[_dayOfYear(DateTime.now()) % exercises.length];
                    return Column(children: [
                      if (sessions.isNotEmpty)
                        _LastBeatdownCard(session: sessions.first),
                      if (featured != null) ...[
                        const SizedBox(height: 8),
                        _FeaturedExerciseCard(exercise: featured),
                      ],
                      if (streak > 0) ...[
                        const SizedBox(height: 8),
                        _StreakCard(weeks: streak),
                      ],
                      if (sessions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _StatsCard(sessions: sessions),
                      ],
                    ]);
                  },
                ),
              ),
            ),

            // ── Quick start row ───────────────────────────────────────────
            SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Consumer2<HistoryService, CurrentWorkoutService>(
                    builder: (context, historySvc, workoutSvc, _) {
                      final lastSession = historySvc.all
                          .where((e) => e.completed && !e.isTemplate)
                          .firstOrNull;
                      return _QuickStartRow(
                        hasDraft: workoutSvc.hasDraftPlan,
                        lastSession: lastSession,
                        onResume: () => _openWeinke(context),
                        onRandom: () {
                          context.read<CurrentWorkoutService>().clearDraft();
                          _openWeinke(context);
                        },
                        onLoadLast: lastSession == null
                            ? null
                            : () => _loadLastSession(
                                context, lastSession),
                      );
                    },
                  ),
                ),
              ),

            // ── Current plan sneak-peek ───────────────────────────────────
            SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Consumer<CurrentWorkoutService>(
                    builder: (context, workoutSvc, _) {
                      final plan = workoutSvc.draftPlan;
                      if (plan == null || plan.allExercises.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final names = plan.allExercises
                          .take(4)
                          .map((e) => e.name)
                          .join(' · ');
                      final more = plan.allExercises.length > 4
                          ? ' +${plan.allExercises.length - 4} more'
                          : '';
                      return GestureDetector(
                        onTap: () => _openWeinke(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: context.f3elevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.f3divider),
                          ),
                          child: Row(children: [
                            const Icon(Icons.fitness_center_rounded,
                                size: 16, color: F3Colors.accent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.homeCurrentWeinke(plan.allExercises.length),
                                    style: const TextStyle(
                                        color: F3Colors.accent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$names$more',
                                    style: TextStyle(
                                        color: context.f3textSecondary,
                                        fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                size: 18, color: context.f3textMuted),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // ── Quick actions ─────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(l10n.homeQuickActions,
                          style: TextStyle(
                              color: context.f3textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5)),
                    ),
                    // Recent-exercises carousel moved to the Exicon library.
                    // Schedule has its own tab now, so no duplicate card here.
                    _QuickCard(
                      icon: Icons.bolt_rounded,
                      title: l10n.homeGenerateBeatdown,
                      subtitle: l10n.homeGenerateBeatdownSub,
                      color: F3Colors.accent,
                      onTap: () => _openWeinke(context),
                    ),
                    const SizedBox(height: 8),
                    _QuickCard(
                      icon: Icons.school_rounded,
                      title: l10n.homeQFieldGuide,
                      subtitle: l10n.homeQFieldGuideSub,
                      color: F3Colors.phaseCOT,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QSourceScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Consumer<HistoryService>(
                      builder: (context, svc, _) => _QuickCard(
                        icon: Icons.history_rounded,
                        title: l10n.homeBeatdownHistory,
                        subtitle: svc.all.isEmpty
                            ? l10n.homeBeatdownHistoryEmpty
                            : l10n.homeBeatdownHistorySub(svc.all.length),
                        color: F3Colors.phaseMary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HistoryScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _QuickCard(
                      icon: Icons.explore_rounded,
                      title: l10n.homeBrowseAos,
                      subtitle: l10n.homeBrowseAosSub,
                      color: const Color(0xFF2196F3),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BrowseAosScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── F3 Core Values ────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              sliver: SliverToBoxAdapter(child: _CoreValues()),
            ),
            // Version & credits live in the You tab (Settings → About) now,
            // not on the home launchpad.
          ],
        ),
      ),
    );
  }

  // Weinke builder is a pushed route now (lives under the Plan tab), so the
  // home shortcuts open it directly rather than switching tabs.
  void _openWeinke(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WorkoutScreen()),
    );
  }

  String _formatDate(DateTime dt) {
    const days = [
      'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
    ];
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }
}

// ─── Home insight helpers ─────────────────────────────────────────────────────

int _dayOfYear(DateTime d) =>
    d.difference(DateTime(d.year, 1, 1)).inDays;

const _mottos = [
  'Leave no man behind, but leave no man where you found him.',
  'Every man needs to struggle to find his purpose.',
  'Pain is the feeling of weakness leaving the body.',
  'Show up. Work hard. Encourage others.',
  'EH someone this week.',
  'You can always do more than you think you can.',
  'The Six doesn\'t win by staying at home.',
  'Plant your shovelflag and get after it.',
  'Fitness is the vehicle, fellowship is the destination.',
  'Hard things done together make us better men.',
  'Your hard is hard. My hard is hard. We just have different hards.',
  'F3: Fitness, Fellowship, Faith — one beatdown at a time.',
  'Get comfortable being uncomfortable.',
  'A man who leads himself can lead others.',
  'Iron sharpens iron.',
  'The only bad workout is the one you didn\'t do.',
  'We accelerate the growth of men.',
  'EH: Exhort, Harass, and Invite.',
  'The Q sets the tone. PAX set the standard.',
  'Mumble chatter is part of the beatdown.',
  'Nobody is coming to save you. Save yourself first, then go back for the Six.',
  'Strong enough to lead. Humble enough to follow.',
  'Your 0530 sets the tone for your entire day.',
  'Coffeeteria is earned.',
  'Plant yourself. Then grow.',
];

String _dailyMotto(DateTime d) =>
    _mottos[_dayOfYear(d) % _mottos.length];

int _streakWeeks(List<WorkoutHistory> sessions) {
  if (sessions.isEmpty) return 0;
  // Build set of "year-week" strings for every completed session.
  Set<String> weeksWithSession = {};
  for (final s in sessions) {
    weeksWithSession.add(_isoWeekKey(s.date));
  }
  // Walk backwards from the current week counting consecutive hits.
  var cursor = DateTime.now();
  int streak = 0;
  while (weeksWithSession.contains(_isoWeekKey(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 7));
  }
  return streak;
}

String _isoWeekKey(DateTime d) {
  // ISO week: Monday is day 1. Use Thursday's year to handle year boundaries.
  final thursday = d.add(Duration(days: 4 - (d.weekday)));
  final firstJan = DateTime(thursday.year, 1, 1);
  final week = ((thursday.difference(firstJan).inDays) ~/ 7) + 1;
  return '${thursday.year}-$week';
}

// ─── Quick action card ────────────────────────────────────────────────────────

// ─── Home avatar ──────────────────────────────────────────────────────────────

/// Circular profile avatar in the home header. Shows the F3 Nation avatar
/// when synced, else the user's initial, else a shield. Purely visual — the
/// whole welcome card it sits in (not just this avatar) opens the profile.
class _HomeAvatar extends StatelessWidget {
  final double size;
  const _HomeAvatar({this.size = 48});

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

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: context.f3card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.f3divider),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      color: context.f3textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              Text(subtitle,
                  style: TextStyle(
                      color: context.f3textSecondary, fontSize: 13)),
            ]),
          ),
          Icon(Icons.chevron_right_rounded,
              color: context.f3textMuted, size: 22),
        ]),
      ),
    );
  }
}

// ─── Last beatdown card ───────────────────────────────────────────────────────

class _LastBeatdownCard extends StatelessWidget {
  final WorkoutHistory session;
  const _LastBeatdownCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final exerciseCount =
        session.blocks.fold<int>(0, (sum, b) => sum + b.exerciseNames.length);
    final paxLabel = session.pax.isEmpty
        ? (session.fngCount > 0 ? '${session.fngCount} FNG' : '—')
        : '${session.pax.length + session.fngCount} PAX';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.f3divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(l10n.homeLastBeatdown,
              style: TextStyle(
                  color: context.f3textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          const Spacer(),
          Text(session.shortDate,
              style: TextStyle(
                  color: context.f3textSecondary, fontSize: 12)),
        ]),
        const SizedBox(height: 8),
        Text(
          session.title.isEmpty ? l10n.homeBeatdownFallback : session.title,
          style: TextStyle(
              color: context.f3textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 17),
        ),
        const SizedBox(height: 6),
        Row(children: [
          if (session.ao.isNotEmpty) ...[
            Icon(Icons.location_on_rounded,
                color: context.f3textMuted, size: 14),
            const SizedBox(width: 3),
            Text(session.ao,
                style: TextStyle(
                    color: context.f3textSecondary, fontSize: 13)),
            const SizedBox(width: 12),
          ],
          Icon(Icons.fitness_center_rounded,
              color: context.f3textMuted, size: 14),
          const SizedBox(width: 3),
          Text(l10n.homeExercisesCount(exerciseCount),
              style: TextStyle(
                  color: context.f3textSecondary, fontSize: 13)),
          const SizedBox(width: 12),
          Icon(Icons.people_rounded,
              color: context.f3textMuted, size: 14),
          const SizedBox(width: 3),
          Text(paxLabel,
              style: TextStyle(
                  color: context.f3textSecondary, fontSize: 13)),
        ]),
      ]),
    );
  }
}

// ─── Featured exercise card ───────────────────────────────────────────────────

class _FeaturedExerciseCard extends StatelessWidget {
  final Exercise exercise;
  const _FeaturedExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final color = F3Colors.forCategory(exercise.category.name);
    return GestureDetector(
      onTap: () => ExerciseDetailSheet.show(context, exercise),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context)!.homeExerciseOfDay,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
              const SizedBox(height: 6),
              Text(exercise.name,
                  style: TextStyle(
                      color: context.f3textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 17)),
              const SizedBox(height: 4),
              Text(exercise.category.displayName,
                  style: TextStyle(color: color, fontSize: 12)),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: color, size: 22),
        ]),
      ),
    );
  }
}

// ─── Streak card ──────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final int weeks;
  const _StreakCard({required this.weeks});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.f3divider),
      ),
      child: Row(children: [
        const Icon(Icons.local_fire_department_rounded,
            color: F3Colors.accent, size: 28),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: '$weeks ',
                style: const TextStyle(
                    color: F3Colors.accent,
                    fontSize: 22,
                    fontWeight: FontWeight.w900),
              ),
              TextSpan(
                text: l10n.homeWeekStreakLabel,
                style: TextStyle(
                    color: context.f3textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800),
              ),
            ]),
          ),
          Text(l10n.homeStreakDesc,
              style: TextStyle(color: context.f3textSecondary, fontSize: 12)),
        ]),
      ]),
    );
  }
}

// ─── Motivational stats card ─────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final List<WorkoutHistory> sessions;
  const _StatsCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalBeatdowns = sessions.length;
    final uniquePax = sessions
        .expand((s) => s.pax)
        .toSet()
        .length;
    final totalPaxLed = sessions.fold(0, (sum, s) => sum + s.totalCount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.f3divider),
      ),
      child: Row(children: [
        const Icon(Icons.bar_chart_rounded,
            color: F3Colors.accent, size: 24),
        const SizedBox(width: 12),
        Expanded(
          // A single localized sentence, not RichText spans stitched from
          // English fragments — Spanish/French word order doesn't match
          // English's "led X across Y" structure, so per-fragment colored
          // spans can't survive translation. Trade the two-tone styling for
          // correct grammar.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeStatsLed(totalPaxLed, totalBeatdowns),
                style: TextStyle(
                    color: context.f3textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              if (uniquePax > 0)
                Text(
                  l10n.homeStatsUniquePax(uniquePax),
                  style: TextStyle(color: context.f3textMuted, fontSize: 12),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── Quick start helpers ──────────────────────────────────────────────────────

void _loadLastSession(BuildContext context, WorkoutHistory session) {
  final exerciseSvc = context.read<ExerciseService>();
  final blocks = session.blocks.map((b) {
    final cat = ExerciseCategory.values.firstWhere(
        (c) => c.name == b.category,
        orElse: () => ExerciseCategory.bodyweight);
    final exercises = b.exerciseNames
        .map((name) => exerciseSvc.all.firstWhere((e) => e.name == name,
            orElse: () => exerciseSvc.all.first))
        .toList();
    return WorkoutBlock(
      label: b.label,
      category: cat,
      exercises: exercises,
      durationMinutes: b.durationMinutes,
      rounds: b.rounds,
    );
  }).toList();
  final plan = WorkoutPlan(
    id: const Uuid().v4(),
    generatedAt: DateTime.now(),
    blocks: blocks,
    settings: const WorkoutSettings(),
  );
  context.read<CurrentWorkoutService>().setDraftPlan(plan);
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const WorkoutScreen()),
  );
}

class _QuickStartRow extends StatelessWidget {
  final bool hasDraft;
  final WorkoutHistory? lastSession;
  final VoidCallback onResume;
  final VoidCallback onRandom;
  final VoidCallback? onLoadLast;

  const _QuickStartRow({
    required this.hasDraft,
    required this.lastSession,
    required this.onResume,
    required this.onRandom,
    this.onLoadLast,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.homeQuickStart,
            style: TextStyle(
                color: context.f3textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Row(children: [
          if (hasDraft) ...[
            Expanded(
              child: _StartChip(
                icon: Icons.play_circle_rounded,
                label: l10n.homeResume,
                color: F3Colors.accent,
                onTap: onResume,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: _StartChip(
              icon: Icons.bolt_rounded,
              label: l10n.homeRandom,
              color: F3Colors.phaseThang,
              onTap: onRandom,
            ),
          ),
          if (onLoadLast != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: _StartChip(
                icon: Icons.history_rounded,
                label: l10n.homeLastPlan,
                color: F3Colors.phaseMary,
                onTap: onLoadLast!,
              ),
            ),
          ],
        ]),
      ],
    );
  }
}

class _StartChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StartChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8)),
        ]),
      ),
    );
  }
}

// ─── Core Values ─────────────────────────────────────────────────────────────

class _CoreValues extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: F3Colors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: F3Colors.accent.withValues(alpha: 0.2)),
      ),
      child: Builder(builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.homeCoreValuesTitle,
              style: const TextStyle(
                  color: F3Colors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5)),
          const SizedBox(height: 8),
          _F(l10n.homeCoreFitness, l10n.homeCoreFitnessDesc),
          _F(l10n.homeCoreFellowship, l10n.homeCoreFellowshipDesc),
          _F(l10n.homeCoreFaith, l10n.homeCoreFaithDesc),
        ]);
      }),
    );
  }
}

class _F extends StatelessWidget {
  final String label;
  final String desc;
  const _F(this.label, this.desc);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(text: '$label  ',
              style: const TextStyle(
                  color: F3Colors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
          TextSpan(text: desc,
              style: TextStyle(
                  color: context.f3textSecondary, fontSize: 13)),
        ]),
      ),
    );
  }
}

class _UpcomingBeatdownsSection extends StatefulWidget {
  const _UpcomingBeatdownsSection();

  @override
  State<_UpcomingBeatdownsSection> createState() => _UpcomingBeatdownsSectionState();
}

class _UpcomingBeatdownsSectionState extends State<_UpcomingBeatdownsSection> {
  List<F3EventInstance>? _events;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final api = context.read<F3ApiService>();
    final profile = context.read<AppProfileService>();
    final userId = int.tryParse(profile.authUserId);
    final events = await api.getUpcomingBeatdowns(userId: userId);
    // Only the ones the PAX is actually HC'd or Q'd for — not every
    // beatdown in the region (that's what Schedule is for).
    final mine = events.where((e) => e.userAttending || e.userIsQ).toList();
    if (!mounted) return;
    setState(() {
      _events = mine.take(7).toList();
      _loading = false;
    });
    // Keep day-before/hour-before (and post-event backblast, if Q'd)
    // reminders in sync with the real HC/Q state — reconciles against
    // whatever was scheduled before, so un-HC'ing elsewhere (Slack, the
    // webapp) still cancels the stale reminder.
    await NotificationService().reconcileEventReminders(mine
        .where((e) => e.numericId != null)
        .map((e) => (
              id: e.numericId!,
              dateTime: e.dateTime,
              title: e.orgName ?? e.locationName ?? 'Beatdown',
              isQ: e.userIsQ,
              hasPreblast: (e.preblast ?? '').isNotEmpty,
            ))
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 96,
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    final events = _events ?? [];
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 13, color: F3Colors.accent),
              const SizedBox(width: 6),
              Text(
                l10n.homeUpcomingBeatdowns,
                style: TextStyle(
                  color: context.f3textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              l10n.homeNothingHcd,
              style: TextStyle(color: context.f3textMuted, fontSize: 12),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _UpcomingBeatdownsCard(events: events),
          ),
      ],
    );
  }
}

/// One summary card: how many beatdowns the PAX is HC'd/Q'd for, a preview
/// of the next one (with its actual AO, not just a location string), and a
/// tap-through to Schedule for the rest — replaces the old horizontal chip
/// list, which showed `locationName` instead of the AO and gave no sense of
/// how many were coming up without scrolling.
class _UpcomingBeatdownsCard extends StatelessWidget {
  final List<F3EventInstance> events;
  const _UpcomingBeatdownsCard({required this.events});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final next = events.first;
    final count = events.length;
    final isToday = _isToday(next.date);
    final isTomorrow = _isTomorrow(next.date);
    final dayLabel = isToday
        ? l10n.homeToday
        : isTomorrow
            ? l10n.homeTomorrow
            : _shortDate(next.date);
    final aoName = next.orgName ?? next.locationName ?? next.name ?? 'AO';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Pre-set Schedule's "mine" filter to the combined HC'd-or-Q'd
          // set — matches what this card's own count badge already shows.
          context.read<ValueNotifier<MineFilter?>>().value = MineFilter.hcOrQ;
          context.read<ValueNotifier<int>>().value = 2; // Schedule tab
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.f3card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.f3divider),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: F3Colors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: F3Colors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeHcdCount(count),
                      style: TextStyle(
                        color: context.f3textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$dayLabel · $aoName${next.userIsQ ? ' · ${l10n.homeYoureQ}' : ''}',
                      style: TextStyle(color: context.f3textMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (count > 1) ...[
                      const SizedBox(height: 6),
                      _WeekSpreadDots(events: events),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.homeSeeAll,
                    style: const TextStyle(
                      color: F3Colors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: F3Colors.accent, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isTomorrow(DateTime d) {
    final tom = DateTime.now().add(const Duration(days: 1));
    return d.year == tom.year && d.month == tom.month && d.day == tom.day;
  }

  String _shortDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[d.weekday - 1]} ${months[d.month - 1]} ${d.day}';
  }
}

/// One dot per upcoming HC'd/Q'd beatdown (capped, with a "+N" overflow) —
/// accent for anything within the next 7 days, steel blue for beyond that,
/// so it's visible at a glance that these are spread across more than one
/// week without having to tap through to Schedule.
class _WeekSpreadDots extends StatelessWidget {
  final List<F3EventInstance> events;
  static const _maxDots = 6;

  const _WeekSpreadDots({required this.events});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekCutoff =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 7));
    final shown = events.take(_maxDots).toList();
    final overflow = events.length - shown.length;
    return Row(
      children: [
        for (final e in shown)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: e.date.isBefore(weekCutoff)
                  ? F3Colors.accent
                  : F3Colors.phaseDisclaimer,
            ),
          ),
        if (overflow > 0)
          Text(
            '+$overflow',
            style: TextStyle(
              color: context.f3textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}
