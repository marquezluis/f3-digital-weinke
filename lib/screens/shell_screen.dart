// lib/screens/shell_screen.dart
// Bottom-navigation shell — 5 intent-based tabs:
//   0 Home · 1 Plan · 2 Schedule · 3 Community · 4 You
// Plan hosts the Q toolkit (Weinke/Q Mode/Exicon/Spartan); Community is the
// PAX/brotherhood surface (future messaging home); You is profile + settings.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/current_workout_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'plan_hub_screen.dart';
import 'schedule_screen.dart';
import 'brotherhood_screen.dart';
import 'settings_screen.dart';
import 'spartan_chat_screen.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  static const _screens = [
    HomeScreen(),         // 0 — Home
    PlanHubScreen(),      // 1 — Plan (Weinke / Q Mode / Exicon / Spartan)
    ScheduleScreen(),     // 2 — Schedule
    BrotherhoodScreen(),  // 3 — Community (PAX + future messaging)
    SettingsScreen(),     // 4 — You (profile + settings)
  ];

  @override
  Widget build(BuildContext context) {
    final draftCount = context
            .watch<CurrentWorkoutService>()
            .draftPlan
            ?.allExercises
            .length ??
        0;
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<int>(
      valueListenable: context.read<ValueNotifier<int>>(),
      builder: (context, index, _) {
        final destinations = [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: draftCount > 0,
              label: Text('$draftCount'),
              child: const Icon(Icons.fitness_center_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: draftCount > 0,
              label: Text('$draftCount'),
              child: const Icon(Icons.fitness_center_rounded),
            ),
            label: l10n.navPlan,
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_outlined),
            selectedIcon: const Icon(Icons.event_rounded),
            label: l10n.navSchedule,
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups_rounded),
            label: l10n.navCommunity,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: l10n.navYou,
          ),
        ];

        return Scaffold(
          backgroundColor: context.f3bg,
          body: IndexedStack(
            index: index,
            children: _screens,
          ),
          // Spartan Co-Q reachable from every main tab.
          floatingActionButton: FloatingActionButton(
            heroTag: 'spartanFab',
            backgroundColor: F3Colors.catCoupon,
            foregroundColor: Colors.white,
            tooltip: l10n.navSpartanCoQ,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SpartanChatScreen()),
            ),
            child: const Icon(Icons.shield_rounded),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: context.f3divider, width: 0.5)),
            ),
            child: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) {
                context.read<ValueNotifier<int>>().value = i;
              },
              destinations: destinations,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
            ),
          ),
        );
      },
    );
  }
}
