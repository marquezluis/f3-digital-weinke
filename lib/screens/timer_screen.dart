// lib/screens/timer_screen.dart
// Live Digital Weinke screen.
// Features: phase-aware timer, exercise display (swipeable), rep counter overlay,
// EMOM/Tabata interval overlay, confetti on session completion, TTS callouts.

import 'dart:async';
import 'dart:math' show pi;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/timer_state.dart';
import '../models/workout_plan.dart';
import '../services/current_workout_service.dart';
import '../services/exercise_service.dart';
import '../services/settings_service.dart';
import '../services/timer_service.dart';
import '../services/workout_generator.dart';
import '../theme/app_theme.dart';
import '../widgets/phase_segment_bar.dart';
import '../widgets/save_session_sheet.dart';
import '../models/workout_history.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  BootcampPhase? _lastPhase;
  String? _lastExerciseName;
  int? _lastExIdx;
  bool _completedHandled = false;
  bool _halfwayAlerted = false;
  String? _lastPlanId; // tracks plan changes to re-seed the timer

  // Confetti
  late final ConfettiController _confettiCtrl;

  // TTS
  final FlutterTts _tts = FlutterTts();
  bool _ttsMuted = false;

  // Rest timer between exercises (opt-in)
  bool _restEnabled = false;
  int _restCountdown = 0;
  static const int _restDurationSecs = 15;
  Timer? _restTimer;

  // Auto-advance mode: advance exercise every N seconds
  bool _autoAdvance = false;
  static const int _autoAdvanceSecs = 180; // 3 min per exercise
  int? _autoAdvanceElapsedAtLastAdvance;

  void _startRest() {
    _restTimer?.cancel();
    setState(() => _restCountdown = _restDurationSecs);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_restCountdown <= 1) {
        t.cancel();
        setState(() => _restCountdown = 0);
      } else {
        setState(() => _restCountdown--);
      }
    });
  }

  void _cancelRest() {
    _restTimer?.cancel();
    if (mounted) setState(() => _restCountdown = 0);
  }

  // Rep counter
  bool _showRepCounter = false;
  int _repCount = 0;

  // EMOM/Tabata overlay
  bool _showInterval = false;
  int _intervalWorkSecs = 20;
  int _intervalRestSecs = 10;
  bool _intervalRunning = false;
  bool _intervalIsWork = true;
  int _intervalSecsLeft = 20;
  int _intervalRound = 1;
  int _totalIntervalRounds = 8;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 4));
    _initTts();
    // Apply saved TTS voice after first frame (context is safe here).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final voice = context.read<SettingsService>().ttsVoice;
      if (voice.isNotEmpty) {
        _tts.setVoice({'name': voice, 'locale': 'en-US'});
      }
    });
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.72);
    await _tts.setPitch(1.0);
  }


  Future<void> _speak(String text) async {
    final voiceOn = context.read<SettingsService>().voiceEnabled;
    if (!voiceOn || _ttsMuted) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  String _phaseAnnouncement(BootcampPhase phase) {
    switch (phase) {
      case BootcampPhase.disclaimer:
        return 'F3 Nation. Six core principles. Disclaimer.';
      case BootcampPhase.warmup:
        return 'Starting Warm-O-Rama. Mosey up!';
      case BootcampPhase.thang:
        return 'The Thang. Let\'s get some!';
      case BootcampPhase.mary:
        return 'Mary time. Core work, PAX!';
      case BootcampPhase.cot:
        return 'Circle of Trust. Bring it in!';
    }
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _tts.stop();
    _stopInterval();
    _restTimer?.cancel();
    super.dispose();
  }

  void _stopInterval() {
    _intervalRunning = false;
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
    _WorkoutSummarySheet.show(context, plan: plan, onSave: (String rolledPax) {
      SaveSessionSheet.show(context, blocks: blocks, initialPax: rolledPax);
    });
  }

  List<Exercise> _exercisesForPhase(BootcampPhase phase, WorkoutPlan plan) {
    return plan.blocks
        .where((b) {
          switch (phase) {
            case BootcampPhase.disclaimer:
              return false;
            case BootcampPhase.warmup:
              return b.category == ExerciseCategory.warmup;
            case BootcampPhase.thang:
              return b.category == ExerciseCategory.bodyweight ||
                  b.category == ExerciseCategory.coupon;
            case BootcampPhase.mary:
              return b.category == ExerciseCategory.mary;
            case BootcampPhase.cot:
              return false;
          }
        })
        .expand((b) => List.generate(b.rounds, (_) => b.exercises).expand((e) => e))
        .toList();
  }

  void _swapExercise(Exercise exercise, WorkoutPlan plan) {
    final generator = WorkoutGenerator(context.read<ExerciseService>());
    final newEx = generator.swapExercise(exercise, plan);
    context
        .read<CurrentWorkoutService>()
        .swapLiveExercise(plan.withSwappedExercise(exercise, newEx));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Swapped for: ${newEx.name}'),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CurrentWorkoutService, TimerService>(
      builder: (context, workoutSvc, timerService, _) {
        final plan = workoutSvc.livePlan;

        if (plan == null) {
          return Scaffold(
            backgroundColor: context.f3bg,
            appBar: AppBar(
              title: const Text('Q Mode'),
              backgroundColor: context.f3bg,
            ),
            body: _EmptyState(
              onGoToWeinke: () => context.read<ValueNotifier<int>>().value = 1,
            ),
          );
        }

        final state = timerService.state;

        // Seed timer with plan-aware durations when plan changes and timer is idle.
        if (plan.id != _lastPlanId && !state.isRunning) {
          _lastPlanId = plan.id;
          _halfwayAlerted = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.read<TimerService>().resetWithPlan(plan);
          });
        }

        // Phase change detection — reset exercise, haptic, TTS.
        if (_lastPhase != null && _lastPhase != state.currentPhase) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              workoutSvc.resetExerciseIndex();
              HapticFeedback.heavyImpact();
              _repCount = 0;
              _cancelRest();
              _speak(_phaseAnnouncement(state.currentPhase));
            }
          });
        }
        _lastPhase = state.currentPhase;

        // Halfway alert — fires once at the midpoint of the total session.
        if (!_halfwayAlerted && !state.isFinished) {
          final totalSecs = timerService.initialTotalSeconds;
          final elapsedSecs = totalSecs - state.totalRemainingSeconds;
          if (elapsedSecs >= totalSecs ~/ 2) {
            _halfwayAlerted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                HapticFeedback.heavyImpact();
                _speak('Halfway there, PAX. Keep pushing!');
              }
            });
          }
        }

        // Session complete — confetti + TTS (once).
        if (state.isFinished && !_completedHandled) {
          _completedHandled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _confettiCtrl.play();
              _speak('Outstanding effort, PAX. Session complete!');
            }
          });
        }

        final exercises = _exercisesForPhase(state.currentPhase, plan);
        final int exIdx = workoutSvc.currentExerciseIndex
            .clamp(0, exercises.isEmpty ? 0 : exercises.length - 1);
        final Exercise? currentExercise =
            exercises.isNotEmpty ? exercises[exIdx] : null;

        // Detect exercise index change (manual or auto).
        final exIndexChanged = _lastExIdx != null &&
            _lastExIdx != exIdx &&
            _lastPhase == state.currentPhase;
        if (exIndexChanged && !state.isFinished && _restEnabled) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _startRest();
          });
        }
        if (exIndexChanged || _lastPhase != state.currentPhase) {
          // Reset auto-advance baseline whenever exercise or phase changes.
          final elapsed = TimerState.totalBootcampSeconds - state.totalRemainingSeconds;
          _autoAdvanceElapsedAtLastAdvance = elapsed;
        }
        _lastExIdx = exIdx;

        // Auto-advance: fire when enough time has passed since last advance.
        if (_autoAdvance && !state.isFinished && exercises.isNotEmpty && _restCountdown == 0) {
          final elapsed = TimerState.totalBootcampSeconds - state.totalRemainingSeconds;
          _autoAdvanceElapsedAtLastAdvance ??= elapsed;
          if (elapsed - _autoAdvanceElapsedAtLastAdvance! >= _autoAdvanceSecs) {
            _autoAdvanceElapsedAtLastAdvance = elapsed;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) workoutSvc.nextExercise(exercises.length);
            });
          }
        }

        // TTS on exercise change.
        final currentName = currentExercise?.name;
        if (currentName != null && currentName != _lastExerciseName) {
          final isFirst = _lastExerciseName == null;
          _lastExerciseName = currentName;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _speak(isFirst
                  ? 'First up: $currentName'
                  : 'Next exercise: $currentName');
            }
          });
        }

        return Scaffold(
          backgroundColor: context.f3bg,
          appBar: AppBar(
            title: const Text('Q Mode'),
            backgroundColor: context.f3bg,
            actions: [
              // EMOM/Tabata toggle
              IconButton(
                icon: Icon(
                  Icons.timer_outlined,
                  color: _showInterval ? F3Colors.accent : null,
                ),
                tooltip: 'EMOM / Tabata overlay',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _showInterval = !_showInterval;
                    if (!_showInterval) _stopInterval();
                  });
                },
              ),
              // Rest timer toggle (opt-in)
              IconButton(
                icon: Icon(
                  Icons.self_improvement_rounded,
                  color: _restEnabled ? F3Colors.accent : null,
                ),
                tooltip: _restEnabled ? 'Rest between exercises ON' : 'Rest between exercises OFF',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _restEnabled = !_restEnabled;
                    if (!_restEnabled) _cancelRest();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(_restEnabled
                        ? 'Rest timer ON — ${_restDurationSecs}s between exercises'
                        : 'Rest timer OFF'),
                    duration: const Duration(seconds: 2),
                  ));
                },
              ),
              // TTS mute toggle
              if (context.read<SettingsService>().voiceEnabled)
                IconButton(
                  icon: Icon(
                    _ttsMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    color: _ttsMuted ? context.f3textMuted : null,
                  ),
                  tooltip: _ttsMuted ? 'Unmute voice' : 'Mute voice',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _ttsMuted = !_ttsMuted);
                    if (_ttsMuted) _tts.stop();
                  },
                ),
              // Auto-advance toggle
              IconButton(
                icon: Icon(
                  Icons.skip_next_rounded,
                  color: _autoAdvance ? F3Colors.accent : null,
                ),
                tooltip: _autoAdvance
                    ? 'Auto-advance ON (3 min/exercise)'
                    : 'Auto-advance OFF',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _autoAdvance = !_autoAdvance;
                    _autoAdvanceElapsedAtLastAdvance = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(_autoAdvance
                        ? 'Auto-advance ON — exercises advance every 3 min'
                        : 'Auto-advance OFF'),
                    duration: const Duration(seconds: 2),
                  ));
                },
              ),
              // Rep counter toggle
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline_rounded,
                  color: _showRepCounter ? F3Colors.accent : null,
                ),
                tooltip: 'Rep counter',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _showRepCounter = !_showRepCounter;
                    if (!_showRepCounter) _repCount = 0;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.save_rounded),
                tooltip: 'Save session',
                onPressed: () => _saveSession(plan),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Phase color background wash
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        state.currentPhase.color.withValues(alpha: 0.07),
                        context.f3bg,
                      ],
                      stops: const [0.0, 0.45],
                    ),
                  ),
                ),
              ),
              // Main content column
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: PhaseSegmentBar(
                        state: state,
                        onPhaseTap: (phase) {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: context.f3card,
                              title: Text('Jump to ${phase.displayName}?',
                                  style: TextStyle(
                                      color: context.f3textPrimary)),
                              content: Text(
                                'Skip to ${phase.displayName} now?',
                                style: TextStyle(
                                    color: context.f3textSecondary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: phase.color,
                                    minimumSize: const Size(80, 40),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    timerService.jumpToPhase(phase);
                                    workoutSvc.resetExerciseIndex();
                                  },
                                  child: const Text('GO',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _PhaseHeader(state: state),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _PhaseTimer(state: state),
                    ),

                    // EMOM/Tabata overlay (inline)
                    if (_showInterval)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: _IntervalPanel(
                          workSecs: _intervalWorkSecs,
                          restSecs: _intervalRestSecs,
                          totalRounds: _totalIntervalRounds,
                          isRunning: _intervalRunning,
                          isWork: _intervalIsWork,
                          secsLeft: _intervalSecsLeft,
                          round: _intervalRound,
                          onWorkChanged: (v) =>
                              setState(() => _intervalWorkSecs = v),
                          onRestChanged: (v) =>
                              setState(() => _intervalRestSecs = v),
                          onRoundsChanged: (v) =>
                              setState(() => _totalIntervalRounds = v),
                          onStartStop: _toggleInterval,
                          onReset: _resetInterval,
                        ),
                      ),

                    // Session complete kudos
                    if (state.isFinished)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: _SessionCompleteCard(
                            onSave: () => _saveSession(plan)),
                      ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _restCountdown > 0
                            ? _RestCard(
                                seconds: _restCountdown,
                                color: state.currentPhase.color,
                                onSkip: _cancelRest,
                              )
                            : _ExerciseDisplay(
                          phase: state.currentPhase,
                          exercises: exercises,
                          currentIndex: exIdx,
                          onSwap: currentExercise != null
                              ? () => _swapExercise(currentExercise, plan)
                              : null,
                          nextExercise: exIdx + 1 < exercises.length
                              ? exercises[exIdx + 1]
                              : null,
                          getExerciseNote: (id) {
                            for (final b in plan.blocks) {
                              final n = b.noteFor(id);
                              if (n.isNotEmpty) return n;
                            }
                            return '';
                          },
                        ),
                      ),
                    ),

                    // Rep counter inline bar
                    if (_showRepCounter)
                      _RepCounterBar(
                        count: _repCount,
                        onIncrement: () {
                          HapticFeedback.lightImpact();
                          setState(() => _repCount++);
                        },
                        onReset: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _repCount = 0);
                        },
                      ),

                    _ControlBar(
                      timerService: timerService,
                      workoutSvc: workoutSvc,
                      state: state,
                      exercisesInPhase: exercises.length,
                      currentExerciseIndex: exIdx,
                      onCancelRest: _cancelRest,
                      onEmergencyMary: () {
                        timerService.jumpToMary();
                        workoutSvc.resetExerciseIndex();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Emergency Mary activated!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Confetti burst at top-center
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiCtrl,
                  blastDirection: pi / 2,
                  numberOfParticles: 40,
                  gravity: 0.2,
                  emissionFrequency: 0.06,
                  colors: const [
                    F3Colors.accent,
                    F3Colors.phaseThang,
                    F3Colors.phaseMary,
                    Colors.white,
                    Colors.yellow,
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleInterval() {
    if (_intervalRunning) {
      _stopInterval();
      setState(() {});
    } else {
      _intervalRunning = true;
      _intervalIsWork = true;
      _intervalSecsLeft = _intervalWorkSecs;
      _speak('Interval start. Work!');
      _runIntervalTick();
    }
  }

  void _resetInterval() {
    _stopInterval();
    setState(() {
      _intervalIsWork = true;
      _intervalSecsLeft = _intervalWorkSecs;
      _intervalRound = 1;
    });
  }

  void _runIntervalTick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || !_intervalRunning) return;
      
      bool playRest = false;
      bool playWork = false;
      bool playComplete = false;

      setState(() {
        _intervalSecsLeft--;
        if (_intervalSecsLeft <= 0) {
          if (_intervalIsWork) {
            _intervalIsWork = false;
            _intervalSecsLeft = _intervalRestSecs;
            playRest = true;
          } else {
            _intervalRound++;
            if (_intervalRound > _totalIntervalRounds) {
              _intervalRunning = false;
              _intervalRound = _totalIntervalRounds;
              playComplete = true;
            } else {
              _intervalIsWork = true;
              _intervalSecsLeft = _intervalWorkSecs;
              playWork = true;
            }
          }
        }
      });

      if (playRest) {
        _speak('Rest!');
        HapticFeedback.heavyImpact();
      } else if (playComplete) {
        _speak('Interval complete!');
      } else if (playWork) {
        _speak('Round $_intervalRound. Work!');
        HapticFeedback.heavyImpact();
      }

      if (_intervalRunning) _runIntervalTick();
    });
  }
}

