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
import '../services/region_service.dart';
import '../utils/greeting.dart';
import '../utils/streak_calculator.dart';
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
import 'brotherhood_screen.dart';
import 'chat_screen.dart';
import 'heatmap_screen.dart';
import '../utils/shared_plan_importer.dart';

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
            // ── Wordmark + compact identity ─────────────────────────────
            // The old design gave the personal welcome card the same visual
            // weight as everything below it — nothing on the page told a
            // returning user which thing actually mattered today. Identity
            // now rides as a slim, tappable strip; the Today hero below it
            // (not this) is the one deliberately dominant element on Home.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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
                    const SizedBox(height: 14),
                    Builder(builder: (context) {
                      final profileName =
                          context.watch<AppProfileService>().displayName;
                      final name =
                          myF3Name.isNotEmpty ? myF3Name : profileName;
                      final greeting =
                          greetingFor(AppLocalizations.of(context)!, now);
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()),
                          ),
                          child: Row(children: [
                            const _HomeAvatar(size: 40),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    // 2 lines, not 1 — a name should never
                                    // silently truncate away at larger
                                    // accessibility text sizes just because
                                    // this row is meant to read compact.
                                    '$greeting, ${name.isEmpty ? l10n.homeWelcomeFallback : name}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: context.f3textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  Tooltip(
                                    message: isGloom
                                        ? 'The gloom = the dark, early-morning hours before sunrise most F3 beatdowns happen in.'
                                        : '',
                                    triggerMode: TooltipTriggerMode.longPress,
                                    child: Text(
                                      // The rotating daily mottos (_dailyMotto)
                                      // are deliberately left English-only for
                                      // now — 25 short motivational lines is a
                                      // large translation surface on its own,
                                      // scoped out of this pass.
                                      isGloom ? l10n.homeSyitg : _dailyMotto(now),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: context.f3textSecondary,
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: context.f3textMuted, size: 18),
                          ]),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ── Today hero (F3 Nation API) ───────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Consumer<F3ApiService>(
                  builder: (context, api, _) => api.isConfigured
                      ? const _TodayHero()
                      // Only reachable on a dev/debug build missing its API
                      // key — every real user is already F3-Nation-signed-in
                      // by the time they reach Home — but a silent blank
                      // space here used to look like a bug rather than a
                      // build config gap.
                      : const _ApiNotConfiguredNotice(),
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
                child: Consumer3<HistoryService, ExerciseService, RegionService>(
                  builder: (context, historySvc, exerciseSvc, regionSvc, _) {
                    final sessions = historySvc.all
                        .where((e) => e.completed && !e.isTemplate)
                        .toList();
                    final exercises = exerciseSvc.all;
                    final streak = streakInfo(sessions);
                    final featured = exercises.isEmpty
                        ? null
                        : exercises[_dayOfYear(DateTime.now()) % exercises.length];
                    return Column(children: [
                      // The app's most mission-critical, easiest-to-ignore
                      // feature (turning EH'd prospects into real PAX) goes
                      // first in this section, not buried on Brotherhood's
                      // long scroll where it's easy to never see.
                      if (regionSvc.ehProspects.isNotEmpty) ...[
                        _EhProspectsCard(region: regionSvc),
                        const SizedBox(height: 8),
                      ],
                      // A brand-new PAX with no history yet sees almost
                      // nothing else on this screen — give them a next
                      // action instead of a page that looks unfinished.
                      if (sessions.isEmpty) ...[
                        _FirstBeatdownNudge(
                            onTap: () => _openWeinke(context)),
                        const SizedBox(height: 8),
                      ],
                      if (sessions.isNotEmpty)
                        _LastBeatdownCard(session: sessions.first),
                      if (featured != null) ...[
                        const SizedBox(height: 8),
                        _FeaturedExerciseCard(exercise: featured),
                      ],
                      // Someone with real history but a currently-broken
                      // streak (status none, weeks 0) used to see no card at
                      // all here — indistinguishable from someone who's
                      // simply never posted. Show it whenever there's any
                      // history, with a "start today" state for the 0 case.
                      if (sessions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _StreakCard(streak: streak),
                      ],
                      // History's "greatest hits" filter (rating == 1) was a
                      // strong retention hook with zero surfacing outside
                      // History itself — a nostalgia nudge on a slow week
                      // (nothing posted yet) can pull a lapsed PAX back.
                      if (streak.status != StreakStatus.secured) ...[
                        Builder(builder: (context) {
                          final hits =
                              sessions.where((e) => e.rating == 1).toList();
                          if (hits.isEmpty) return const SizedBox.shrink();
                          final pick = hits[
                              _dayOfYear(DateTime.now()) % hits.length];
                          return Column(children: [
                            const SizedBox(height: 8),
                            _GreatestHitNudge(
                              title: pick.title,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const HistoryScreen()),
                              ),
                            ),
                          ]);
                        }),
                      ],
                      if (sessions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _StatsCard(sessions: sessions),
                        const SizedBox(height: 8),
                        _ActivityStripCard(sessions: sessions),
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
                    // Chat previously had no entry point anywhere on Home
                    // despite being the newest engagement surface — it was
                    // only reachable by already being on Brotherhood.
                    _QuickCard(
                      icon: Icons.forum_rounded,
                      title: l10n.homeRegionChat,
                      subtitle: l10n.homeRegionChatSub,
                      color: F3Colors.catBodyweight,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatScreen()),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 8),
                    // Same import a Co-Q's shared plan already does from
                    // History's app bar — that action was only ever
                    // discoverable by someone who happened to already be in
                    // History, not something a Q would think to look for.
                    _QuickCard(
                      icon: Icons.group_add_rounded,
                      title: 'Import a Co-Q\'s Plan',
                      subtitle: 'Paste a plan a Co-Q shared with you',
                      color: F3Colors.phaseWarmup,
                      onTap: () => importSharedPlanFromClipboard(
                          context, context.read<HistoryService>()),
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

// StreakStatus/StreakInfo/_streakInfo/_daysLeftInWeek now live in
// ../utils/streak_calculator.dart, so the logic is actually unit-testable —
// it used to be private to this file.

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

class _ApiNotConfiguredNotice extends StatelessWidget {
  const _ApiNotConfiguredNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.f3elevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.f3divider),
      ),
      child: Row(children: [
        Icon(Icons.wifi_off_rounded, color: context.f3textMuted, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "F3 API key isn't set for this build — schedule features are unavailable.",
            style: TextStyle(color: context.f3textMuted, fontSize: 11.5),
          ),
        ),
      ]),
    );
  }
}

