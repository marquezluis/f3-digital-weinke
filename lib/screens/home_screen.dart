// lib/screens/home_screen.dart
// Digital Weinke — home dashboard.
// Branding: F3 "Badass Black" + red-orange accent.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/workout_history.dart';
import '../models/workout_plan.dart';
import '../models/workout_settings.dart';
import '../services/app_profile_service.dart' hide AppRole;
import '../services/current_workout_service.dart';
import '../services/exercise_service.dart';
import '../services/history_service.dart';
import '../utils/greeting.dart';
import '../services/settings_service.dart';
import '../services/f3_api_service.dart';
import '../models/f3_api_models.dart';
import '../widgets/exercise_detail_sheet.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import '../widgets/version_footer.dart';
import 'qsource_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.read<ExerciseService>();
    final counts = service.categoryCounts;
    final settingsSvc = context.watch<SettingsService>();
    final appRole = settingsSvc.appRole;
    final myF3Name = settingsSvc.myF3Name;
    final now = DateTime.now();
    final isGloom = now.hour < 9;

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
                    // Wordmark + avatar row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: 'DIGITAL ',
                                style: TextStyle(
                                  color: context.f3textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  height: 1,
                                ),
                              ),
                              TextSpan(
                                text: 'WEINKE',
                                style: TextStyle(
                                  color: F3Colors.accent,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  height: 1,
                                ),
                              ),
                            ]),
                          ),
                        ),
                        // Tap the avatar to jump to your profile & settings.
                        const _HomeAvatar(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Big, friendly greeting — the personal hello.
                    Builder(builder: (context) {
                      final profileName =
                          context.watch<AppProfileService>().displayName;
                      final name =
                          myF3Name.isNotEmpty ? myF3Name : profileName;
                      final greeting = greetingForNow(now);
                      return RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: name.isEmpty ? greeting : '$greeting,\n',
                            style: TextStyle(
                              color: context.f3textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                          if (name.isNotEmpty)
                            TextSpan(
                              text: name,
                              style: TextStyle(
                                color: context.f3textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                        ]),
                      );
                    }),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(now),
                      style: TextStyle(
                        color: context.f3textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isGloom
                          ? 'SYITG — See You in the Gloom.'
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

            // ── 50-min timeline preview ───────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                  child: _TimelineCard()),
            ),

            // ── Exicon stats ──────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                  child: _StatsRow(counts: counts, total: service.all.length)),
            ),

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

            // ── Quick start row (Q role only) ─────────────────────────────
            if (appRole == AppRole.q)
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
                        onResume: () => _nav(context, 1),
                        onRandom: () {
                          context.read<CurrentWorkoutService>().clearDraft();
                          _nav(context, 1);
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
            if (appRole == AppRole.q)
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
                        onTap: () => _nav(context, 1),
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
                                    'CURRENT WEINKE — ${plan.allExercises.length} exercises',
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

            // ── Recent exercises carousel ─────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
              sliver: SliverToBoxAdapter(
                child: _RecentExercisesCarousel(),
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
                      child: Text('QUICK ACTIONS',
                          style: TextStyle(
                              color: context.f3textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5)),
                    ),
                    // Trimmed to the essentials — Exicon, Live Timer, and
                    // Spartan Co-Q each have a dedicated nav tab, so they don't
                    // need to also crowd the home page.
                    if (appRole == AppRole.q) ...[
                      _QuickCard(
                        icon: Icons.bolt_rounded,
                        title: 'Generate Beatdown',
                        subtitle: 'Random 50-min plan from the Exicon',
                        color: F3Colors.accent,
                        onTap: () => _nav(context, 1),
                      ),
                      const SizedBox(height: 8),
                    ],
                    _QuickCard(
                      icon: Icons.school_rounded,
                      title: 'Q Field Guide',
                      subtitle: 'Prep · cadence · COT · backblast · QSource',
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
                        title: 'Beatdown History',
                        subtitle: svc.all.isEmpty
                            ? 'No sessions yet — save your first beatdown'
                            : '${svc.all.length} session${svc.all.length == 1 ? "" : "s"} · tap to view & share backblast',
                        color: F3Colors.phaseMary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HistoryScreen()),
                        ),
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

            // ── Version & Credits ─────────────────────────────────────────
            const SliverToBoxAdapter(
              child: VersionFooter(),
            ),
          ],
        ),
      ),
    );
  }

  void _nav(BuildContext context, int index) {
    context.read<ValueNotifier<int>>().value = index;
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

// ─── 50-minute timeline card ──────────────────────────────────────────────────

class _TimelineCard extends StatelessWidget {
  static const _phases = [
    ('DISCLAIMER',   '1m',  F3Colors.phaseDisclaimer),
    ('WARM-O-RAMA',  '7m',  F3Colors.phaseWarmup),
    ('THE THANG',    '32m', F3Colors.phaseThang),
    ('MARY',         '6m',  F3Colors.phaseMary),
    ('COT',          '4m',  F3Colors.phaseCOT),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.f3divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('50-MINUTE TIMELINE',
              style: TextStyle(
                  color: context.f3textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Row(
            children: _phases.map((p) {
              final flex = p.$2 == '32m' ? 32 : p.$2 == '7m' ? 7 :
                           p.$2 == '6m' ? 6 : p.$2 == '4m' ? 4 : 1;
              return Expanded(
                flex: flex,
                child: Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: p.$3,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: _phases.map((p) => Expanded(
              flex: p.$2 == '32m' ? 32 : p.$2 == '7m' ? 7 :
                   p.$2 == '6m' ? 6 : p.$2 == '4m' ? 4 : 1,
              child: Text(p.$2,
                  style: TextStyle(
                      color: p.$3, fontSize: 9, fontWeight: FontWeight.w700)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Map<ExerciseCategory, int> counts;
  final int total;

  const _StatsRow({required this.counts, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.f3divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('EXICON LOADED',
                style: TextStyle(
                    color: context.f3textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
            const Spacer(),
            Text('$total exercises',
                style: const TextStyle(
                    color: F3Colors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Row(
            children: ExerciseCategory.values.map((cat) {
              final color = F3Colors.forCategory(cat.name);
              return Expanded(
                child: Column(children: [
                  Text('${counts[cat] ?? 0}',
                      style: TextStyle(
                          color: color,
                          fontSize: 24,
                          fontWeight: FontWeight.w900)),
                  Text(cat.shortName,
                      style: TextStyle(
                          color: context.f3textMuted, fontSize: 10),
                      overflow: TextOverflow.ellipsis),
                ]),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Quick action card ────────────────────────────────────────────────────────

// ─── Home avatar ──────────────────────────────────────────────────────────────

/// Circular profile avatar in the home header. Shows the F3 Nation avatar
/// when synced, else the user's initial, else a shield. Tapping it jumps to
/// Settings (where the profile & account live).
class _HomeAvatar extends StatelessWidget {
  const _HomeAvatar();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProfileService>(
      builder: (context, profile, _) {
        final url = profile.avatarUrl;
        final name = profile.displayName;
        final initial =
            name.isNotEmpty ? name.characters.first.toUpperCase() : '';
        return GestureDetector(
          onTap: () => context.read<ValueNotifier<int>>().value = 6,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: F3Colors.accent.withValues(alpha: 0.14),
              border:
                  Border.all(color: F3Colors.accent.withValues(alpha: 0.5), width: 2),
              image: url.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(url), fit: BoxFit.cover)
                  : null,
            ),
            alignment: Alignment.center,
            child: url.isNotEmpty
                ? null
                : (initial.isNotEmpty
                    ? Text(initial,
                        style: const TextStyle(
                            color: F3Colors.accent,
                            fontWeight: FontWeight.w900,
                            fontSize: 20))
                    : const Icon(Icons.shield_rounded,
                        color: F3Colors.accent, size: 24)),
          ),
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
          Text('LAST BEATDOWN',
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
          session.title.isEmpty ? 'Beatdown' : session.title,
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
          Text('$exerciseCount exercises',
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
              Text('EXERCISE OF THE DAY',
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
                text: 'WEEK STREAK',
                style: TextStyle(
                    color: context.f3textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800),
              ),
            ]),
          ),
          Text('Consecutive weeks with a completed beatdown',
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
          child: RichText(
            text: TextSpan(children: [
              TextSpan(
                text: "You've led ",
                style: TextStyle(
                    color: context.f3textSecondary, fontSize: 13),
              ),
              TextSpan(
                text: '$totalPaxLed PAX',
                style: const TextStyle(
                    color: F3Colors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800),
              ),
              TextSpan(
                text: ' across ',
                style: TextStyle(
                    color: context.f3textSecondary, fontSize: 13),
              ),
              TextSpan(
                text: '$totalBeatdowns beatdown${totalBeatdowns == 1 ? "" : "s"}',
                style: const TextStyle(
                    color: F3Colors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800),
              ),
              if (uniquePax > 0)
                TextSpan(
                  text: ' · $uniquePax unique PAX',
                  style: TextStyle(
                      color: context.f3textMuted, fontSize: 12),
                ),
            ]),
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
  context.read<ValueNotifier<int>>().value = 1;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QUICK START',
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
                label: 'RESUME',
                color: F3Colors.accent,
                onTap: onResume,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: _StartChip(
              icon: Icons.bolt_rounded,
              label: 'RANDOM',
              color: F3Colors.phaseThang,
              onTap: onRandom,
            ),
          ),
          if (onLoadLast != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: _StartChip(
                icon: Icons.history_rounded,
                label: 'LAST PLAN',
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
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('THE THREE F\'S',
            style: TextStyle(
                color: F3Colors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        SizedBox(height: 8),
        _F('FITNESS',    'Free, peer-led outdoor workouts for men.'),
        _F('FELLOWSHIP', 'Community forged through shared struggle.'),
        _F('FAITH',      'Spiritual growth through accountability.'),
      ]),
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

// ─── Recent exercises carousel ────────────────────────────────────────────────

class _RecentExercisesCarousel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final history = context.read<HistoryService>();
    final exerciseSvc = context.read<ExerciseService>();

    final seen = <String>{};
    final recentNames = <String>[];
    for (final session in history.all.where((h) => !h.isTemplate).take(3)) {
      for (final block in session.blocks) {
        for (final name in block.exerciseNames) {
          if (seen.add(name)) recentNames.add(name);
          if (recentNames.length >= 10) break;
        }
        if (recentNames.length >= 10) break;
      }
      if (recentNames.length >= 10) break;
    }

    if (recentNames.isEmpty) return const SizedBox.shrink();

    Exercise? findByName(String name) {
      try { return exerciseSvc.all.firstWhere((e) => e.name == name); }
      catch (_) { return null; }
    }

    final exercises = recentNames
        .map(findByName)
        .whereType<Exercise>()
        .take(8)
        .toList();

    if (exercises.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'RECENTLY USED',
            style: TextStyle(
              color: context.f3textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: exercises.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final ex = exercises[i];
              final color = F3Colors.forCategory(ex.category.name);
              return GestureDetector(
                onTap: () => ExerciseDetailSheet.show(context, ex),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    ex.name,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Upcoming Beatdowns (F3 Nation API) ───────────────────────────────────────

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
    final events = await api.getUpcomingBeatdowns();
    if (!mounted) return;
    setState(() {
      _events = events.take(7).toList();
      _loading = false;
    });
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
    if (events.isEmpty) return const SizedBox.shrink();

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
                'UPCOMING BEATDOWNS',
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
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _BeatdownChip(event: events[i]),
          ),
        ),
      ],
    );
  }
}

class _BeatdownChip extends StatelessWidget {
  final F3EventInstance event;
  const _BeatdownChip({required this.event});

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(event.date);
    final isTomorrow = _isTomorrow(event.date);
    final dayLabel = isToday
        ? 'TODAY'
        : isTomorrow
            ? 'TOMORROW'
            : _shortDate(event.date);

    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday
            ? F3Colors.accent.withValues(alpha: 0.12)
            : context.f3card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday ? F3Colors.accent.withValues(alpha: 0.5) : context.f3divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayLabel,
            style: TextStyle(
              color: isToday ? F3Colors.accent : context.f3textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            event.locationName ?? 'AO',
            style: TextStyle(
              color: context.f3textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          if (event.hasQ)
            Text(
              'Q: ${event.qF3Name ?? '—'}',
              style: TextStyle(
                color: context.f3textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else
            Text(
              'Q OPEN',
              style: TextStyle(
                color: F3Colors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
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
