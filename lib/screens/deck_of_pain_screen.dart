// lib/screens/deck_of_pain_screen.dart
// Deck of Pain — randomized-pool version. The Q picks how many exercises and
// how many cards, gets a randomized rotation from the Exicon (edit/reroll each
// or all), then draws: every card shows one pooled exercise + a rep count.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';
import '../theme/app_theme.dart';

class DeckOfPainScreen extends StatefulWidget {
  const DeckOfPainScreen({super.key});

  @override
  State<DeckOfPainScreen> createState() => _DeckOfPainScreenState();
}

class _DeckOfPainScreenState extends State<DeckOfPainScreen> {
  final _rng = Random();
  static const _cardOptions = [5, 10, 20, 30, 52];

  int _exerciseCount = 6;
  int _targetCards = 20;
  bool _includeCoupon = false;

  List<Exercise> _pool = [];
  bool _started = false;

  int _drawn = 0;
  int _totalReps = 0;
  Exercise? _current;
  int _currentReps = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _randomizePool());
  }

  List<Exercise> get _candidates {
    final all = context.read<ExerciseService>().all.where((e) {
      if (e.category == ExerciseCategory.warmup) return false;
      if (!_includeCoupon && e.category == ExerciseCategory.coupon) {
        return false;
      }
      return true;
    }).toList();
    return all;
  }

  void _randomizePool() {
    final pool = List<Exercise>.from(_candidates)..shuffle(_rng);
    setState(() => _pool = pool.take(_exerciseCount).toList());
  }

  void _rerollOne(int index) {
    final used = _pool.map((e) => e.id).toSet();
    final options =
        _candidates.where((e) => !used.contains(e.id)).toList();
    if (options.isEmpty) return;
    setState(() => _pool[index] = options[_rng.nextInt(options.length)]);
  }

  void _removeOne(int index) {
    setState(() {
      _pool.removeAt(index);
      _exerciseCount = _pool.length;
    });
  }

  void _setExerciseCount(int n) {
    n = n.clamp(2, 15);
    _exerciseCount = n;
    if (n <= _pool.length) {
      setState(() => _pool = _pool.take(n).toList());
    } else {
      // grow: add new random exercises not already used
      final used = _pool.map((e) => e.id).toSet();
      final options = _candidates.where((e) => !used.contains(e.id)).toList()
        ..shuffle(_rng);
      setState(() => _pool = [..._pool, ...options.take(n - _pool.length)]);
    }
  }

  int _repsForRank(int rank) => rank; // 1..13 (face cards = 11/12/13)

  void _draw() {
    if (_pool.isEmpty || _drawn >= _targetCards) return;
    HapticFeedback.mediumImpact();
    final reps = _repsForRank(1 + _rng.nextInt(13));
    setState(() {
      _current = _pool[_rng.nextInt(_pool.length)];
      _currentReps = reps;
      _totalReps += reps;
      _drawn++;
    });
  }

  Future<void> _promptCustomCount() async {
    final ctrl = TextEditingController(text: '$_targetCards');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.f3card,
        title: const Text('How many cards?'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: TextStyle(color: context.f3textPrimary),
          decoration: const InputDecoration(hintText: '1 – 99'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final n = int.tryParse(ctrl.text.trim());
              Navigator.pop(context, n?.clamp(1, 99));
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (result != null) setState(() => _targetCards = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: const Text('Deck of Pain'),
        backgroundColor: context.f3bg,
        actions: [
          if (_started)
            TextButton(
              onPressed: () => setState(() {
                _started = false;
                _drawn = 0;
                _totalReps = 0;
                _current = null;
              }),
              child: const Text('EDIT'),
            ),
        ],
      ),
      body: SafeArea(
        child: _started ? _buildPlay(context) : _buildSetup(context),
      ),
    );
  }

  // ── Setup ─────────────────────────────────────────────────────────────────
  Widget _buildSetup(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Exercise count
        Row(children: [
          Text('Exercises',
              style: TextStyle(
                  color: context.f3textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          _Stepper(
            value: _exerciseCount,
            onChanged: _setExerciseCount,
            min: 2,
            max: 15,
          ),
        ]),
        const SizedBox(height: 16),
        // Card count
        Text('Cards to draw',
            style: TextStyle(
                color: context.f3textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, children: [
          ..._cardOptions.map((n) => _chip(n == 52 ? 'All' : '$n',
              _targetCards == n, () => setState(() => _targetCards = n))),
          _chip(
              _cardOptions.contains(_targetCards) ? 'Custom' : '$_targetCards',
              !_cardOptions.contains(_targetCards),
              _promptCustomCount),
        ]),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _includeCoupon,
          onChanged: (v) {
            setState(() => _includeCoupon = v);
            _randomizePool();
          },
          title: Text('Include coupon exercises',
              style: TextStyle(color: context.f3textPrimary, fontSize: 14)),
        ),
        const Divider(),
        Row(children: [
          Text('The rotation',
              style: TextStyle(
                  color: context.f3textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          TextButton.icon(
            onPressed: _randomizePool,
            icon: const Icon(Icons.casino_rounded, size: 18),
            label: const Text('Randomize all'),
          ),
        ]),
        const SizedBox(height: 4),
        ..._pool.asMap().entries.map((e) => _ExerciseRow(
              name: e.value.name,
              category: e.value.category.displayName,
              onReroll: () => _rerollOne(e.key),
              onRemove: _pool.length > 2 ? () => _removeOne(e.key) : null,
            )),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: F3Colors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: _pool.isEmpty
              ? null
              : () => setState(() {
                    _started = true;
                    _drawn = 0;
                    _totalReps = 0;
                    _current = null;
                  }),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text('Start — $_targetCards cards'),
        ),
      ],
    );
  }

  // ── Play ────────────────────────────────────────────────────────────────
  Widget _buildPlay(BuildContext context) {
    final done = _drawn >= _targetCards;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text('$_drawn / $_targetCards drawn · $_totalReps reps',
              style: TextStyle(color: context.f3textSecondary, fontSize: 13)),
        ),
        Expanded(
          child: Center(
            child: _current == null
                ? Text('Tap DRAW to start',
                    style: TextStyle(
                        color: context.f3textMuted, fontSize: 16))
                : Container(
                    margin: const EdgeInsets.all(28),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: context.f3card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: F3Colors.accent, width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$_currentReps',
                            style: const TextStyle(
                                color: F3Colors.accent,
                                fontSize: 72,
                                fontWeight: FontWeight.w900,
                                height: 1)),
                        Text('REPS',
                            style: TextStyle(
                                color: context.f3textMuted,
                                fontSize: 12,
                                letterSpacing: 3)),
                        const SizedBox(height: 16),
                        Text(_current!.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: context.f3textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: done ? context.f3card : F3Colors.accent,
                foregroundColor: done ? context.f3textPrimary : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              onPressed: done
                  ? () => setState(() {
                        _drawn = 0;
                        _totalReps = 0;
                        _current = null;
                      })
                  : _draw,
              child: Text(done ? 'Done — deal again' : 'DRAW',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: context.f3elevated,
      selectedColor: F3Colors.accent.withValues(alpha: 0.18),
      labelStyle: TextStyle(
          color: selected ? F3Colors.accent : context.f3textSecondary),
      side: BorderSide(
          color: selected ? F3Colors.accent : context.f3divider),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _Stepper(
      {required this.value,
      required this.onChanged,
      required this.min,
      required this.max});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      IconButton(
        icon: const Icon(Icons.remove_circle_outline_rounded),
        color: context.f3textSecondary,
        onPressed: value > min ? () => onChanged(value - 1) : null,
      ),
      SizedBox(
        width: 28,
        child: Text('$value',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: context.f3textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
      ),
      IconButton(
        icon: const Icon(Icons.add_circle_outline_rounded),
        color: context.f3textSecondary,
        onPressed: value < max ? () => onChanged(value + 1) : null,
      ),
    ]);
  }
}

class _ExerciseRow extends StatelessWidget {
  final String name;
  final String category;
  final VoidCallback onReroll;
  final VoidCallback? onRemove;
  const _ExerciseRow(
      {required this.name,
      required this.category,
      required this.onReroll,
      this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(
                      color: context.f3textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              Text(category,
                  style:
                      TextStyle(color: context.f3textMuted, fontSize: 11)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.casino_rounded, size: 20),
          color: context.f3textSecondary,
          tooltip: 'Reroll',
          onPressed: onReroll,
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 20),
          color: onRemove == null ? context.f3divider : context.f3textMuted,
          tooltip: 'Remove',
          onPressed: onRemove,
        ),
      ]),
    );
  }
}
