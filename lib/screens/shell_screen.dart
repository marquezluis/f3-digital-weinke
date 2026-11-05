// lib/screens/shell_screen.dart
// Bottom-navigation shell — 5 tabs, reorganized to match the official F3
// Nation app's wireframe tab structure (Home / Map-Cal / Commz / Resources
// / Profile) now that both apps are being compared side by side for
// Moneyball's ground-up build:
//   0 Home · 1 Map/Cal · 2 Commz · 3 Resources · 4 Profile
// Map/Cal (map_cal_screen.dart) merges the former standalone Browse-AOs
// entry point and the Schedule tab behind a top toggle. Commz is Region
// Chat (chat_screen.dart), now gated behind sign-in. Resources
// (resources_hub_screen.dart) replaces the former "Plan" tab — same Q
// toolkit, now also including the previously-unreachable Q Builder, under
// the wireframe's own grouping (Q Tools / Codex / QSource / App Help).
// Profile stays routed to SettingsScreen, which already carries profile
// identity alongside preferences — splitting those apart is a bigger
// change than this pass's relabel+reorg (see resources_hub_screen.dart's
// header for the same scoping call on Q Builder's prior unreachability).
//
// Previously (#91) this was Home/Plan/Schedule/Fellowship/You; Brotherhood
// (PAX roster) doesn't have its own tab anymore — it's still reachable from
// Home (same entry point as before), since it was never one of the
// official app's 5 primary tabs either. home_screen.dart's hardcoded
// Schedule-tab shortcut was updated to open Map/Cal (index 1) directly to
// its Calendar view.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../services/current_workout_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'map_cal_screen.dart';
import 'chat_screen.dart';
import 'resources_hub_screen.dart';
import 'settings_screen.dart';
import 'spartan_chat_screen.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  static const _screens = [
    HomeScreen(),          // 0 — Home
    MapCalScreen(),        // 1 — Map/Cal (Browse AOs + Schedule, toggled)
    ChatScreen(),           // 2 — Commz (Region Chat, signed-in only)
    ResourcesHubScreen(),  // 3 — Resources (Q Tools / Codex / QSource / Help)
    SettingsScreen(),      // 4 — Profile
  ];

  @override
  Widget build(BuildContext context) {
    final draftCount = context
            .watch<CurrentWorkoutService>()
            .draftPlan
            ?.allExercises
            .length ??
        0;
    // Commz is gated behind sign-in (chat_screen.dart's _CommzLockScreen) —
    // a lock icon here previews that instead of a chat bubble that would
    // otherwise promise a tab the tap is about to refuse.
    final commzLocked = !(context.watch<AuthService>().currentUser?.identities
            .any((i) => i.provider == AuthProvider.f3nation) ??
        false);
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
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map_rounded),
            label: l10n.navMapCal,
          ),
          NavigationDestination(
            icon: Icon(commzLocked
                ? Icons.lock_outline_rounded
                : Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(commzLocked
                ? Icons.lock_rounded
                : Icons.chat_bubble_rounded),
            label: l10n.navCommz,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: draftCount > 0,
              label: Text('$draftCount'),
              child: const Icon(Icons.auto_stories_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: draftCount > 0,
              label: Text('$draftCount'),
              child: const Icon(Icons.auto_stories_rounded),
            ),
            label: l10n.navResources,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: l10n.navProfile,
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