// ─── Rep counter bar ──────────────────────────────────────────────────────────

class _RepCounterBar extends StatelessWidget {
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onReset;

  const _RepCounterBar({
    required this.count,
    required this.onIncrement,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.f3elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: F3Colors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.repeat_rounded, size: 18, color: F3Colors.accent),
        const SizedBox(width: 10),
        const Text('REPS',
            style: TextStyle(
                color: F3Colors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
        const SizedBox(width: 12),
        Text(
          '$count',
          style: TextStyle(
              color: context.f3textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900),
        ),
        const Spacer(),
        TextButton(
          onPressed: onReset,
          child: Text('RESET',
              style: TextStyle(
                  color: context.f3textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onIncrement,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: F3Colors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ]),
    );
  }
}

// ─── EMOM / Tabata interval panel ────────────────────────────────────────────

class _IntervalPanel extends StatelessWidget {
  final int workSecs;
  final int restSecs;
  final int totalRounds;
  final bool isRunning;
  final bool isWork;
  final int secsLeft;
  final int round;
  final void Function(int) onWorkChanged;
  final void Function(int) onRestChanged;
  final void Function(int) onRoundsChanged;
  final VoidCallback onStartStop;
  final VoidCallback onReset;

  const _IntervalPanel({
    required this.workSecs,
    required this.restSecs,
    required this.totalRounds,
    required this.isRunning,
    required this.isWork,
    required this.secsLeft,
    required this.round,
    required this.onWorkChanged,
    required this.onRestChanged,
    required this.onRoundsChanged,
    required this.onStartStop,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWork ? F3Colors.phaseThang : F3Colors.phaseMary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(children: [
        Row(children: [
          Icon(Icons.timer_rounded, size: 16, color: context.f3textMuted),
          const SizedBox(width: 6),
          Text('EMOM / TABATA',
              style: TextStyle(
                  color: context.f3textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          const Spacer(),
          if (isRunning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${isWork ? 'WORK' : 'REST'} · Rd $round/$totalRounds',
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
        ]),
        if (isRunning) ...[
          const SizedBox(height: 8),
          Text(
            _fmt(secsLeft),
            style: TextStyle(
                color: color,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: 3),
          ),
          const SizedBox(height: 8),
        ] else ...[
          const SizedBox(height: 10),
          Row(children: [
            _SpinBox(
                label: 'WORK',
                value: workSecs,
                min: 5,
                max: 300,
                step: 5,
                onChanged: onWorkChanged),
            const SizedBox(width: 8),
            _SpinBox(
                label: 'REST',
                value: restSecs,
                min: 5,
                max: 120,
                step: 5,
                onChanged: onRestChanged),
            const SizedBox(width: 8),
            _SpinBox(
                label: 'ROUNDS',
                value: totalRounds,
                min: 1,
                max: 20,
                step: 1,
                onChanged: onRoundsChanged),
          ]),
          const SizedBox(height: 8),
        ],
        Row(children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.f3textSecondary,
                  side: BorderSide(color: context.f3divider),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: onStartStop,
                icon: Icon(
                    isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 18),
                label: Text(isRunning ? 'PAUSE' : 'START',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  String _fmt(int secs) =>
      '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}';
}

class _SpinBox extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final void Function(int) onChanged;

  const _SpinBox({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(label,
            style: TextStyle(
                color: context.f3textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          InkWell(
            onTap: value > min ? () => onChanged(value - step) : null,
            borderRadius: BorderRadius.circular(4),
            child: Icon(Icons.remove_rounded,
                size: 18, color: context.f3textSecondary),
          ),
          const SizedBox(width: 4),
          Text('$value',
              style: TextStyle(
                  color: context.f3textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          InkWell(
            onTap: value < max ? () => onChanged(value + step) : null,
            borderRadius: BorderRadius.circular(4),
            child: Icon(Icons.add_rounded,
                size: 18, color: context.f3textSecondary),
          ),
        ]),
      ]),
    );
  }
}

// ─── Empty state (no live plan yet) ───────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onGoToWeinke;
  const _EmptyState({required this.onGoToWeinke});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined,
                color: context.f3textMuted, size: 72),
            const SizedBox(height: 20),
            Text(
              'BUILD A WEINKE FIRST',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.f3textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Draft your beatdown on the Weinke tab, then tap\n'
              '"START WORKOUT" to load it here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.f3textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onGoToWeinke,
              style: ElevatedButton.styleFrom(
                backgroundColor: F3Colors.accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.fitness_center_rounded),
              label: const Text('GO TO WEINKE',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Phase header ─────────────────────────────────────────────────────────────

class _PhaseHeader extends StatelessWidget {
  final TimerState state;
  const _PhaseHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final phase = state.currentPhase;
    final next = phase.next;
    return Row(
      children: [
        Container(
          width: 5,
          height: 28,
          decoration: BoxDecoration(
            color: phase.color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                phase.displayName,
                style: TextStyle(
                  color: phase.color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                phase.subtitle,
                style: TextStyle(
                  color: context.f3textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (next != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: next.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: next.color.withValues(alpha: 0.4)),
            ),
            child: Text(
              'Up: ${next.displayName}',
              style: TextStyle(
                color: next.color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Phase countdown digits ───────────────────────────────────────────────────

class _PhaseTimer extends StatelessWidget {
  final TimerState state;
  const _PhaseTimer({required this.state});

  @override
  Widget build(BuildContext context) {
    final isFinished = state.isFinished;
    final height = MediaQuery.sizeOf(context).height;
    final timerFontSize = height < 700 ? 54.0 : 72.0;
    return Column(
      children: [
        Text(
          isFinished ? '00:00' : state.formattedPhaseRemaining,
          style: TextStyle(
            color: isFinished
                ? F3Colors.phaseThang.withValues(alpha: 0.4)
                : state.currentPhase.color,
            fontSize: timerFontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isFinished
              ? 'SESSION COMPLETE'
              : 'total: ${state.formattedTotalRemaining}',
          style: TextStyle(
            color: context.f3textMuted,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ─── Exercise display ─────────────────────────────────────────────────────────

class _ExerciseDisplay extends StatefulWidget {
  final BootcampPhase phase;
  final List<Exercise> exercises;
  final int currentIndex;
  final VoidCallback? onSwap;
  final Exercise? nextExercise;
  final String Function(String exerciseId)? getExerciseNote;

  const _ExerciseDisplay({
    required this.phase,
    required this.exercises,
    required this.currentIndex,
    required this.onSwap,
    this.nextExercise,
    this.getExerciseNote,
  });

  @override
  State<_ExerciseDisplay> createState() => _ExerciseDisplayState();
}

class _ExerciseDisplayState extends State<_ExerciseDisplay> {
  PageController? _pageCtrl;
  int? _lastIndex;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: widget.currentIndex);
    _lastIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(_ExerciseDisplay old) {
    super.didUpdateWidget(old);
    if (widget.currentIndex != _lastIndex) {
      _lastIndex = widget.currentIndex;
      _pageCtrl?.animateToPage(
        widget.currentIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _pageCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = widget.phase;
    final exercises = widget.exercises;
    final currentIndex = widget.currentIndex;
    final onSwap = widget.onSwap;

    if (phase == BootcampPhase.disclaimer) return const _DisclaimerCard();
    if (phase == BootcampPhase.cot) return const _COTCard();

    if (exercises.isEmpty) {
      return Center(
        child: Text(
          'No exercises for this phase.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      children: [
        _ExerciseDots(
          total: exercises.length,
          current: currentIndex,
          color: phase.color,
        ),
        const SizedBox(height: 4),
        if (exercises.length > 1)
          Text(
            'Swipe to browse exercises',
            style: TextStyle(
              color: context.f3textMuted,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: exercises.length,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              final workoutSvc = context.read<CurrentWorkoutService>();
              if (i > currentIndex) {
                workoutSvc.nextExercise(exercises.length);
              } else if (i < currentIndex) {
              workoutSvc.previousExercise();
              }
            },
            itemBuilder: (_, idx) {
              final pageEx = exercises[idx];
              final exNote = widget.getExerciseNote?.call(pageEx.id) ?? '';
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: phase.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: phase.color.withValues(alpha: 0.55),
                    width: 2,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (pageEx.equipment == Equipment.coupon) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: F3Colors.catCoupon.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: F3Colors.catCoupon.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fitness_center_rounded,
                                  size: 14, color: F3Colors.catCoupon),
                              SizedBox(width: 6),
                              Text(
                                'COUPON REQUIRED',
                                style: TextStyle(
                                  color: F3Colors.catCoupon,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        pageEx.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: phase.color,
                                  fontSize: _nameFontSize(pageEx.name),
                                  shadows: [
                                    Shadow(
                                      color: phase.color.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                      ),
                      if (exNote.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: F3Colors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: F3Colors.accent.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sticky_note_2_rounded,
                                  size: 13, color: F3Colors.accent),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  exNote,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: F3Colors.accent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: F3Colors.forIntensity(pageEx.intensity.name)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pageEx.intensity.displayName.toUpperCase(),
                          style: TextStyle(
                            color: F3Colors.forIntensity(pageEx.intensity.name),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      if (pageEx.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          pageEx.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 16),
                      const _ExerciseDemo(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (onSwap != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: onSwap,
              icon: const Icon(Icons.swap_horiz_rounded, size: 20),
              label: const Text('SWAP EXERCISE'),
            ),
          ),
        ],
        if (widget.nextExercise != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: context.f3elevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.f3divider),
            ),
            child: Row(children: [
              Icon(Icons.arrow_forward_rounded,
                  size: 14, color: context.f3textMuted),
              const SizedBox(width: 8),
              Text('NEXT',
                  style: TextStyle(
                      color: context.f3textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.nextExercise!.name,
                  style: TextStyle(
                      color: context.f3textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  double _nameFontSize(String name) {
    if (name.length > 24) return 34;
    if (name.length > 18) return 42;
    if (name.length > 12) return 54;
    return 68;
  }
}

// ─── Interactive Exercise Demo Placeholder ──────────────────────────────────

class _ExerciseDemo extends StatefulWidget {
  const _ExerciseDemo();

  @override
  State<_ExerciseDemo> createState() => _ExerciseDemoState();
}

class _ExerciseDemoState extends State<_ExerciseDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _showDemo = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton.icon(
          onPressed: () {
            final reduced = context.read<SettingsService>().reducedMotion;
            setState(() => _showDemo = !_showDemo);
            if (_showDemo && !reduced) {
              _controller.repeat(reverse: true);
            } else {
              _controller.stop();
            }
          },
          icon: Icon(
            _showDemo
                ? Icons.visibility_off_rounded
                : Icons.play_circle_fill_rounded,
          ),
          label: Text(_showDemo ? 'HIDE DEMO' : 'VIEW DEMO'),
          style: TextButton.styleFrom(foregroundColor: F3Colors.accent),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
          child: !_showDemo
              ? const SizedBox.shrink()
              : Container(
                  width: double.infinity,
                  height: 140,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: context.f3elevated.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: F3Colors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fitness_center_rounded,
                              size: 42, color: context.f3textSecondary),
                          SizedBox(height: 12),
                          Text(
                            'Animation Placeholder\n(Ready for local GIFs)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.f3textMuted,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Session complete kudos card ──────────────────────────────────────────────

class _SessionCompleteCard extends StatelessWidget {
  final VoidCallback onSave;
  const _SessionCompleteCard({required this.onSave});

  static const _kudos = [
    'OUTSTANDING EFFORT, PAX.',
    "THAT'S HOW IT'S DONE.",
    'NO MAN LEFT BEHIND.',
    'THE IRON SHARPENS IRON.',
    'WELL DONE, BROTHER.',
    'LEAVE NO MAN WHERE YOU FOUND HIM.',
  ];

  @override
  Widget build(BuildContext context) {
    final msg = _kudos[DateTime.now().millisecond % _kudos.length];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: F3Colors.phaseThang.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: F3Colors.phaseThang.withValues(alpha: 0.4)),
      ),
      child: Column(children: [
        const Icon(Icons.emoji_events_rounded,
            color: F3Colors.phaseThang, size: 32),
        const SizedBox(height: 6),
        Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.f3textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: F3Colors.phaseThang,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('SAVE SESSION',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ]),
    );
  }
}

class _ExerciseDots extends StatelessWidget {
  final int total;
  final int current;
  final Color color;

  const _ExerciseDots(
      {required this.total, required this.current, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return Container(
          width: active ? 18 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─── Disclaimer card ──────────────────────────────────────────────────────────

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: F3Colors.phaseDisclaimer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: F3Colors.phaseDisclaimer.withValues(alpha: 0.4), width: 1.5),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel_rounded,
                color: F3Colors.phaseDisclaimer, size: 34),
            SizedBox(height: 12),
            Text(
              'DISCLAIMER',
              style: TextStyle(
                color: context.f3textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '"I am not a professional trainer. This is a free workout. '
              'You are responsible for your own health and safety. '
              'Modify any exercise as needed. F3 is peer-led and '
              'participation is voluntary."',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.f3textSecondary,
                fontSize: 15,
                height: 1.45,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Read this aloud before the warm-up begins.',
              style: TextStyle(color: context.f3textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── COT card ─────────────────────────────────────────────────────────────────

class _COTCard extends StatelessWidget {
  const _COTCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: F3Colors.phaseCOT.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: F3Colors.phaseCOT.withValues(alpha: 0.4), width: 1.5),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_rounded,
                color: F3Colors.phaseCOT, size: 34),
            const SizedBox(height: 12),
            Text(
              'CIRCLE OF TRUST',
              style: TextStyle(
                color: context.f3textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            ...[
              '1. COUNT-O-RAMA — Count all PAX aloud.',
              '2. NAME-O-RAMA — Each man states his name.',
              '3. FNG NAMING — Welcome and name any First Time Guy.',
              '4. ANNOUNCEMENTS — Upcoming F3 events.',
              '5. CLOSING WORD — Brief prayer or word of wisdom.',
            ].map(
              (step) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        step,
                        style: TextStyle(
                          color: context.f3textSecondary,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Control bar ──────────────────────────────────────────────────────────────

class _ControlBar extends StatelessWidget {
  final TimerService timerService;
  final CurrentWorkoutService workoutSvc;
  final TimerState state;
  final int exercisesInPhase;
  final int currentExerciseIndex;
  final VoidCallback onCancelRest;
  final VoidCallback onEmergencyMary;

  const _ControlBar({
    required this.timerService,
    required this.workoutSvc,
    required this.state,
    required this.exercisesInPhase,
    required this.currentExerciseIndex,
    required this.onCancelRest,
    required this.onEmergencyMary,
  });

  void _extend(BuildContext context) {
    timerService.extendCurrentPhase(60);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('+1 min added to current phase'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canEmergency = !state.isFinished &&
        state.currentPhase != BootcampPhase.mary &&
        state.currentPhase != BootcampPhase.cot &&
        (state.isRunning || state.isPaused);

    final bool canPrevious = (state.isRunning || state.isPaused) &&
        (currentExerciseIndex > 0 || state.currentPhase != BootcampPhase.disclaimer);

    final bool canNextPhase = state.isRunning || state.isPaused;
    final bool canExtend = !state.isFinished && (state.isRunning || state.isPaused);

    return Container(
      color: context.f3card,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canEmergency)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: F3Colors.accent,
                    side: const BorderSide(color: F3Colors.accent, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: context.f3card,
                        title: Text('Emergency Mary',
                            style: TextStyle(color: context.f3textPrimary)),
                        content: Text(
                          'Skip to Mary now? This cannot be undone.',
                          style: TextStyle(color: context.f3textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: F3Colors.accent,
                              minimumSize: const Size(80, 40),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              onEmergencyMary();
                            },
                            child: const Text('GO',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.warning_rounded, size: 18),
                  label: const Text('EMERGENCY MARY',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
            ),
          if (canExtend)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                height: 36,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.f3textSecondary,
                    side: BorderSide(color: context.f3divider),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => _extend(context),
                  icon: const Icon(Icons.more_time_rounded, size: 16),
                  label: const Text('+1 MIN',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _ControlButton(
                  icon: Icons.skip_previous_rounded,
                  label: 'Previous',
                  color: canPrevious ? context.f3textSecondary : context.f3textMuted,
                  onTap: canPrevious ? () {
                    if (!workoutSvc.previousExercise()) {
                      timerService.previousPhase();
                      workoutSvc.resetExerciseIndex();
                    }
                  } : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _PrimaryPlayButton(
                    state: state, timerService: timerService),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _ControlButton(
                  icon: Icons.skip_next_rounded,
                  label: 'Next',
                  color: canNextPhase
                      ? context.f3textSecondary
                      : context.f3textMuted,
                  onTap: canNextPhase
                      ? () {
                          onCancelRest();
                          if (!workoutSvc.nextExercise(exercisesInPhase)) {
                            timerService.advancePhase();
                            workoutSvc.resetExerciseIndex();
                          }
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryPlayButton extends StatelessWidget {
  final TimerState state;
  final TimerService timerService;
  const _PrimaryPlayButton({required this.state, required this.timerService});

  @override
  Widget build(BuildContext context) {
    final bool disabled = state.isFinished;
    final bool isRunning = state.isRunning;
    final VoidCallback? action = disabled
        ? null
        : (isRunning
            ? timerService.pause
            : state.isPaused
                ? timerService.resume
                : timerService.start);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: disabled
            ? context.f3textMuted.withValues(alpha: 0.2)
            : F3Colors.accent,
        child: InkWell(
          onTap: action == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  action();
                },
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: disabled
                  ? []
                  : [
                      BoxShadow(
                        color: F3Colors.accent.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: disabled ? context.f3textMuted : Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    disabled
                        ? 'DONE'
                        : isRunning
                            ? 'PAUSE'
                            : state.isPaused
                                ? 'RESUME'
                                : 'START',
                    style: TextStyle(
                      color: disabled ? context.f3textMuted : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: context.f3elevated,
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.f3divider),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Post-workout summary sheet ───────────────────────────────────────────────

class _WorkoutSummarySheet extends StatefulWidget {
  final WorkoutPlan plan;
  final void Function(String) onSave;

  const _WorkoutSummarySheet({required this.plan, required this.onSave});

  static void show(BuildContext context,
      {required WorkoutPlan plan, required void Function(String) onSave}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WorkoutSummarySheet(plan: plan, onSave: onSave),
    );
  }

  @override
  State<_WorkoutSummarySheet> createState() => _WorkoutSummarySheetState();
}

class _WorkoutSummarySheetState extends State<_WorkoutSummarySheet> {
  String _rolledPax = '';

  void _showRollCall() {
    final ctrl = TextEditingController(text: _rolledPax);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.f3card,
        title: Text('NAME-O-RAMA',
            style: TextStyle(
                color: context.f3textPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          style: TextStyle(color: context.f3textPrimary),
          decoration: InputDecoration(
            hintText: 'Dredd, Mayhem, Roscoe…',
            hintStyle: TextStyle(color: context.f3textMuted),
            labelText: 'PAX Names (comma-separated)',
            labelStyle: TextStyle(color: context.f3textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _rolledPax = ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalExercises = widget.plan.allExercises.length;
    final blocks = widget.plan.blocks;
    final totalMins = widget.plan.totalMinutes;

    final paxCount = _rolledPax.isEmpty
        ? 0
        : _rolledPax.split(',').where((s) => s.trim().isNotEmpty).length;

    return Container(
      decoration: BoxDecoration(
        color: context.f3bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
                color: context.f3divider,
                borderRadius: BorderRadius.circular(2)),
          ),
          const Icon(Icons.emoji_events_rounded,
              color: F3Colors.accent, size: 40),
          const SizedBox(height: 10),
          Text('BEATDOWN COMPLETE',
              style: TextStyle(
                  color: context.f3textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text('Nice work out there, PAX.',
              style: TextStyle(color: context.f3textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            _SummaryStat(
              icon: Icons.timer_rounded,
              value: '$totalMins',
              label: 'MINUTES',
              color: F3Colors.phaseThang,
            ),
            _SummaryStat(
              icon: Icons.fitness_center_rounded,
              value: '$totalExercises',
              label: 'EXERCISES',
              color: F3Colors.phaseMary,
            ),
            _SummaryStat(
              icon: Icons.view_module_rounded,
              value: '${blocks.length}',
              label: 'BLOCKS',
              color: F3Colors.phaseWarmup,
            ),
          ]),
          const SizedBox(height: 16),
          // ── Name-O-Rama roll call ─────────────────────────────────────
          OutlinedButton.icon(
            onPressed: _showRollCall,
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  paxCount > 0 ? F3Colors.accent : context.f3textSecondary,
              side: BorderSide(
                  color: paxCount > 0 ? F3Colors.accent : context.f3divider),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(double.infinity, 44),
            ),
            icon: Icon(
                paxCount > 0
                    ? Icons.how_to_reg_rounded
                    : Icons.group_add_rounded,
                size: 18),
            label: Text(paxCount > 0
                ? 'PAX ROLLED: $paxCount  (tap to edit)'
                : 'NAME-O-RAMA — ROLL CALL'),
          ),
          const SizedBox(height: 16),
          ...blocks.map((b) {
            final color = F3Colors.forCategory(b.category.name);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(b.label,
                      style: TextStyle(
                          color: context.f3textPrimary,
                          fontWeight: FontWeight.w600)),
                ),
                Text(
                  '${b.exercises.length} ex · ${b.durationMinutes * b.rounds} min${b.rounds > 1 ? ' (${b.rounds}×)' : ''}',
                  style: TextStyle(
                      color: context.f3textMuted, fontSize: 12),
                ),
              ]),
            );
          }),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.f3textSecondary,
                  side: BorderSide(color: context.f3divider),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('CLOSE'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onSave(_rolledPax);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: F3Colors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(0, 48),
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                label: const Text('SAVE BACKBLAST',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        Text(label,
            style: TextStyle(
                color: context.f3textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      ]),
    );
  }
}

// ─── Rest card shown between exercises ───────────────────────────────────────

class _RestCard extends StatelessWidget {
  final int seconds;
  final Color color;
  final VoidCallback onSkip;

  const _RestCard({
    required this.seconds,
    required this.color,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.self_improvement_rounded, color: color, size: 48),
          const SizedBox(height: 12),
          Text(
            'REST',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${seconds}s',
            style: TextStyle(
              color: color,
              fontSize: 56,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onSkip,
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(160, 44),
            ),
            child: const Text('SKIP REST',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
