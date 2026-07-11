// lib/screens/shell_screen.dart
// Bottom-navigation shell — 7 tabs, Q Mode at center (index 3).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/current_workout_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'workout_screen.dart';
import 'library_screen.dart';
import 'timer_screen.dart';
import 'spartan_chat_screen.dart';
import 'brotherhood_screen.dart';
import 'settings_screen.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  static const _screens = [
    HomeScreen(),         // 0 — Home
    WorkoutScreen(),      // 1 — Weinke
    LibraryScreen(),      // 2 — Exicon
    TimerScreen(),        // 3 — Q Mode (center)
    SpartanChatScreen(),  // 4 — Spartan
    BrotherhoodScreen(),  // 5 — PAX
    SettingsScreen(),     // 6 — Settings
  ];

  @override
  Widget build(BuildContext context) {
    final exerciseCount = context
            .watch<CurrentWorkoutService>()
            .draftPlan
            ?.allExercises
            .length ??
        0;

    const destinations = [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.fitness_center_outlined),
        selectedIcon: Icon(Icons.fitness_center_rounded),
        label: 'Weinke',
      ),
      NavigationDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book_rounded),
        label: 'Exicon',
      ),
      NavigationDestination(
        icon: Icon(Icons.play_circle_outline_rounded),
        selectedIcon: Icon(Icons.play_circle_rounded),
        label: 'Q Mode',
      ),
      NavigationDestination(
        icon: Icon(Icons.shield_outlined),
        selectedIcon: Icon(Icons.shield_rounded),
        label: 'Spartan',
      ),
      NavigationDestination(
        icon: Icon(Icons.groups_outlined),
        selectedIcon: Icon(Icons.groups_rounded),
        label: 'PAX',
      ),
      NavigationDestination(
        icon: Icon(Icons.tune_outlined),
        selectedIcon: Icon(Icons.tune_rounded),
        label: 'Settings',
      ),
    ];

    return ValueListenableBuilder<int>(
      valueListenable: context.read<ValueNotifier<int>>(),
      builder: (context, index, _) {
        // Weinke badge wired in separately to avoid rebuilding destinations list.
        final destinations7 = [
          destinations[0],
          NavigationDestination(
            icon: Badge(
              isLabelVisible: exerciseCount > 0,
              label: Text('$exerciseCount'),
              child: const Icon(Icons.fitness_center_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: exerciseCount > 0,
              label: Text('$exerciseCount'),
              child: const Icon(Icons.fitness_center_rounded),
            ),
            label: 'Weinke',
          ),
          ...destinations.sublist(2),
        ];

        return Scaffold(
          backgroundColor: context.f3bg,
          body: IndexedStack(
            index: index,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.f3divider, width: 0.5)),
            ),
            child: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) {
                context.read<ValueNotifier<int>>().value = i;
              },
              destinations: destinations7,
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            ),
          ),
        );
      },
    );
  }
}
