// lib/screens/profile_hub_screen.dart
// The "Profile" tab (PROF-01..06 in the official-app wireframes), grouped
// under one hub the same way resources_hub_screen.dart grouped Resources —
// identity up top, then PAX Vault (PROF-02), Badges & Milestones (PROF-03),
// Leaderboards (PROF-04), and Settings (PROF-06). Edit Profile/Emergency
// Contact (PROF-05) stay one tap away via the identity card → ProfileScreen,
// same as before.
//
// Previously this tab routed straight to SettingsScreen, which carried
// identity (banner + manual F3-name field for an unlinked PAX) ahead of
// app preferences on one long scroll — splitting those apart was flagged in
// shell_screen.dart's header as a bigger change than that pass's
// relabel+reorg. This hub is that change: the identity banner and manual
// F3-name field moved here from SettingsScreen (verbatim behavior, new
// home), and PAX Vault/Badges — previously only reachable from Home/
// Brotherhood — get their own cards here too, matching the wireframes'
// grouping without removing their existing Home/Brotherhood entry points.
//
// Leaderboards (PROF-04) is a disabled placeholder, not a dead link that
// pretends to work: `/v1/org` and friends have no region-wide stats
// endpoint for this app to call (see docs/wireframe-mapping.md).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/auth_models.dart';
import '../services/app_profile_service.dart';
import '../services/auth_service.dart';
import '../services/f3_api_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../utils/greeting.dart';
import '../widgets/self_avatar.dart';
import 'achievements_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class ProfileHubScreen extends StatelessWidget {
  const ProfileHubScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: context.f3bg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _IdentityCard(),
          const SizedBox(height: 20),
          _SectionLabel('PAX STATS'),
          _ToolCard(
            icon: Icons.insights_rounded,
            title: 'PAX Vault',
            subtitle: 'Your saved sessions, streaks, and trends',
            color: F3Colors.accent,
            onTap: () => _push(context, const HistoryScreen()),
          ),
          const SizedBox(height: 8),
          _ToolCard(
            icon: Icons.emoji_events_rounded,
            title: 'Badges & Milestones',
            subtitle: 'Achievements earned from your own history',
            color: const Color(0xFFFFD700),
            onTap: () => _push(context, const AchievementsScreen()),
          ),
          const SizedBox(height: 8),
          _ToolCard(
            icon: Icons.leaderboard_rounded,
            title: 'Leaderboards',
            subtitle:
                "Not available — F3 Nation's API has no region-wide stats endpoint for this app to use",
            color: context.f3textMuted,
            onTap: null,
          ),
          const SizedBox(height: 20),
          _SectionLabel('APP'),
          _ToolCard(
            icon: Icons.settings_rounded,
            title: 'Settings',
            subtitle: 'Appearance, voice, music, safety, and data',
            color: F3Colors.catMary,
            onTap: () => _push(context, const SettingsScreen()),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(text,
          style: TextStyle(
              color: context.f3textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2)),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  const _ToolCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: context.f3card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Opacity(
          opacity: disabled ? 0.6 : 1,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.f3divider),
            ),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: context.f3textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                    Text(subtitle,
                        style: TextStyle(
                            color: context.f3textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              if (!disabled)
                Icon(Icons.chevron_right_rounded, color: context.f3textMuted),
            ]),
          ),
        ),
      ),
    );
  }
}

/// PROF-01: the identity card — ported from SettingsScreen's former
/// `_ProfileBanner` (same F3-Nation-sync-on-open behavior and manual
/// F3-name field for an unlinked PAX), now living here instead so Settings
/// below is app preferences only.
class _IdentityCard extends StatefulWidget {
  const _IdentityCard();

  @override
  State<_IdentityCard> createState() => _IdentityCardState();
}

class _IdentityCardState extends State<_IdentityCard> {
  bool _synced = false;
  bool _syncing = false;

  bool _isLinked(AuthService auth) =>
      auth.currentUser?.identities
          .any((i) => i.provider == AuthProvider.f3nation) ??
      false;

