// lib/screens/deck_of_pain_screen.dart
// Deck of Pain: a standard 52-card deck where each draw picks an exercise
// (by suit) and a rep count (by rank). A classic F3 game mode — the exact
// suit-to-exercise mapping is regional folklore, not a standard, so it's
// editable rather than hard-coded.
//
// Deliberately standalone (not wired into WorkoutFormat/workout_generator) —
// it's a quick-draw tool a Q pulls up mid-workout, not a planned block type.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

enum _CardSuit { hearts, diamonds, clubs, spades }

class _PlayingCard {
  final _CardSuit suit;
  final int rank; // 1 = Ace ... 11 = Jack, 12 = Queen, 13 = King

  const _PlayingCard(this.suit, this.rank);

  String get rankLabel => switch (rank) {
        1 => 'A',
        11 => 'J',
        12 => 'Q',
        13 => 'K',
        _ => '$rank',
      };

  /// Reps for this card. Face cards are worth their traditional Deck of
  /// Pain values; Ace is famously "1 or 11, Q's call."
  int get reps => switch (rank) {
        11 => 11,
        12 => 12,
        13 => 13,
        _ => rank,
      };

  String get suitSymbol => switch (suit) {
        _CardSuit.hearts => '♥',
        _CardSuit.diamonds => '♦',
        _CardSuit.clubs => '♣',
        _CardSuit.spades => '♠',
      };

  bool get isRed => suit == _CardSuit.hearts || suit == _CardSuit.diamonds;
}

class DeckOfPainScreen extends StatefulWidget {
  const DeckOfPainScreen({super.key});

  @override
  State<DeckOfPainScreen> createState() => _DeckOfPainScreenState();
}

/// A named preset — four suit→exercise mappings. All bodyweight (no coupon
/// required) unless noted, so a Q can run any of them cold at any AO.
class _DeckPreset {
  final String name;
  final String hearts;
  final String diamonds;
  final String clubs;
  final String spades;
  const _DeckPreset(this.name,
      {required this.hearts,
      required this.diamonds,
      required this.clubs,
      required this.spades});
}

const _deckPresets = <_DeckPreset>[
  _DeckPreset('Classic',
      hearts: 'Merkins',
      diamonds: 'Squats',
      clubs: 'Burpees',
      spades: 'Mountain Climbers'),
  _DeckPreset('Upper Body',
      hearts: 'Merkins',
      diamonds: 'Diamond Merkins',
      clubs: 'Wide Merkins',
      spades: 'Dips'),
  _DeckPreset('Legs',
      hearts: 'Squats',
      diamonds: 'Lunges',
      clubs: 'Jump Squats',
      spades: 'Calf Raises'),
  _DeckPreset('Core',
      hearts: 'Big Boy Sit-ups',
      diamonds: 'Flutter Kicks',
      clubs: 'American Hammers',
      spades: 'Freddie Mercuries'),
  _DeckPreset('Gasser',
      hearts: 'Burpees',
      diamonds: 'Mountain Climbers',
      clubs: 'Squat Jumps',
      spades: 'Merkins'),
  _DeckPreset('Coupon',
      hearts: 'Curls',
      diamonds: 'Overhead Press',
      clubs: 'Coupon Squats',
      spades: 'Coupon Swings'),
];

class _DeckOfPainScreenState extends State<DeckOfPainScreen> {
  // Suit → exercise mapping. Regional F3 folklore, not a standard — editable
  // so a Q can match their AO's convention, and swappable via presets.
  final Map<_CardSuit, TextEditingController> _exerciseCtrls = {
    _CardSuit.hearts: TextEditingController(text: 'Merkins'),
    _CardSuit.diamonds: TextEditingController(text: 'Squats'),
    _CardSuit.clubs: TextEditingController(text: 'Burpees'),
    _CardSuit.spades: TextEditingController(text: 'Mountain Climbers'),
  };
  int _presetIndex = 0;

  List<_PlayingCard> _deck = [];
  int _drawn = 0;
  _PlayingCard? _current;
  bool _showCustomize = false;

  @override
  void initState() {
    super.initState();
    _reshuffle();
  }

  void _applyPreset(int index) {
    final p = _deckPresets[index];
    _exerciseCtrls[_CardSuit.hearts]!.text = p.hearts;
    _exerciseCtrls[_CardSuit.diamonds]!.text = p.diamonds;
    _exerciseCtrls[_CardSuit.clubs]!.text = p.clubs;
    _exerciseCtrls[_CardSuit.spades]!.text = p.spades;
    setState(() => _presetIndex = index);
  }

