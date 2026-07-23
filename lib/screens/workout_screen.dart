// lib/screens/workout_screen.dart
// Weinke tab — draft/planning mode.
//
// Workflow:
//   • Generate Beatdown  — first-time or after New Beatdown; creates a fresh draft.
//   • Regenerate (shuffle icon in AppBar) — reshuffles exercises for the current
//     draft using the same settings. Does NOT touch any in-progress live plan.
//   • New Beatdown (FAB) — clears the current draft so Q can start over with
//     a brand-new plan. Does NOT disrupt an in-progress live session.
//   • Swap (per-exercise)  — replace one exercise in the draft.
//   • Save — save draft plan to history (before going live).
//   • START WORKOUT — accepts the draft as the live plan and navigates to the
//     Live tab, syncing the plan to the timer screen.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/exercise.dart';
import '../models/workout_plan.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_settings.dart';
import '../services/current_workout_service.dart';
import '../services/exercise_service.dart';
import '../services/history_service.dart';
import 'timer_screen.dart';
import '../services/music_launcher.dart';
import '../services/timer_service.dart';
import '../services/weinke_exporter.dart';
import '../services/workout_generator.dart';
import '../services/settings_service.dart';
import '../services/spartan_service.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_card.dart';
import '../widgets/exercise_detail_sheet.dart';
import '../widgets/save_session_sheet.dart';
import '../models/workout_history.dart';
import 'custom_exercise_screen.dart';

class WorkoutScreen extends StatefulWidget {
  /// True when opened from a real Schedule beatdown's "Build my Weinke"
  /// button — adds a "Use as Preblast" action that pops the built plan back
  /// to the caller (Schedule already knows the AO/date/time/Q for that
  /// event; this screen only needs to hand back the plan itself).
  final bool forPreblast;

  /// The plan text from an already-posted preblast for this same event —
  /// set when a Q is replaced (sick, conflict, etc.) and the new Q opens
  /// "Build my Weinke" for an event someone else already planned. Shown as
  /// a reference so they can reuse it instead of hunting for it separately;
  /// not parsed into blocks automatically — free-form prose isn't reliably
  /// reducible to structured exercises.
  final String? existingPreblastPlan;