class _GreatestHitNudge extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _GreatestHitNudge({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.f3card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.f3divider),
          ),
          child: Row(children: [
            const Icon(Icons.star_rounded, color: F3Colors.phaseCOT, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Run it back',
                      style: TextStyle(
                          color: context.f3textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  Text(
                      title.isEmpty
                          ? 'A greatest hit from your history'
                          : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: context.f3textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.f3textMuted),
          ]),
        ),
      ),
    );
  }
}

class _FirstBeatdownNudge extends StatelessWidget {
  final VoidCallback onTap;
  const _FirstBeatdownNudge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: F3Colors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: F3Colors.accent.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: F3Colors.accent.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: F3Colors.accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.homeFirstBeatdownTitle,
                      style: TextStyle(
                          color: context.f3textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(l10n.homeFirstBeatdownSubtitle,
                      style: TextStyle(
                          color: context.f3textSecondary, fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: F3Colors.accent),
          ]),
        ),
      ),
    );
  }
}

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

// ─── EH prospects card ────────────────────────────────────────────────────────

class _EhProspectsCard extends StatelessWidget {
  final RegionService region;
  const _EhProspectsCard({required this.region});

  @override
  Widget build(BuildContext context) {
    final prospects = region.ehProspects;
    final needingFollowUp = region.prospectsNeedingFollowUp;
    final urgent = needingFollowUp.isNotEmpty;
    // Gold matches the same urgency signal the streak card uses; blue (an
    // existing token, not a new color) for the calm "nothing due" state so
    // it doesn't read as a second brand accent competing with the red hero.
    final color = urgent ? F3Colors.phaseCOT : F3Colors.catBodyweight;
    final title = urgent
        ? '${needingFollowUp.length} ${needingFollowUp.length == 1 ? 'prospect needs' : 'prospects need'} a follow-up'
        : '${prospects.length} EH ${prospects.length == 1 ? 'prospect' : 'prospects'} in your pipeline';
    final subtitle = urgent
        ? needingFollowUp.map((p) => p.name).take(3).join(', ')
        : "You're all caught up";

    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const BrotherhoodScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: urgent ? color.withValues(alpha: 0.08) : context.f3card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: urgent ? color.withValues(alpha: 0.4) : context.f3divider),
        ),
        child: Row(children: [
          Icon(Icons.record_voice_over_rounded, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                title,
                style: TextStyle(
                  color: urgent ? color : context.f3textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: urgent ? color : context.f3textSecondary, fontSize: 12),
              ),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: context.f3textMuted, size: 20),
        ]),
      ),
    );
  }
}