  /// Schedules a sync if we're linked and haven't synced yet this session.
  /// Called from `build()` (via a post-frame callback, guarded by
  /// `_syncing`) rather than only once from `initState` — this hub is built
  /// once at app startup inside the tab shell's `IndexedStack` and never
  /// rebuilt from scratch, so an initState-only trigger can race
  /// `AuthService` still restoring its persisted session: if `_isLinked`
  /// reads false at that first-frame moment, the one-shot call bails and
  /// never retries. Reacting to the `Consumer2` rebuild instead catches the
  /// moment linked flips true, whenever that actually happens.
  void _maybeSync(bool linked) {
    if (!linked || _synced || _syncing) return;
    _syncing = true;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _syncFromF3().whenComplete(() {
              if (mounted) _syncing = false;
            }));
  }

  /// When the account is linked, quietly refresh the local profile from the
  /// F3 Nation database each time this hub opens — their DB is the source
  /// of truth for F3 name, region, and avatar.
  Future<void> _syncFromF3() async {
    final auth = context.read<AuthService>();
    final api = context.read<F3ApiService>();
    final profile = context.read<AppProfileService>();
    if (!_isLinked(auth)) return;

    final token = await auth.getF3AccessToken();
    if (token == null) return;
    final f3 = await api.getMyProfile(userAccessToken: token);
    if (f3 == null || !mounted) return;

    await profile.applyF3Profile(
      f3Name: f3.displayName,
      region: f3.homeRegionName,
      avatarUrl: f3.avatarUrl,
      homeRegionId: f3.homeRegionId,
      // The real F3 Nation numeric user id — every write (HC, take-Q,
      // preblast, Schedule's calendar query) needs this, not the local
      // guest-account id `authUserId` defaults to before this ever ran.
      f3UserId: f3.id,
    );
    // Feed the per-user region into the API client so upcoming beatdowns and
    // Slack routing target this PAX's own region, not the build default.
    api.userOrgId = f3.homeRegionId;
    if (mounted) setState(() => _synced = true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProfileService, AuthService>(
      builder: (context, profile, auth, _) {
        _maybeSync(_isLinked(auth));
        final name = profile.displayName.isEmpty ? 'PAX' : profile.displayName;
        final linked = _isLinked(auth);
        final banner = Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: context.f3card,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: F3Colors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const SelfAvatar(size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${greetingFor(AppLocalizations.of(context)!)},',
                            style: TextStyle(
                                color: context.f3textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        Text(name,
                            style: TextStyle(
                                color: context.f3textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 18)),
                        if (profile.homeAo.isNotEmpty)
                          Text(profile.homeAo,
                              style: TextStyle(
                                  color: context.f3textSecondary,
                                  fontSize: 13)),
                        if (profile.region.isNotEmpty)
                          Text(profile.region,
                              style: TextStyle(
                                  color: context.f3textMuted, fontSize: 12)),
                        if (linked)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(
                                  _synced
                                      ? Icons.verified_rounded
                                      : Icons.sync_rounded,
                                  color: F3Colors.accent,
                                  size: 13),
                              const SizedBox(width: 4),
                              Text(
                                _synced
                                    ? 'Synced with F3 Nation'
                                    : 'Linked to F3 Nation',
                                style: const TextStyle(
                                    color: F3Colors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700),
                              ),
                            ]),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: context.f3textMuted),
                ]),
              ),
            ),
          ),
        );

        // Manual F3-name field only when we don't already have it from the
        // signed-in F3 Nation profile — no point asking twice.
        final manualNameField = profile.displayName.isNotEmpty
            ? const SizedBox.shrink()
            : Consumer<SettingsService>(
                builder: (context, service, _) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    initialValue: service.myF3Name,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.settingsMyF3Name,
                      hintText:
                          AppLocalizations.of(context)!.settingsMyF3NameHint,
                      prefixIcon: const Icon(Icons.badge_rounded),
                    ),
                    onChanged: (val) => service.setMyF3Name(val.trim()),
                  ),
                ),
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [banner, manualNameField],
        );
      },
    );
  }
}
