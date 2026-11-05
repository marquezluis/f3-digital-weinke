// lib/screens/map_cal_screen.dart
// The "Map/Cal" tab (MAP-01/CAL-01 in the official-app wireframes): Browse
// AOs and Schedule merged behind one top toggle, matching the wireframe's
// tab structure. Each kept view is still its own full screen underneath
// (own AppBar, own state) — this only adds the toggle strip above an
// IndexedStack, the same pattern shell_screen.dart already uses to switch
// between tabs, just nested one level deeper here.
//
// Deliberately NOT a from-scratch merged screen: Browse AOs and Schedule
// are both substantial, independently-tested features already. Rebuilding
// them as one screen risked breaking either for a visual nicety this
// wireframe alignment doesn't actually require.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'browse_aos_screen.dart';
import 'schedule_screen.dart';

class MapCalScreen extends StatefulWidget {
  const MapCalScreen({super.key});

  @override
  State<MapCalScreen> createState() => _MapCalScreenState();
}

class _MapCalScreenState extends State<MapCalScreen> {
  late MapCalView _view;

  // Lets Home's "see all" jump (ValueNotifier<MapCalView?>) force this
  // already-live screen (kept alive in ShellScreen's IndexedStack) onto
  // Calendar, overriding whatever view was last remembered — same pattern
  // as ScheduleScreen's own MineFilter notifier.
  late final ValueNotifier<MapCalView?> _forcedViewNotifier;

  @override
  void initState() {
    super.initState();
    // Opens to whichever view was used last (or the Settings default on
    // first-ever open) — PROF-06 in the wireframes.
    _view = context.read<SettingsService>().mapCalDefaultView;
    _forcedViewNotifier = context.read<ValueNotifier<MapCalView?>>();
    _forcedViewNotifier.addListener(_onViewForced);
  }

  @override
  void dispose() {
    _forcedViewNotifier.removeListener(_onViewForced);
    super.dispose();
  }

  void _onViewForced() {
    final requested = _forcedViewNotifier.value;
    if (requested == null) return;
    setState(() => _view = requested);
    _forcedViewNotifier.value = null; // consume once
  }

  void _setView(MapCalView view) {
    if (view == _view) return;
    setState(() => _view = view);
    context.read<SettingsService>().setMapCalDefaultView(view);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: SegmentedButton<MapCalView>(
              segments: const [
                ButtonSegment(
                  value: MapCalView.map,
                  icon: Icon(Icons.map_rounded),
                  label: Text('Map'),
                ),
                ButtonSegment(
                  value: MapCalView.calendar,
                  icon: Icon(Icons.calendar_month_rounded),
                  label: Text('Calendar'),
                ),
              ],
              selected: {_view},
              onSelectionChanged: (s) => _setView(s.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? F3Colors.accent.withValues(alpha: 0.16)
                        : context.f3card),
              ),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _view == MapCalView.map ? 0 : 1,
            children: const [BrowseAosScreen(), ScheduleScreen()],
          ),
        ),
      ],
    );
  }
}