  const WorkoutScreen({
    super.key,
    this.forPreblast = false,
    this.existingPreblastPlan,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    // Auto-generate on first open only if there is no existing draft.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workoutSvc = context.read<CurrentWorkoutService>();
      if (!workoutSvc.hasDraftPlan) {
        _generate();
      }
    });
  }

  /// Generate (or regenerate) a workout plan and store it as the draft.
  void _generate() {
    final service = context.read<ExerciseService>();
    final settings = context.read<SettingsService>().settings;
    setState(() => _generating = true);
    Future.microtask(() {
      final plan = WorkoutGenerator(service).generate(settings);
      if (mounted) {
        context.read<CurrentWorkoutService>().setDraftPlan(plan);
        setState(() => _generating = false);
      }
    });
  }

  /// Clear the current draft and start fresh (New Beatdown).
  /// Does NOT disturb any in-progress live session.
  void _newBeatdown() {
    context.read<CurrentWorkoutService>().clearDraft();
    // Immediately generate a fresh plan so the screen is not blank.
    _generate();
  }

  /// A real blank slate — three empty blocks (Warm-O-Rama/Thang/Mary) with
  /// no exercises, for a Q who wants to build every pick themselves rather
  /// than start from a random generated plan. Existing "Add Exercise" (per
  /// block) is how they'd then fill each one in.
  void _newBeatdownBlank() {
    final settings = context.read<SettingsService>().settings;
    final total = settings.durationMinutes;
    final thangMinutes = (total - 15).clamp(5, total);
    context.read<CurrentWorkoutService>().setDraftPlan(WorkoutPlan(
          id: const Uuid().v4(),
          generatedAt: DateTime.now(),
          settings: settings,
          blocks: [
            const WorkoutBlock(
              label: 'Warm-O-Rama',
              category: ExerciseCategory.warmup,
              exercises: [],
              durationMinutes: 7,
            ),
            WorkoutBlock(
              label: 'THE THANG',
              category: ExerciseCategory.bodyweight,
              exercises: const [],
              durationMinutes: thangMinutes,
            ),
            const WorkoutBlock(
              label: 'Mary',
              category: ExerciseCategory.mary,
              exercises: [],
              durationMinutes: 8,
            ),
          ],
        ));
  }

  Future<void> _confirmNewBeatdown() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.f3card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bolt_rounded, color: F3Colors.accent),
              title: const Text('Generate New'),
              subtitle: const Text('Auto-picked exercises, same as usual'),
              onTap: () => Navigator.pop(context, 'generate'),
            ),
            ListTile(
              leading: Icon(Icons.crop_square_rounded,
                  color: context.f3textSecondary),
              title: const Text('Start Blank'),
              subtitle: const Text('Empty blocks — you add every exercise'),
              onTap: () => Navigator.pop(context, 'blank'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == 'generate') {
      _newBeatdown();
    } else if (choice == 'blank') {
      _newBeatdownBlank();
    }
  }

  void _useAsPreblast(WorkoutPlan plan) {
    Navigator.pop(context, plan);
  }

  void _saveSession(WorkoutPlan plan) {
    final blocks = plan.blocks
        .map((b) => HistoryBlock(
              label: b.label,
              category: b.category.name,
              durationMinutes: b.durationMinutes,
              exerciseNames: b.exercises.map((e) => e.name).toList(),
              rounds: b.rounds,
            ))
        .toList();
    SaveSessionSheet.show(context, blocks: blocks);
  }

  void _saveAsTemplate(WorkoutPlan plan) async {
    final ctrl = TextEditingController(text: 'My Beatdown Template');
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.f3card,
        title: Text('Save as Template',
            style: TextStyle(color: context.f3textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: context.f3textPrimary),
          decoration: const InputDecoration(hintText: 'Template name'),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL')),
          TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child:
                  const Text('SAVE', style: TextStyle(color: F3Colors.accent))),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    final blocks = plan.blocks
        .map((b) => HistoryBlock(
              label: b.label,
              category: b.category.name,
              durationMinutes: b.durationMinutes,
              exerciseNames: b.exercises.map((e) => e.name).toList(),
              rounds: b.rounds,
            ))
        .toList();
    final template = WorkoutHistory(
      id: const Uuid().v4(),
      title: name,
      date: DateTime.now(),
      blocks: blocks,
      isTemplate: true,
    );
    await context.read<HistoryService>().add(template);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$name" saved as template.')),
      );
    }
  }

  void _showTemplates() {
    final templates =
        context.read<HistoryService>().all.where((h) => h.isTemplate).toList();
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('No templates yet. Save a plan as a template first.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: context.f3card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 16),
            const Text('LOAD TEMPLATE',
                style: TextStyle(
                    color: F3Colors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2)),
            const SizedBox(height: 8),
            ...templates.map((t) => ListTile(
                  leading: const Icon(Icons.bookmark_rounded,
                      color: F3Colors.accent),
                  title: Text(t.title,
                      style: TextStyle(
                          color: context.f3textPrimary,
                          fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      '${t.blocks.fold(0, (s, b) => s + b.exerciseNames.length)} exercises',
                      style: TextStyle(
                          color: context.f3textSecondary, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _loadTemplate(t);
                  },
                )),
            const SizedBox(height: 8),
          ]),
        );
      },
    );
  }

  void _loadTemplate(WorkoutHistory template) {
    final exerciseSvc = context.read<ExerciseService>();
    final blocks = template.blocks.map((b) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${template.title}" loaded.')),
    );
  }

  void _shareWeinke(WorkoutPlan plan) async {
    final settings = context.read<SettingsService>();
    final aoCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '0530');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.f3card,
        title: Text('Share as Preblast',
            style: TextStyle(color: context.f3textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: aoCtrl,
              autofocus: true,
              style: TextStyle(color: context.f3textPrimary),
              decoration: const InputDecoration(
                labelText: 'AO Name',
                hintText: 'e.g. Agoge',
                prefixIcon: Icon(Icons.location_on_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timeCtrl,
              style: TextStyle(color: context.f3textPrimary),
              decoration: const InputDecoration(
                labelText: 'Start Time',
                hintText: '0530',
                prefixIcon: Icon(Icons.access_time_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('SHARE', style: TextStyle(color: F3Colors.accent)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final text = WeinkeExporter.formatPreblast(
      plan,
      ao: aoCtrl.text.trim(),
      time: timeCtrl.text.trim(),
      qName: settings.myF3Name,
    );
    Share.share(text,
        subject:
            'Preblast: ${aoCtrl.text.trim().isEmpty ? "Beatdown" : aoCtrl.text.trim()}');
  }

  void _auditPlan(WorkoutPlan plan) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: context.f3card,
        title: Text('Spartan is reviewing...',
            style: TextStyle(color: context.f3textPrimary)),
        content: SizedBox(
            height: 50,
            child: Center(
                child: CircularProgressIndicator(color: F3Colors.accent))),
      ),
    );

    final spartan = SpartanService.instance;
    final feedback = await spartan.auditBeatdown(plan);

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: context.f3card,
          title: Text('Spartan Audit',
              style: TextStyle(color: context.f3textPrimary)),
          content: Text(feedback,
              style: TextStyle(color: context.f3textSecondary, height: 1.4)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('GOT IT')),
          ],
        ),
      );
    }
  }

  /// Replace (or prepend) the Warm-O-Rama block with a fresh random set.
  void _quickWarmup(WorkoutPlan plan) {
    final generator = WorkoutGenerator(context.read<ExerciseService>());
    final settings = context.read<SettingsService>().settings;
    final newWarmup = generator.buildWarmupBlock(settings);
    final newBlocks = List<WorkoutBlock>.from(plan.blocks);
    final idx =
        newBlocks.indexWhere((b) => b.category == ExerciseCategory.warmup);
    if (idx >= 0) {
      newBlocks[idx] = newWarmup;
    } else {
      newBlocks.insert(0, newWarmup);
    }
    context.read<CurrentWorkoutService>().setDraftPlan(WorkoutPlan(
          id: plan.id,
          generatedAt: plan.generatedAt,
          blocks: newBlocks,
          settings: plan.settings,
        ));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Warm-O-Rama refreshed with new exercises'),
      duration: Duration(seconds: 2),
    ));
  }

  void _swap(Exercise exercise, WorkoutPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExerciseSwapSheet(
        original: exercise,
        plan: plan,
      ),
    );
  }

  Future<void> _startWorkout(WorkoutPlan plan) async {
    final workoutSvc = context.read<CurrentWorkoutService>();
    workoutSvc.setDraftPlan(plan);
    workoutSvc.acceptDraftAsLive();
    context.read<TimerService>().reset();

    final svc = context.read<SettingsService>();
    if (svc.musicEnabled && mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: context.f3card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(Icons.music_note_rounded, color: F3Colors.accent, size: 22),
            SizedBox(width: 10),
            Text('Launch music?',
                style: TextStyle(color: context.f3textPrimary, fontSize: 17)),
          ]),
          content: Text(
            'Open your music app now. Press the back button to return to your workout when you\'re ready.',
            style: TextStyle(
                color: context.f3textSecondary, height: 1.45, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('SKIP'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 40),
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              child: const Text('LAUNCH'),
            ),
          ],
        ),
      );
      if (confirm == true && mounted) {
        await MusicLauncher.launch(svc.musicProvider, svc.musicPlaylistUrl);
      }
    }

    if (mounted) {
      // Q Mode is now reached as a pushed route (Plan hub), not a tab index.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TimerScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentWorkoutService>(
      builder: (context, workoutSvc, _) {
        final plan = workoutSvc.draftPlan;
        return Scaffold(
          backgroundColor: context.f3bg,
          appBar: AppBar(
            title: const Text('Your Weinke'),
            backgroundColor: context.f3bg,
            actions: [
              IconButton(
                icon: const Icon(Icons.bookmark_border_rounded),
                tooltip: 'Templates',
                onPressed: _showTemplates,
              ),
              if (plan != null) ...[
                if (widget.forPreblast)
                  IconButton(
                    icon: const Icon(Icons.campaign_rounded),
                    tooltip: 'Use as Preblast',
                    onPressed: () => _useAsPreblast(plan),
                  ),
                IconButton(
                  icon: const Icon(Icons.wb_sunny_rounded),
                  tooltip: 'Quick Warm-O-Rama',
                  onPressed: () => _quickWarmup(plan),
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  tooltip: 'Share as Preblast',
                  onPressed: () => _shareWeinke(plan),
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_add_rounded),
                  tooltip: 'Save as Template',
                  onPressed: () => _saveAsTemplate(plan),
                ),
                IconButton(
                  icon: const Icon(Icons.save_rounded),
                  tooltip: 'Save draft to history',
                  onPressed: () => _saveSession(plan),
                ),
                IconButton(
                  icon: const Icon(Icons.shuffle_rounded),
                  tooltip: 'Regenerate — reshuffle exercises',
                  onPressed: _generate,
                ),
              ],
            ],
          ),
          body: _generating
              ? const Center(
                  child: CircularProgressIndicator(color: F3Colors.accent))
              : plan == null
                  ? _EmptyState(
                      onGenerate: _generate, onTemplates: _showTemplates)
                  : Column(
                      children: [
                        if (widget.forPreblast)
                          Container(
                            width: double.infinity,
                            color: F3Colors.accent.withValues(alpha: 0.12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(children: [
                              const Icon(Icons.campaign_rounded,
                                  color: F3Colors.accent, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Building this beatdown\'s Weinke — tap the '
                                  'megaphone above to use it as the preblast.',
                                  style: TextStyle(
                                      color: context.f3textPrimary,
                                      fontSize: 12.5),
                                ),
                              ),
                            ]),
                          ),
                        if ((widget.existingPreblastPlan ?? '').isNotEmpty)
                          _ExistingPlanBanner(
                              plan: widget.existingPreblastPlan!),
                        _GenOptions(onChanged: _generate),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: _PlanHeader(plan: plan),
                        ),
                        Expanded(
                          child: _PlanView(
                            plan: plan,
                            onSwap: (ex) => _swap(ex, plan),
                          ),
                        ),
                      ],
                    ),
          // Bottom action area when a plan exists
          bottomNavigationBar: plan != null && !_generating
              ? _BottomActions(
                  onNewBeatdown: _confirmNewBeatdown,
                  onStartWorkout: () => _startWorkout(plan),
                )
              : null,
          // Matches the shield FAB pattern used for Spartan elsewhere in the
          // app (shell_screen.dart) — was crowding the AppBar's icon row.
          floatingActionButton: plan != null
              ? FloatingActionButton(
                  heroTag: 'weinkeSpartanFab',
                  backgroundColor: F3Colors.catCoupon,
                  foregroundColor: Colors.white,
                  tooltip: 'Audit with Spartan',
                  onPressed: () => _auditPlan(plan),
                  child: const Icon(Icons.shield_rounded),
                )
              : null,
        );
      },
    );
  }
}