// ─── Streak card ──────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final StreakInfo streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final atRisk = streak.status == StreakStatus.atRisk;
    final zero = streak.status == StreakStatus.none;
    // Gold, not another shade of the brand red — an at-risk streak needs to
    // read as its own kind of signal, not just "more accent," the same way
    // a phase color does elsewhere in the app. Zero starts calm/neutral —
    // it's an invitation, not a warning.
    final color = atRisk
        ? F3Colors.phaseCOT
        : zero
            ? context.f3textMuted
            : F3Colors.accent;
    final daysLeft = daysLeftInWeek(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: atRisk ? color.withValues(alpha: 0.08) : context.f3card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: atRisk ? color.withValues(alpha: 0.4) : context.f3divider),
      ),
      child: Row(children: [
        Icon(
            atRisk || zero
                ? Icons.local_fire_department_outlined
                : Icons.local_fire_department_rounded,
            color: color,
            size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: zero ? '' : '${streak.weeks} ',
                  style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900),
                ),
                TextSpan(
                  text: zero ? l10n.homeStreakZeroTitle : l10n.homeWeekStreakLabel,
                  style: TextStyle(
                      color: context.f3textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ]),
            ),
            Text(
              // Scoped out of translation for now, same as the other new
              // copy on this screen — the calm-state description below
              // stays on the existing localized string.
              zero
                  ? l10n.homeStreakZeroDesc
                  : atRisk
                      ? (daysLeft == 1
                          ? "Don't break it — post today to keep it alive"
                          : "Don't break it — $daysLeft days left to post")
                      : l10n.homeStreakDesc,
              style: TextStyle(
                  color: atRisk ? color : context.f3textSecondary,
                  fontSize: 12,
                  fontWeight: atRisk ? FontWeight.w700 : FontWeight.normal),
            ),
          ]),
        ),
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

// ─── Recent activity strip ────────────────────────────────────────────────────

/// A compact, tappable preview of the full Heatmap screen's 52-week grid —
/// deliberately just the last 10 weeks, small squares, no legend or month
/// labels. The full grid is a strong visualization sitting one tap deep in
/// Your Stats; this surfaces a glance of it without trying to cram the
/// entire screen onto Home. Self-contained rather than reusing
/// HeatmapScreen's internal grid logic, since that widget is built for a
/// full 52-week layout with month labels, not a small preview.
class _ActivityStripCard extends StatelessWidget {
  final List<WorkoutHistory> sessions;
  const _ActivityStripCard({required this.sessions});

