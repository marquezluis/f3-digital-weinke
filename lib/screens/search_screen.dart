// lib/screens/search_screen.dart
// One search box across the three separately-browsable content types
// (Exicon, QSource field guide, AOs) — there was previously no way to look
// for something across all of them at once. Result taps are deliberately
// broad, not deep-linked into the exact QSource section or map pin — that
// would mean threading a jump target through screens that don't currently
// expose one, a bigger change than this search box itself.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/f3_api_models.dart';
import '../models/qsource_data.dart';
import '../services/exercise_service.dart';
import '../services/f3_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/category_chip.dart';
import '../widgets/exercise_detail_sheet.dart';
import 'browse_aos_screen.dart';
import 'qsource_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  List<F3Location> _allLocations = const [];
  bool _locationsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final locations = await context.read<F3ApiService>().getLocations();
    if (!mounted) return;
    setState(() {
      _allLocations = locations;
      _locationsLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<QGuideSection> get _qSourceMatches {
    final q = _query.toLowerCase();
    if (q.isEmpty) return const [];
    return QSourceData.allSections.where((section) {
      if (section.title.toLowerCase().contains(q)) return true;
      if ((section.subtitle ?? '').toLowerCase().contains(q)) return true;
      return section.entries.any((e) =>
          e.label.toLowerCase().contains(q) ||
          (e.detail ?? '').toLowerCase().contains(q));
    }).toList();
  }

  List<F3Location> get _locationMatches {
    final q = _query.toLowerCase();
    if (q.isEmpty) return const [];
    return _allLocations.where((loc) {
      final name = (loc.aoName ?? loc.name).toLowerCase();
      return name.contains(q) ||
          (loc.description ?? '').toLowerCase().contains(q) ||
          (loc.city ?? '').toLowerCase().contains(q);
    }).take(15).toList();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = context.watch<ExerciseService>();
    final exerciseMatches =
        _query.isEmpty ? const <Exercise>[] : exercises.search(_query).take(15).toList();
    final qsourceMatches = _qSourceMatches;
    final locationMatches = _locationMatches;
    final hasAnyResults = exerciseMatches.isNotEmpty ||
        qsourceMatches.isNotEmpty ||
        locationMatches.isNotEmpty;

    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        backgroundColor: context.f3bg,
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: TextStyle(color: context.f3textPrimary),
          decoration: InputDecoration(
            hintText: 'Search exercises, QSource, AOs…',
            hintStyle: TextStyle(color: context.f3textMuted),
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
      ),
      body: _query.isEmpty
          ? Center(
              child: Text(
                'Search across the Exicon, Q Field Guide, and AOs at once.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.f3textMuted, fontSize: 13),
              ),
            )
          : !hasAnyResults
              ? Center(
                  child: Text('No results for "$_query"',
                      style: TextStyle(color: context.f3textMuted)),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (exerciseMatches.isNotEmpty) ...[
                      _ResultHeader('EXICON', exerciseMatches.length),
                      ...exerciseMatches.map((ex) => Card(
                            color: context.f3card,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CategoryChip(category: ex.category, small: true),
                              title: Text(ex.name,
                                  style: TextStyle(color: context.f3textPrimary)),
                              onTap: () => ExerciseDetailSheet.show(context, ex),
                            ),
                          )),
                      const SizedBox(height: 12),
                    ],
                    if (qsourceMatches.isNotEmpty) ...[
                      _ResultHeader('Q FIELD GUIDE', qsourceMatches.length),
                      ...qsourceMatches.map((s) => Card(
                            color: context.f3card,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(Icons.menu_book_rounded,
                                  color: F3Colors.phaseCOT),
                              title: Text(s.title,
                                  style: TextStyle(color: context.f3textPrimary)),
                              subtitle: s.subtitle != null
                                  ? Text(s.subtitle!,
                                      style:
                                          TextStyle(color: context.f3textMuted))
                                  : null,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const QSourceScreen())),
                            ),
                          )),
                      const SizedBox(height: 12),
                    ],
                    if (_locationsLoading)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                            child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2))),
                      )
                    else if (locationMatches.isNotEmpty) ...[
                      _ResultHeader('AOs', locationMatches.length),
                      ...locationMatches.map((loc) => Card(
                            color: context.f3card,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(Icons.flag_rounded,
                                  color: F3Colors.accent),
                              title: Text(loc.aoName ?? loc.name,
                                  style: TextStyle(color: context.f3textPrimary)),
                              subtitle: loc.city != null
                                  ? Text(loc.city!,
                                      style:
                                          TextStyle(color: context.f3textMuted))
                                  : null,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const BrowseAosScreen())),
                            ),
                          )),
                    ],
                  ],
                ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final String title;
  final int count;
  const _ResultHeader(this.title, this.count);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text('$title ($count)',
          style: TextStyle(
              color: context.f3textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1)),
    );
  }
}