// ─── Interactive Exercise Swap Sheet ──────────────────────────────────────────

class _ExerciseSwapSheet extends StatefulWidget {
  final Exercise original;
  final WorkoutPlan plan;

  const _ExerciseSwapSheet({required this.original, required this.plan});

  @override
  State<_ExerciseSwapSheet> createState() => _ExerciseSwapSheetState();
}

class _ExerciseSwapSheetState extends State<_ExerciseSwapSheet> {
  String _searchQuery = '';
  Intensity? _filterIntensity;

  @override
  void initState() {
    super.initState();
    _filterIntensity = widget.original.intensity;
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<ExerciseService>();
    final usedIds = widget.plan.allExercises.map((e) => e.id).toSet();

    var pool = service
        .byCategory(widget.original.category)
        .where((e) => e.id != widget.original.id && !usedIds.contains(e.id))
        .toList();

    if (_filterIntensity != null) {
      pool = pool.where((e) => e.intensity == _filterIntensity).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      pool = pool
          .where((e) =>
              e.name.toLowerCase().contains(q) ||
              e.description.toLowerCase().contains(q))
          .toList();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: context.f3bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: context.f3divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search for an exercise...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: Intensity.values.map((intensity) {
                  final selected = _filterIntensity == intensity;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(intensity.displayName),
                      selected: selected,
                      selectedColor: F3Colors.forIntensity(intensity.name)
                          .withValues(alpha: 0.3),
                      onSelected: (val) => setState(
                          () => _filterIntensity = val ? intensity : null),
                    ),
                  );
                }).toList(),
              ),
            ),
            Divider(color: context.f3divider),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.all(16),
                itemCount: pool.length,
                itemBuilder: (context, index) {
                  final ex = pool[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ExerciseCard(
                      exercise: ex,
                      onSwap: () {
                        final updated = widget.plan
                            .withSwappedExercise(widget.original, ex);
                        context
                            .read<CurrentWorkoutService>()
                            .swapDraftExercise(updated);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Swipeable exercise card (delete + duplicate + note) ─────────────────────

class _SwipableExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final int blockIndex;
  final int exerciseIndex;
  final VoidCallback onSwap;
  final String note;
  final CallStyle callStyle;
  final bool hasCallStyleOverride;

  const _SwipableExerciseCard({
    super.key,
    required this.exercise,
    required this.blockIndex,
    required this.exerciseIndex,
    required this.onSwap,
    this.note = '',
    this.callStyle = CallStyle.onYourOwn,
    this.hasCallStyleOverride = false,
  });

  void _editCallStyle(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.f3card,
        title: Text('How should PAX count this?',
            style: TextStyle(color: context.f3textPrimary, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasCallStyleOverride)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    Icon(Icons.undo_rounded, color: context.f3textSecondary),
                title: Text('Use block default',
                    style: TextStyle(color: context.f3textPrimary)),
                onTap: () {
                  context.read<CurrentWorkoutService>()
                      .setExerciseCallStyleInDraftBlock(
                          blockIndex, exercise.id, null);
                  Navigator.pop(context);
                },
              ),
            ...CallStyle.values.map((style) {
              final selected = callStyle == style;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? F3Colors.accent : context.f3textMuted,
                ),
                title: Text(style.displayName,
                    style: TextStyle(
                        color:
                            selected ? F3Colors.accent : context.f3textPrimary,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.normal)),
                onTap: () {
                  context.read<CurrentWorkoutService>()
                      .setExerciseCallStyleInDraftBlock(
                          blockIndex, exercise.id, style);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutSvc = context.read<CurrentWorkoutService>();
    return Dismissible(
      key: ValueKey('dismiss_${blockIndex}_${exercise.id}_$exerciseIndex'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.red, size: 26),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: context.f3card,
                title: Text('Remove exercise?',
                    style: TextStyle(color: context.f3textPrimary)),
                content: Text(exercise.name,
                    style: TextStyle(color: context.f3textSecondary)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('CANCEL')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('REMOVE',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) {
        workoutSvc.removeExerciseFromDraftBlock(blockIndex, exercise.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${exercise.name} removed'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () =>
                workoutSvc.addExerciseToDraftBlock(blockIndex, exercise),
          ),
        ));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExerciseCard(
            exercise: exercise,
            onDetail: () => ExerciseDetailSheet.show(context, exercise),
            onSwap: onSwap,
            onDuplicate: () {
              workoutSvc.duplicateExerciseInDraftBlock(
                  blockIndex, exerciseIndex);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${exercise.name} duplicated'),
                duration: const Duration(seconds: 2),
              ));
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _editNote(context, workoutSvc),
                  child: Row(children: [
                    Icon(
                      note.isEmpty
                          ? Icons.note_add_outlined
                          : Icons.sticky_note_2_rounded,
                      size: 13,
                      color:
                          note.isEmpty ? context.f3textMuted : F3Colors.accent,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        note.isEmpty ? 'Add Q note…' : note,
                        style: TextStyle(
                          color: note.isEmpty
                              ? context.f3textMuted
                              : F3Colors.accent,
                          fontSize: 11,
                          fontStyle: note.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                          fontWeight: note.isEmpty
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _editCallStyle(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: hasCallStyleOverride
                        ? F3Colors.accent.withValues(alpha: 0.18)
                        : context.f3divider.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: hasCallStyleOverride
                            ? F3Colors.accent.withValues(alpha: 0.5)
                            : Colors.transparent),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.campaign_rounded,
                        size: 10,
                        color: hasCallStyleOverride
                            ? F3Colors.accent
                            : context.f3textMuted),
                    const SizedBox(width: 3),
                    Text(callStyle.displayName,
                        style: TextStyle(
                            color: hasCallStyleOverride
                                ? F3Colors.accent
                                : context.f3textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  void _editNote(BuildContext context, CurrentWorkoutService workoutSvc) {
    final ctrl = TextEditingController(text: note);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.f3card,
        title: Text(exercise.name,
            style: TextStyle(
                color: context.f3textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 2,
          style: TextStyle(color: context.f3textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. OYO · do in cadence · flapjack halfway',
            hintStyle: TextStyle(color: context.f3textMuted),
            labelText: 'Q Note',
            labelStyle: TextStyle(color: context.f3textSecondary),
          ),
        ),
        actions: [
          if (note.isNotEmpty)
            TextButton(
              onPressed: () {
                workoutSvc.setExerciseNoteInDraftBlock(
                    blockIndex, exercise.id, '');
                Navigator.pop(ctx);
              },
              child:
                  Text('CLEAR', style: TextStyle(color: context.f3textMuted)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              workoutSvc.setExerciseNoteInDraftBlock(
                  blockIndex, exercise.id, ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom action bar ────────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  final VoidCallback onNewBeatdown;
  final VoidCallback onStartWorkout;

  const _BottomActions({
    required this.onNewBeatdown,
    required this.onStartWorkout,
  });

  // Shared style constants so both buttons have identical footprints.
  static const _kButtonHeight = 52.0;
  static const _kButtonPadding =
      EdgeInsets.symmetric(horizontal: 8, vertical: 0);
  static const _kButtonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
  static const _kButtonMinSize = Size(double.infinity, _kButtonHeight);
  static const _kLabelStyle = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 14,
    letterSpacing: 0.6,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: context.f3card,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // New Beatdown — clears draft and generates a fresh one
            Expanded(
              child: SizedBox(
                height: _kButtonHeight,
                child: OutlinedButton.icon(
                  onPressed: onNewBeatdown,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.f3textSecondary,
                    side: BorderSide(color: context.f3divider),
                    padding: _kButtonPadding,
                    minimumSize: _kButtonMinSize,
                    shape: _kButtonShape,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('New Beatdown', style: _kLabelStyle),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Start Workout — accepts draft → live and navigates to Live tab
            Expanded(
              child: SizedBox(
                height: _kButtonHeight,
                child: ElevatedButton.icon(
                  onPressed: onStartWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: F3Colors.accent,
                    foregroundColor: Colors.white,
                    padding: _kButtonPadding,
                    minimumSize: _kButtonMinSize,
                    shape: _kButtonShape,
                    elevation: 4,
                    shadowColor: F3Colors.accent.withValues(alpha: 0.45),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('START WORKOUT', style: _kLabelStyle),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onGenerate;
  final VoidCallback onTemplates;
  const _EmptyState({required this.onGenerate, required this.onTemplates});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt_rounded, color: F3Colors.accent, size: 72),
            const SizedBox(height: 20),
            Text('GENERATE YOUR WEINKE',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: context.f3textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1)),
            const SizedBox(height: 12),
            Text(
              'A full beatdown: Disclaimer → Warm-O-Rama → The Thang → '
              'Mary → COT.\nExercises drawn from the full F3 Exicon.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.f3textSecondary, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.bolt_rounded),
              label: const Text('GENERATE BEATDOWN'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onTemplates,
              icon: const Icon(Icons.bookmark_rounded, size: 18),
              label: const Text('LOAD TEMPLATE'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Existing plan reference (Q replaced) ──────────────────────────────────────

/// Shown when a new Q is building a Weinke for an event someone else already
/// posted a preblast for (e.g. the original Q got sick and dropped Q). Just
/// a reference to copy from — not parsed into blocks, since free-form prose
/// isn't reliably reducible to structured exercises.
class _ExistingPlanBanner extends StatefulWidget {
  final String plan;
  const _ExistingPlanBanner({required this.plan});

  @override
  State<_ExistingPlanBanner> createState() => _ExistingPlanBannerState();
}

class _ExistingPlanBannerState extends State<_ExistingPlanBanner> {
  bool _expanded = false;
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.plan));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.f3divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_edu_rounded,
                  color: context.f3textMuted, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Previous Q\'s plan for this beatdown',
                  style: TextStyle(
                      color: context.f3textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8),
                ),
              ),
              IconButton(
                tooltip: 'Copy',
                visualDensity: VisualDensity.compact,
                icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 16,
                    color: _copied ? F3Colors.accent : context.f3textMuted),
                onPressed: _copy,
              ),
            ],
          ),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              widget.plan,
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: TextStyle(color: context.f3textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Plan view ────────────────────────────────────────────────────────────────

/// Compact generation controls that live with the builder (moved out of
/// Settings): equipment (coupon mode) as a dropdown, plus a multi-select
/// intensity chip row. Changing either updates the shared WorkoutSettings and
/// regenerates the plan via [onChanged].
class _GenOptions extends StatelessWidget {
  final VoidCallback onChanged;
  const _GenOptions({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<SettingsService>();
    final s = svc.settings;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: context.f3bg,
        border: Border(bottom: BorderSide(color: context.f3divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center_rounded,
                  size: 16, color: context.f3textMuted),
              const SizedBox(width: 6),
              Text('Coupons in The Thang',
                  style:
                      TextStyle(color: context.f3textSecondary, fontSize: 13)),
              const Spacer(),
              DropdownButton<CouponMode>(
                value: s.couponMode,
                isDense: true,
                underline: const SizedBox.shrink(),
                style: TextStyle(
                    color: context.f3textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
                dropdownColor: context.f3card,
                items: CouponMode.values
                    .map((m) =>
                        DropdownMenuItem(value: m, child: Text(m.displayName)))
                    .toList(),
                onChanged: (m) {
                  if (m == null) return;
                  svc.update(s.copyWith(couponMode: m));
                  onChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: Intensity.values.map((i) {
              final on = s.intensities.contains(i);
              return FilterChip(
                label:
                    Text(i.displayName, style: const TextStyle(fontSize: 12)),
                selected: on,
                showCheckmark: false,
                backgroundColor: context.f3elevated,
                selectedColor:
                    F3Colors.forIntensity(i.name).withValues(alpha: 0.22),
                labelStyle: TextStyle(
                    color: on
                        ? F3Colors.forIntensity(i.name)
                        : context.f3textSecondary),
                side: BorderSide(
                    color:
                        on ? F3Colors.forIntensity(i.name) : context.f3divider),
                onSelected: (sel) {
                  final cur = Set<Intensity>.from(s.intensities);
                  if (on) {
                    if (cur.length > 1) cur.remove(i); // keep at least one
                  } else {
                    cur.add(i);
                  }
                  svc.update(s.copyWith(intensities: cur));
                  onChanged();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PlanView extends StatelessWidget {
  final WorkoutPlan plan;
  final void Function(Exercise) onSwap;

  const _PlanView({required this.plan, required this.onSwap});

  String _phaseGroup(ExerciseCategory cat) {
    switch (cat) {
      case ExerciseCategory.warmup:
        return 'WARM-O-RAMA';
      case ExerciseCategory.bodyweight:
      case ExerciseCategory.coupon:
        return 'THE THANG';
      case ExerciseCategory.mary:
        return 'MARY';
    }
  }

  List<Widget> _buildBlockSlivers(
      List<WorkoutBlock> blocks, void Function(Exercise) onSwap) {
    final slivers = <Widget>[];
    String? lastGroup;
    for (int i = 0; i < blocks.length; i++) {
      final group = _phaseGroup(blocks[i].category);
      if (group != lastGroup) {
        lastGroup = group;
        final color = F3Colors.forCategory(blocks[i].category.name);
        slivers.add(SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Row(children: [
              Expanded(child: Divider(color: color.withValues(alpha: 0.3))),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(group,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Divider(color: color.withValues(alpha: 0.3))),
            ]),
          ),
        ));
      }
      slivers.add(SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        sliver: SliverToBoxAdapter(
          child: _BlockSection(block: blocks[i], blockIndex: i, onSwap: onSwap),
        ),
      ));
    }
    return slivers;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Disclaimer
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _PhaseCard(
              label: 'DISCLAIMER',
              duration: '1 min',
              color: F3Colors.phaseDisclaimer,
              body: '"I am not a professional. Modify as needed. '
                  'Participation is voluntary."',
            ),
          ),
        ),
        // Exercise blocks grouped under phase headers
        ..._buildBlockSlivers(plan.blocks, onSwap),
        // COT
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _PhaseCard(
              label: 'COT',
              duration: '4 min',
              color: F3Colors.phaseCOT,
              body:
                  'Count-O-Rama · Name-O-Rama · FNG Naming · Announcements · Closing Word',
            ),
          ),
        ),
        // Extra padding so content clears the bottom action bar
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }
}

class _PlanHeader extends StatelessWidget {
  final WorkoutPlan plan;
  const _PlanHeader({required this.plan});

  List<String> _warnings(WorkoutPlan plan) {
    final warnings = <String>[];
    final hasWarmup = plan.blocks.any(
        (b) => b.category == ExerciseCategory.warmup && b.exercises.isNotEmpty);
    final hasThang = plan.blocks.any((b) =>
        (b.category == ExerciseCategory.bodyweight ||
            b.category == ExerciseCategory.coupon) &&
        b.exercises.isNotEmpty);
    final hasMary = plan.blocks.any(
        (b) => b.category == ExerciseCategory.mary && b.exercises.isNotEmpty);
    if (!hasWarmup) warnings.add('No Warm-O-Rama exercises');
    if (!hasThang) warnings.add('No Thang exercises');
    if (!hasMary) warnings.add('No Mary exercises');
    return warnings;
  }

  @override
  Widget build(BuildContext context) {
    final warnings = _warnings(plan);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.f3card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: F3Colors.accent.withValues(alpha: 0.35)),
          ),
          child: Row(children: [
            const Icon(Icons.bolt_rounded, color: F3Colors.accent, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("TODAY'S BEATDOWN",
                        style: TextStyle(
                            color: F3Colors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5)),
                    Text(
                        '${plan.allExercises.length} exercises · ${plan.blocks.length} blocks',
                        style: TextStyle(
                            color: context.f3textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    _TimeBudgetBar(plan: plan),
                  ]),
            ),
            Text(_fmt(plan.generatedAt),
                style: TextStyle(color: context.f3textMuted, fontSize: 11)),
          ]),
        ),
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('UNBALANCED PLAN',
                        style: TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                    const SizedBox(height: 2),
                    Text(warnings.join(' · '),
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ],
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _TimeBudgetBar extends StatelessWidget {
  final WorkoutPlan plan;
  const _TimeBudgetBar({required this.plan});

  @override
  Widget build(BuildContext context) {
    final target = plan.settings.durationMinutes;
    final planned = plan.refinedTotalMinutes;
    final ratio = (planned / target).clamp(0.0, 1.2);
    final over = planned > target;
    final under = planned < target - 2;
    final color = over
        ? Colors.redAccent
        : under
            ? Colors.orange
            : F3Colors.accent;
    final label = over
        ? '$planned min (+${planned - target} over)'
        : '$planned of $target min planned';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: context.f3divider,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    ]);
  }
}

class _PhaseCard extends StatelessWidget {
  final String label;
  final String duration;
  final Color color;
  final String body;

  const _PhaseCard({
    required this.label,
    required this.duration,
    required this.color,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(duration,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(body,
                    style: TextStyle(
                        color: context.f3textSecondary,
                        fontSize: 13,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockSection extends StatelessWidget {
  final WorkoutBlock block;
  final int blockIndex;
  final void Function(Exercise) onSwap;

  const _BlockSection({
    required this.block,
    required this.blockIndex,
    required this.onSwap,
  });

  void _addRandom(BuildContext context) {
    final service = context.read<ExerciseService>();
    final workoutSvc = context.read<CurrentWorkoutService>();
    final usedIds =
        workoutSvc.draftPlan?.allExercises.map((e) => e.id).toSet() ?? {};
    final pool = service
        .byCategory(block.category)
        .where((e) => !usedIds.contains(e.id))
        .toList()
      ..shuffle();
    if (pool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No more exercises available for this category.'),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    workoutSvc.addExerciseToDraftBlock(blockIndex, pool.first);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Added: ${pool.first.name}'),
      duration: const Duration(seconds: 2),
    ));
  }

  void _renameBlock(BuildContext context) {
    final ctrl = TextEditingController(text: block.label);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.f3card,
        title: Text('Rename Block',
            style: TextStyle(color: context.f3textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: context.f3textPrimary),
          decoration: const InputDecoration(
            hintText: 'e.g. Coupon Strength',
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              context
                  .read<CurrentWorkoutService>()
                  .renameDraftBlock(blockIndex, val.trim());
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                context
                    .read<CurrentWorkoutService>()
                    .renameDraftBlock(blockIndex, ctrl.text.trim());
              }
              Navigator.pop(context);
            },
            child:
                const Text('RENAME', style: TextStyle(color: F3Colors.accent)),
          ),
        ],
      ),
    );
  }

  void _editCallStyle(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.f3card,
        title: Text('How should PAX count this?',
            style: TextStyle(color: context.f3textPrimary, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: CallStyle.values.map((style) {
            final selected = block.callStyle == style;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? F3Colors.accent : context.f3textMuted,
              ),
              title: Text(style.displayName,
                  style: TextStyle(
                      color: selected ? F3Colors.accent : context.f3textPrimary,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.normal)),
              onTap: () {
                context
                    .read<CurrentWorkoutService>()
                    .setDraftBlockCallStyle(blockIndex, style);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }

  void _editRounds(BuildContext context) {
    int tempRounds = block.rounds;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: context.f3card,
          title: Text('Set Rounds',
              style: TextStyle(color: context.f3textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(block.label,
                  style:
                      TextStyle(color: context.f3textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline,
                        color: context.f3textSecondary, size: 32),
                    onPressed: tempRounds > 1
                        ? () => setState(() => tempRounds--)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text('$tempRounds',
                      style: TextStyle(
                          color: context.f3textPrimary,
                          fontSize: 40,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: F3Colors.accent, size: 32),
                    onPressed: tempRounds < 10
                        ? () => setState(() => tempRounds++)
                        : null,
                  ),
                ],
              ),
              Text(tempRounds == 1 ? 'round' : 'rounds',
                  style: TextStyle(color: context.f3textMuted, fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                context
                    .read<CurrentWorkoutService>()
                    .setDraftBlockRounds(blockIndex, tempRounds);
                Navigator.pop(context);
              },
              child:
                  const Text('SAVE', style: TextStyle(color: F3Colors.accent)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = F3Colors.forCategory(block.category.name);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => _renameBlock(context),
                child: Row(children: [
                  Flexible(
                    child: Text(block.label.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5)),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit_rounded,
                      color: color.withValues(alpha: 0.5), size: 13),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(
                  block.rounds > 1
                      ? '${block.durationMinutes * block.rounds} min'
                      : '${block.durationMinutes} min',
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _editRounds(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: block.rounds > 1
                        ? F3Colors.accent.withValues(alpha: 0.18)
                        : context.f3divider.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: block.rounds > 1
                            ? F3Colors.accent.withValues(alpha: 0.5)
                            : Colors.transparent)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.repeat_rounded,
                        size: 10,
                        color: block.rounds > 1
                            ? F3Colors.accent
                            : context.f3textMuted),
                    const SizedBox(width: 3),
                    Text(block.rounds > 1 ? '${block.rounds}x' : '1x',
                        style: TextStyle(
                            color: block.rounds > 1
                                ? F3Colors.accent
                                : context.f3textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _editCallStyle(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: block.callStyle != CallStyle.onYourOwn
                        ? F3Colors.accent.withValues(alpha: 0.18)
                        : context.f3divider.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: block.callStyle != CallStyle.onYourOwn
                            ? F3Colors.accent.withValues(alpha: 0.5)
                            : Colors.transparent)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.campaign_rounded,
                        size: 10,
                        color: block.callStyle != CallStyle.onYourOwn
                            ? F3Colors.accent
                            : context.f3textMuted),
                    const SizedBox(width: 3),
                    Text(block.callStyle.displayName,
                        style: TextStyle(
                            color: block.callStyle != CallStyle.onYourOwn
                                ? F3Colors.accent
                                : context.f3textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ]),
        ),
        if (block.rounds > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: F3Colors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: F3Colors.accent.withValues(alpha: 0.3))),
              child: Text(
                '${block.rounds} ROUNDS — repeat all exercises below ${block.rounds}×',
                style: const TextStyle(
                    color: F3Colors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
              ),
            ),
          ),
        if (block.notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(block.notes,
                style: TextStyle(
                    color: context.f3textMuted,
                    fontSize: 12,
                    fontStyle: FontStyle.italic)),
          ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          proxyDecorator: (child, _, __) =>
              Material(color: Colors.transparent, child: child),
          onReorder: (oldIdx, newIdx) => context
              .read<CurrentWorkoutService>()
              .reorderExerciseInDraftBlock(blockIndex, oldIdx, newIdx),
          itemCount: block.exercises.length,
          itemBuilder: (ctx, ei) {
            final ex = block.exercises[ei];
            return Padding(
              key: ValueKey('item_${blockIndex}_${ex.id}_$ei'),
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ReorderableDragStartListener(
                    index: ei,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 4, 6, 4),
                      child: Icon(Icons.drag_handle_rounded,
                          color: context.f3textMuted, size: 22),
                    ),
                  ),
                  Expanded(
                    child: _SwipableExerciseCard(
                      key: ValueKey('card_${blockIndex}_${ex.id}_$ei'),
                      exercise: ex,
                      blockIndex: blockIndex,
                      exerciseIndex: ei,
                      onSwap: () => onSwap(ex),
                      note: block.noteFor(ex.id),
                      callStyle: block.callStyleFor(ex.id),
                      hasCallStyleOverride:
                          block.exerciseCallStyles.containsKey(ex.id),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openAddExercise(context),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('ADD EXERCISE'),
            style: OutlinedButton.styleFrom(
              foregroundColor: F3Colors.forCategory(block.category.name),
              side: BorderSide(
                  color: F3Colors.forCategory(block.category.name)
                      .withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  void _openAddExercise(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.f3card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddExerciseSheet(
        blockIndex: blockIndex,
        blockLabel: block.label,
        defaultCategory: block.category,
        onRandomize: () => _addRandom(context),
      ),
    );
  }
}

// ─── Add Exercise sheet: search, randomize, or write a custom one ────────────
// Replaces the old "ADD RANDOM EXERCISE" button. Defaults to the block's own
// category (so a Warmup block still nudges toward warmup moves) but the
// category filter is switchable — a Thang block can pull bodyweight AND
// coupon exercises into the same block this way, on top of the plan-level
// "Mixed" equipment setting that already splits Thang generation between them.
class _AddExerciseSheet extends StatefulWidget {
  final int blockIndex;
  final String blockLabel;
  final ExerciseCategory defaultCategory;
  final VoidCallback onRandomize;

  const _AddExerciseSheet({
    required this.blockIndex,
    required this.blockLabel,
    required this.defaultCategory,
    required this.onRandomize,
  });

  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  ExerciseCategory? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _categoryFilter = widget.defaultCategory;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _createCustom() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const CustomExerciseScreen()),
    );
    if (mounted) setState(() {}); // pick up the newly-created exercise
  }

  void _add(Exercise ex) {
    context
        .read<CurrentWorkoutService>()
        .addExerciseToDraftBlock(widget.blockIndex, ex);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Added: ${ex.name}'),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ExerciseService>();
    final workoutSvc = context.watch<CurrentWorkoutService>();
    final usedIds =
        workoutSvc.draftPlan?.allExercises.map((e) => e.id).toSet() ?? {};

    var pool = _query.isEmpty ? service.all : service.search(_query);
    if (_categoryFilter != null) {
      pool = pool.where((e) => e.category == _categoryFilter).toList();
    }
    pool = pool.where((e) => !usedIds.contains(e.id)).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: context.f3bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: context.f3divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Add to ${widget.blockLabel}',
                  style: TextStyle(
                      color: context.f3textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onRandomize();
                    },
                    icon: const Icon(Icons.shuffle_rounded, size: 16),
                    label: const Text('RANDOMIZE'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _createCustom,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('WRITE CUSTOM'),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search for an exercise...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [null, ...ExerciseCategory.values].map((cat) {
                  final selected = _categoryFilter == cat;
                  final color = cat == null
                      ? context.f3textSecondary
                      : F3Colors.forCategory(cat.name);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat?.displayName ?? 'All'),
                      selected: selected,
                      selectedColor: color.withValues(alpha: 0.25),
                      onSelected: (_) => setState(() => _categoryFilter = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            Divider(color: context.f3divider),
            Expanded(
              child: pool.isEmpty
                  ? Center(
                      child: Text('No matching exercises.',
                          style: TextStyle(color: context.f3textMuted)),
                    )
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: pool.length,
                      itemBuilder: (context, i) {
                        final ex = pool[i];
                        final color = F3Colors.forCategory(ex.category.name);
                        return ListTile(
                          onTap: () => _add(ex),
                          leading: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          title: Text(ex.name,
                              style: TextStyle(color: context.f3textPrimary)),
                          subtitle: Text(
                              '${ex.category.displayName} · ${ex.intensity.displayName}'
                              '${ex.secondsPerSet != null ? ' · ~${ex.secondsPerSet}s/set' : ''}',
                              style: TextStyle(
                                  color: context.f3textSecondary,
                                  fontSize: 12)),
                          trailing: Icon(Icons.add_circle_outline_rounded,
                              color: color),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