  static const _weeks = 10;

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  DateTime _mostRecentMonday(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final gridStart =
        _mostRecentMonday(now).subtract(const Duration(days: 7 * (_weeks - 1)));
    final counts = <String, int>{};
    for (final s in sessions) {
      final key = _dayKey(s.date);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final maxCount =
        counts.values.isEmpty ? 0 : counts.values.reduce((a, b) => a > b ? a : b);

    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const HeatmapScreen())),
      child: Container(
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
              Text('RECENT ACTIVITY',
                  style: TextStyle(
                      color: context.f3textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, size: 16, color: context.f3textMuted),
            ]),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_weeks, (col) {
                final weekStart = gridStart.add(Duration(days: col * 7));
                return Column(
                  children: List.generate(7, (row) {
                    final day = weekStart.add(Duration(days: row));
                    if (day.isAfter(now)) {
                      return const Padding(
                        padding: EdgeInsets.all(1.5),
                        child: SizedBox(width: 9, height: 9),
                      );
                    }
                    final count = counts[_dayKey(day)] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.all(1.5),
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: count == 0
                              ? context.f3elevated
                              : Color.lerp(
                                  F3Colors.accent.withValues(alpha: 0.25),
                                  F3Colors.accent,
                                  maxCount == 0 ? 1 : count / maxCount,
                                ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ],
        ),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          // Flexible + ellipsis: a safety net against the row's widest label
          // ("LAST PLAN") clipping its Expanded share when all three chips
          // (Resume/Random/Last Plan) share the row on a narrower screen —
          // was a hard render overflow before this.
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8)),
          ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: F3Colors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: F3Colors.accent.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Builder(builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // F3's founding identity was reading as a quiet caption-sized
          // afterthought next to a dozen equally-weighted cards — bigger
          // title, an icon per value, and more breathing room make it read
          // as a statement instead of fine print.
          Text(l10n.homeCoreValuesTitle,
              style: const TextStyle(
                  color: F3Colors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5)),
          const SizedBox(height: 14),
          _F(Icons.fitness_center_rounded, l10n.homeCoreFitness,
              l10n.homeCoreFitnessDesc),
          const SizedBox(height: 10),
          _F(Icons.groups_rounded, l10n.homeCoreFellowship,
              l10n.homeCoreFellowshipDesc),
          const SizedBox(height: 10),
          _F(Icons.favorite_rounded, l10n.homeCoreFaith, l10n.homeCoreFaithDesc),
        ]);
      }),
    );
  }
}

class _F extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  const _F(this.icon, this.label, this.desc);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: F3Colors.accent, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(children: [
              TextSpan(text: '$label  ',
                  style: const TextStyle(
                      color: F3Colors.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              TextSpan(text: desc,
                  style: TextStyle(
                      color: context.f3textSecondary, fontSize: 13)),
            ]),
          ),
        ),
      ],
    );
  }
}

/// The single most important thing today, in priority order: Q'ing the next
/// HC'd/Q'd event, then HC'd for it, then nothing on the books yet. This is
/// Home's one deliberately dominant element — a full-bleed accent card, not
/// another bordered card the same size as everything below it.
class _TodayHero extends StatefulWidget {
  const _TodayHero();

  @override
  State<_TodayHero> createState() => _TodayHeroState();
}

