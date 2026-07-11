// lib/screens/library_screen.dart
// Full Exicon library — searchable, filterable by category and intensity.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_card.dart';
import '../widgets/exercise_detail_sheet.dart';

enum _ExiconSort { alphabetical, mostUsed, neverUsed }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Set<Intensity> _intensityFilter = Set.from(Intensity.values);
  // null = show all; Equipment.none = no coupon; Equipment.coupon = coupon only
  Equipment? _equipmentFilter;
  _ExiconSort _sort = _ExiconSort.alphabetical;

  static const _tabs = [
    ('All', null),
    ('Warm-Up', ExerciseCategory.warmup),
    ('Bodyweight', ExerciseCategory.bodyweight),
    ('Coupon', ExerciseCategory.coupon),
    ('Mary', ExerciseCategory.mary),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseService>(
      builder: (context, service, _) => _buildScaffold(context, service),
    );
  }

  Widget _buildScaffold(BuildContext context, ExerciseService service) {
    final history = Provider.of<HistoryService>(context, listen: false);
    final usageMap = _buildUsageMap(history);

    // Compute filtered lists once per build — avoids running the filter 2× per tab.
    final filteredByTab = {
      for (final t in _tabs) t.$2: _filteredExercises(service, t.$2, usageMap)
    };

    return Scaffold(
      backgroundColor: F3Colors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final exercises = filteredByTab[_tabs[_tabController.index].$2]!;
          if (exercises.isEmpty) return;
          final pick = exercises[Random().nextInt(exercises.length)];
          ExerciseDetailSheet.show(context, pick);
        },
        icon: const Icon(Icons.casino_rounded),
        label: const Text('SURPRISE ME',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        backgroundColor: F3Colors.accent,
        foregroundColor: Colors.white,
      ),
      appBar: AppBar(
        title: const Text('Exicon Library'),
        backgroundColor: F3Colors.background,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          // Sort order toggle
          IconButton(
            icon: Icon(
              switch (_sort) {
                _ExiconSort.alphabetical => Icons.sort_by_alpha_rounded,
                _ExiconSort.mostUsed => Icons.trending_up_rounded,
                _ExiconSort.neverUsed => Icons.new_releases_rounded,
              },
              color: _sort != _ExiconSort.alphabetical ? F3Colors.accent : null,
            ),
            tooltip: 'Sort order',
            onPressed: () => setState(() {
              _sort = switch (_sort) {
                _ExiconSort.alphabetical => _ExiconSort.mostUsed,
                _ExiconSort.mostUsed => _ExiconSort.neverUsed,
                _ExiconSort.neverUsed => _ExiconSort.alphabetical,
              };
            }),
          ),
          if (_sort != _ExiconSort.alphabetical)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: F3Colors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _sort == _ExiconSort.mostUsed ? 'MOST USED' : 'NEVER USED',
                    style: const TextStyle(
                        color: F3Colors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          // Equipment filter toggle
          IconButton(
            icon: Icon(
              Icons.hardware_rounded,
              color: _equipmentFilter != null
                  ? F3Colors.catCoupon
                  : null,
            ),
            tooltip: 'Equipment filter',
            onPressed: () {
              setState(() {
                // Cycle: all → no coupon → coupon only → all
                if (_equipmentFilter == null) {
                  _equipmentFilter = Equipment.none;
                } else if (_equipmentFilter == Equipment.none) {
                  _equipmentFilter = Equipment.coupon;
                } else {
                  _equipmentFilter = null;
                }
              });
            },
          ),
          if (_equipmentFilter != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: F3Colors.catCoupon.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _equipmentFilter == Equipment.coupon
                        ? 'COUPON'
                        : 'NO COUPON',
                    style: const TextStyle(
                        color: F3Colors.catCoupon,
                        fontSize: 10,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          // Intensity filter
          PopupMenuButton<Intensity>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter by intensity',
            color: F3Colors.card,
            onSelected: (intensity) {
              setState(() {
                if (_intensityFilter.contains(intensity)) {
                  if (_intensityFilter.length > 1) {
                    _intensityFilter = Set.from(_intensityFilter)
                      ..remove(intensity);
                  }
                } else {
                  _intensityFilter = Set.from(_intensityFilter)
                    ..add(intensity);
                }
              });
            },
            itemBuilder: (_) => Intensity.values.map((i) {
              final color = F3Colors.forIntensity(i.name);
              return PopupMenuItem(
                value: i,
                child: Row(children: [
                  Icon(
                    _intensityFilter.contains(i)
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: color, size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(i.displayName,
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w600)),
                ]),
              );
            }).toList(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: SizedBox(
            height: 108,
            width: double.infinity,
            child: ColoredBox(
              color: F3Colors.background,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: F3Colors.textPrimary, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Search exercises…',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: F3Colors.accent,
                    labelColor: F3Colors.accent,
                    unselectedLabelColor: F3Colors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    dividerColor: Colors.transparent,
                    tabs: _tabs.map((t) {
                      final count = filteredByTab[t.$2]!.length;
                      return Tab(text: '${t.$1} ($count)');
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ColoredBox(
        color: F3Colors.background,
        child: TabBarView(
          controller: _tabController,
          children: _tabs.map((t) {
            return _ExerciseList(
              exercises: filteredByTab[t.$2]!,
              query: _query,
            );
          }).toList(),
        ),
      ),
    );
  }

  Map<String, int> _buildUsageMap(HistoryService history) {
    final map = <String, int>{};
    for (final session in history.all) {
      for (final block in session.blocks) {
        for (final name in block.exerciseNames) {
          map[name] = (map[name] ?? 0) + 1;
        }
      }
    }
    return map;
  }

  List<Exercise> _filteredExercises(
      ExerciseService service, ExerciseCategory? cat, Map<String, int> usageMap) {
    List<Exercise> base =
        List.of(cat == null ? service.all : service.byCategory(cat));

    // Equipment filter
    if (_equipmentFilter != null) {
      base = base.where((e) => e.equipment == _equipmentFilter).toList();
    }

    // Intensity filter
    if (_intensityFilter.length < Intensity.values.length) {
      base = base.where((e) => _intensityFilter.contains(e.intensity)).toList();
    }

    // Text search
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      base = base.where((e) =>
          e.name.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q) ||
          e.aliases.any((a) => a.toLowerCase().contains(q))).toList();
    }

    // Sort
    switch (_sort) {
      case _ExiconSort.alphabetical:
        base.sort((a, b) => a.name.compareTo(b.name));
      case _ExiconSort.mostUsed:
        base.sort((a, b) =>
            (usageMap[b.name] ?? 0).compareTo(usageMap[a.name] ?? 0));
      case _ExiconSort.neverUsed:
        base.sort((a, b) {
          final aUsed = usageMap.containsKey(a.name);
          final bUsed = usageMap.containsKey(b.name);
          if (!aUsed && bUsed) return -1;
          if (aUsed && !bUsed) return 1;
          return a.name.compareTo(b.name);
        });
    }

    return base;
  }
}

class _ExerciseList extends StatelessWidget {
  final List<Exercise> exercises;
  final String query;

  const _ExerciseList({required this.exercises, required this.query});

  void _showDetail(BuildContext context, Exercise ex) {
    ExerciseDetailSheet.show(context, ex);
  }

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return ColoredBox(
        color: F3Colors.background,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: F3Colors.elevated,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: F3Colors.divider),
                ),
                child: const Icon(Icons.search_off_rounded, color: F3Colors.textMuted, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                query.isEmpty ? 'No exercises match.' : 'No results for "$query"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: F3Colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                query.isEmpty
                    ? 'Try adjusting the intensity or equipment filter.'
                    : 'Check spelling or try a shorter search term.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: F3Colors.textSecondary, fontSize: 13),
              ),
            ]),
          ),
        ),
      );
    }

    return ColoredBox(
      color: F3Colors.background,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: exercises.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ExerciseCard(
            exercise: exercises[i],
            onDetail: () => _showDetail(context, exercises[i]),
          ),
        ),
      ),
    );
  }
}