  @override
  void dispose() {
    for (final ctrl in _exerciseCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _reshuffle() {
    final deck = [
      for (final suit in _CardSuit.values)
        for (var rank = 1; rank <= 13; rank++) _PlayingCard(suit, rank),
    ]..shuffle(Random());
    setState(() {
      _deck = deck;
      _drawn = 0;
      _current = null;
    });
  }

  void _draw() {
    if (_drawn >= _deck.length) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _current = _deck[_drawn];
      _drawn++;
    });
  }

  String _exerciseFor(_CardSuit suit) => _exerciseCtrls[suit]!.text.trim().isEmpty
      ? _exerciseCtrls[suit]!.text
      : _exerciseCtrls[suit]!.text.trim();

  @override
  Widget build(BuildContext context) {
    final remaining = _deck.length - _drawn;
    final deckComplete = _drawn >= _deck.length;

    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: const Text('Deck of Pain'),
        backgroundColor: context.f3bg,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Customize exercises',
            onPressed: () => setState(() => _showCustomize = !_showCustomize),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_drawn / ${_deck.length} drawn',
                    style: TextStyle(color: context.f3textSecondary, fontSize: 13),
                  ),
                  TextButton.icon(
                    onPressed: _reshuffle,
                    icon: const Icon(Icons.shuffle_rounded, size: 18),
                    label: const Text('Reshuffle'),
                  ),
                ],
              ),
            ),
            // Preset decks — tap to swap all four suits at once.
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                itemCount: _deckPresets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final selected = i == _presetIndex;
                  return ChoiceChip(
                    label: Text(_deckPresets[i].name,
                        style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => _applyPreset(i),
                    backgroundColor: context.f3elevated,
                    selectedColor: F3Colors.accent.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                        color:
                            selected ? F3Colors.accent : context.f3textSecondary,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal),
                    side: BorderSide(
                        color: selected ? F3Colors.accent : context.f3divider),
                  );
                },
              ),
            ),
            if (_showCustomize)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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
                      Text(
                        'Suit → exercise (this is regional tradition, not a rule — set it to match your AO)',
                        style: TextStyle(color: context.f3textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 10),
                      for (final suit in _CardSuit.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextField(
                            controller: _exerciseCtrls[suit],
                            style: TextStyle(color: context.f3textPrimary),
                            decoration: InputDecoration(
                              isDense: true,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  _PlayingCard(suit, 1).suitSymbol,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: _PlayingCard(suit, 1).isRed
                                        ? const Color(0xFFE53935)
                                        : context.f3textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Center(
                child: deckComplete
                    ? _DeckCompleteCard(onReshuffle: _reshuffle)
                    : _current == null
                        ? _DrawPrompt(onDraw: _draw, remaining: remaining)
                        : _CardDisplay(
                            card: _current!,
                            exercise: _exerciseFor(_current!.suit),
                          ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: deckComplete ? null : _draw,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  icon: const Icon(Icons.style_rounded),
                  label: Text(
                    deckComplete
                        ? 'Deck Complete'
                        : _current == null
                            ? 'Draw First Card'
                            : 'Draw Next Card ($remaining left)',
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

class _DrawPrompt extends StatelessWidget {
  final VoidCallback onDraw;
  final int remaining;
  const _DrawPrompt({required this.onDraw, required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.style_outlined, color: context.f3textMuted, size: 64),
        const SizedBox(height: 16),
        Text(
          'Full deck, shuffled and ready',
          style: TextStyle(color: context.f3textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

class _CardDisplay extends StatelessWidget {
  final _PlayingCard card;
  final String exercise;
  const _CardDisplay({required this.card, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final color = card.isRed ? const Color(0xFFE53935) : context.f3textPrimary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 180,
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.f3card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.f3divider, width: 2),
            boxShadow: [
              BoxShadow(
                color: F3Colors.accent.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(card.rankLabel,
                  style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.w900)),
              Center(
                child: Text(card.suitSymbol, style: TextStyle(color: color, fontSize: 72)),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Transform.rotate(
                  angle: pi,
                  child: Text(card.rankLabel,
                      style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '${card.reps} × $exercise',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.f3textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DeckCompleteCard extends StatelessWidget {
  final VoidCallback onReshuffle;
  const _DeckCompleteCard({required this.onReshuffle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.celebration_rounded, color: F3Colors.accent, size: 64),
        const SizedBox(height: 16),
        Text(
          'Deck complete — that\'s the whole 52',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.f3textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onReshuffle,
          icon: const Icon(Icons.shuffle_rounded),
          label: const Text('Reshuffle'),
        ),
      ],
    );
  }
}