class _TodayHeroState extends State<_TodayHero> {
  List<F3EventInstance>? _events;
  bool _loading = true;
  // Distinguishes a genuinely empty schedule from a failed fetch — without
  // this, a network hiccup renders identically to "nothing HC'd", with no
  // way to tell the difference or retry.
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final api = context.read<F3ApiService>();
    final profile = context.read<AppProfileService>();
    final userId = int.tryParse(profile.authUserId);
    final result = await api.getUpcomingBeatdownsWithStatus(userId: userId);
    // Only the ones the PAX is actually HC'd or Q'd for — not every
    // beatdown in the region (that's what Schedule is for).
    final mine =
        result.events.where((e) => e.userAttending || e.userIsQ).toList();
    if (!mounted) return;
    setState(() {
      _events = mine.take(7).toList();
      _loading = false;
      _failed = result.failed;
    });
    if (result.failed) return;
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
              hasPreblast: e.hasPreblast,
            ))
        .toList());
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return Container(
        height: 132,
        decoration: BoxDecoration(
          color: context.f3card,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final events = _events ?? [];

    if (_failed) {
      return _HeroShell(
        gradient: false,
        onTap: _fetch,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              // Distinct from the "nothing HC'd" empty state below — this
              // is a network failure, not a genuinely empty schedule, and
              // conflating the two left no way to tell "really nothing
              // scheduled" apart from "couldn't reach F3 Nation".
              child: Text("Couldn't load your schedule — tap to retry",
                  style: TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    if (events.isEmpty) {
      return _HeroShell(
        gradient: false,
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const BrowseAosScreen())),
        child: Row(
          // homeNothingHcd is a full sentence, not a short label — it wraps
          // to 2-3 lines, so the icon has to anchor to the top of the row
          // instead of the row's default vertical-center.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.explore_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l10n.homeNothingHcd,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.35)),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
          ],
        ),
      );
    }

    final next = events.first;
    final isQ = next.userIsQ;
    final isToday = _isToday(next.date);
    final isTomorrow = _isTomorrow(next.date);
    final dayLabel = isToday
        ? l10n.homeToday
        : isTomorrow
            ? l10n.homeTomorrow
            : _shortDate(next.date);
    final aoName = next.orgName ?? next.locationName ?? next.name ?? 'AO';
    final more = events.length - 1;

    return _HeroShell(
      gradient: isQ,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isQ ? 0.24 : 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (isQ ? l10n.homeYoureQ : dayLabel).toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1),
                ),
              ),
              if (isQ) ...[
                const SizedBox(width: 8),
                Text(dayLabel,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(aoName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900, height: 1.05)),
          if (more > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _WeekSpreadDots(events: events, light: true),
                const SizedBox(width: 6),
                // The dots alone read as a stray mark blown up to hero
                // scale — they worked as a supplementary detail on the old,
                // smaller card, but need a label here to mean anything.
                Text(
                  more == 1 ? '+1 more this week' : '+$more more this week',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.55)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (isQ) {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const WorkoutScreen()));
                } else {
                  context.read<ValueNotifier<MineFilter?>>().value = MineFilter.hcOrQ;
                  context.read<ValueNotifier<int>>().value = 2; // Schedule tab
                }
              },
              // Scoped out of translation for now, same as the empty-state
              // copy above.
              child: Text(isQ ? 'Build your Weinke' : l10n.homeSeeAll,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared full-bleed container for the Today hero: an intense gradient when
/// the PAX is Q'ing (the highest-stakes state), a solid accent fill
/// otherwise — both are still clearly one tier above the bordered cards
/// below them on the page.
class _HeroShell extends StatelessWidget {
  final Widget child;
  final bool gradient;
  final VoidCallback? onTap;
  const _HeroShell({required this.child, required this.gradient, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: gradient
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [F3Colors.accent, F3Colors.accentDim],
                  )
                : null,
            color: gradient ? null : F3Colors.accent.withValues(alpha: 0.88),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// One dot per upcoming HC'd/Q'd beatdown (capped, with a "+N" overflow) —
/// accent for anything within the next 7 days, steel blue for beyond that,
/// so it's visible at a glance that these are spread across more than one
/// week without having to tap through to Schedule.
class _WeekSpreadDots extends StatelessWidget {
  final List<F3EventInstance> events;
  // Renders in white-on-translucent instead of accent/steel-blue when sitting
  // on the Today hero's own colored fill, where the default palette would be
  // invisible or clash.
  final bool light;
  static const _maxDots = 6;

  const _WeekSpreadDots({required this.events, this.light = false});

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
              color: light
                  ? Colors.white.withValues(alpha: e.date.isBefore(weekCutoff) ? 0.95 : 0.5)
                  : (e.date.isBefore(weekCutoff)
                      ? F3Colors.accent
                      : F3Colors.phaseDisclaimer),
            ),
          ),
        if (overflow > 0)
          Text(
            '+$overflow',
            style: TextStyle(
              color: light ? Colors.white.withValues(alpha: 0.85) : context.f3textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}
