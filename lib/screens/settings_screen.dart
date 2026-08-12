// lib/screens/settings_screen.dart
// Workout generation settings: coupon mode, intensity filter.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_version.dart';
import 'package:share_plus/share_plus.dart';
import '../models/auth_models.dart';
import 'admin_location_screen.dart';
import '../services/app_profile_service.dart' hide AppRole;
import '../services/auth_service.dart';
import '../services/codex_sync_service.dart';
import '../services/exercise_service.dart';
import '../services/history_service.dart';
import '../services/local_app_lock_service.dart';
import '../services/local_backup_service.dart';
import '../services/music_launcher.dart';
import '../services/region_service.dart';
import '../services/f3_api_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../utils/greeting.dart';
import '../widgets/f3_glossary_sheet.dart';
import '../widgets/theme_language_picker.dart';
import 'profile_screen.dart';
import 'emergency_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        backgroundColor: context.f3bg,
      ),
      body: Consumer<SettingsService>(
        builder: (context, service, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Profile banner ────────────────────────────────────────────
              // Already shows linked/synced status and (via Profile) email —
              // a separate F3 Nation account card here was pure duplication.
              const _ProfileBanner(isQ: true),

              const SizedBox(height: 20),

              // Manual F3 name field only when we don't already have it from
              // the signed-in F3 Nation profile — no point asking twice.
              Consumer<AppProfileService>(
                builder: (context, profile, _) {
                  if (profile.displayName.isNotEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextFormField(
                      initialValue: service.myF3Name,
                      decoration: InputDecoration(
                        labelText: l10n.settingsMyF3Name,
                        hintText: l10n.settingsMyF3NameHint,
                        prefixIcon: const Icon(Icons.badge_rounded),
                      ),
                      onChanged: (val) => service.setMyF3Name(val.trim()),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // ── Appearance ────────────────────────────────────────────────
              _SectionHeader(l10n.settingsAppearance),
              const SizedBox(height: 8),
              ThemePicker(
                current: service.themeMode,
                onSelect: (mode) => service.setThemeMode(mode),
              ),
              const SizedBox(height: 12),
              LanguagePicker(
                current: service.locale.languageCode,
                onSelect: (code) => service.setLocale(Locale(code)),
              ),
              const SizedBox(height: 28),

              // ── Voice & Accessibility ───────────────────────────────────────
              _SectionHeader(l10n.settingsVoiceAccessibility),
              const SizedBox(height: 8),
              _SwitchRow(
                label: l10n.settingsEnableVoiceCallouts,
                subtitle: l10n.settingsVoiceCalloutsDesc,
                value: service.voiceEnabled,
                onChanged: (val) => service.updateVoiceEnabled(val),
              ),
              if (service.voiceEnabled) ...[
                const SizedBox(height: 8),
                _VoiceSelector(
                  currentVoice: service.ttsVoice,
                  onVoiceSelected: (v) => service.setTtsVoice(v),
                ),
              ],
              const SizedBox(height: 8),
              _SwitchRow(
                label: l10n.settingsReducedMotion,
                subtitle: l10n.settingsReducedMotionDesc,
                value: service.reducedMotion,
                onChanged: (val) => service.updateReducedMotion(val),
              ),
              const SizedBox(height: 28),

              // ── Music ─────────────────────────────────────────────────────
              _SectionHeader(l10n.settingsMusic),
              const SizedBox(height: 8),
              _SwitchRow(
                label: l10n.settingsLaunchMusic,
                subtitle: l10n.settingsLaunchMusicDesc,
                value: service.musicEnabled,
                onChanged: (val) => service.setMusicEnabled(val),
              ),
              if (service.musicEnabled) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<MusicProvider>(
                  initialValue: service.musicProvider,
                  dropdownColor: context.f3card,
                  decoration: InputDecoration(
                    labelText: l10n.settingsMusicProvider,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(10),
                      child: _MusicProviderIcon(service.musicProvider),
                    ),
                  ),
                  items: MusicProvider.values.map((p) => DropdownMenuItem(
                    value: p,
                    child: Row(children: [
                      _MusicProviderIcon(p),
                      const SizedBox(width: 10),
                      Text(p.displayName),
                    ]),
                  )).toList(),
                  // Collapsed field is text-only — the prefixIcon already
                  // shows the provider icon, so the item's own icon would
                  // render it twice.
                  selectedItemBuilder: (context) => MusicProvider.values
                      .map((p) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(p.displayName),
                          ))
                      .toList(),
                  onChanged: (p) { if (p != null) service.setMusicProvider(p); },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: service.musicPlaylistUrl,
                  decoration: InputDecoration(
                    labelText: l10n.settingsPlaylistUrl,
                    hintText: l10n.settingsPlaylistUrlHint,
                    prefixIcon: const Icon(Icons.link_rounded),
                  ),
                  onChanged: (val) => service.setMusicPlaylistUrl(val.trim()),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    l10n.settingsPlaylistUrlHelp,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // ── Safety ────────────────────────────────────────────────────
              _SectionHeader(l10n.settingsSafety),
              const SizedBox(height: 8),
              // App Lock was previously only ever settable once, during
              // first-run onboarding — anyone who skipped it there had no
              // way back in short of reinstalling. This is the only place
              // it can be turned on (or off) after the fact.
              const _AppLockToggle(),
              const SizedBox(height: 8),
              _NavTile(
                icon: Icons.emergency_rounded,
                title: l10n.settingsEmergencyInfo,
                subtitle: l10n.settingsEmergencyInfoSub,
                color: Colors.redAccent,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EmergencyScreen())),
              ),
              const SizedBox(height: 28),

              // ── Data ──────────────────────────────────────────────────────
              _SectionHeader(l10n.settingsData),
              const SizedBox(height: 8),
              _NavTile(
                icon: Icons.info_outline_rounded,
                title: l10n.settingsDataFlow,
                subtitle: l10n.settingsDataFlowSub,
                color: F3Colors.catMary,
                onTap: () => showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(l10n.settingsDataFlowConfirmTitle),
                    content: Text(l10n.settingsDataFlowConfirmBody),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _NavTile(
                icon: Icons.upload_rounded,
                title: l10n.settingsExportBackup,
                subtitle: l10n.settingsExportBackupSub,
                color: F3Colors.catBodyweight,
                onTap: () async {
                  final profile = context.read<AppProfileService>();
                  final history = context.read<HistoryService>();
                  final region  = context.read<RegionService>();
                  final json = LocalBackupService.exportJson(
                    profile: profile,
                    history: history,
                    region: region,
                  );
                  await Share.share(json, subject: 'Digital Weinke Backup');
                },
              ),
              const SizedBox(height: 8),
              _NavTile(
                icon: Icons.download_rounded,
                title: l10n.settingsImportBackup,
                subtitle: l10n.settingsImportBackupSub,
                color: F3Colors.catCoupon,
                onTap: () async {
                  final profile   = context.read<AppProfileService>();
                  final history   = context.read<HistoryService>();
                  final region    = context.read<RegionService>();
                  final messenger = ScaffoldMessenger.of(context);
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (!messenger.mounted) return;
                  final raw = data?.text ?? '';
                  if (raw.isEmpty) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.settingsClipboardEmpty)),
                    );
                    return;
                  }
                  if (!context.mounted) return;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(l10n.settingsImportBackupConfirmTitle),
                      content: Text(l10n.settingsImportBackupConfirmBody),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('CANCEL'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  try {
                    await LocalBackupService.importJson(
                      raw: raw,
                      profile: profile,
                      history: history,
                      region: region,
                    );
                    if (!messenger.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.settingsBackupImported)),
                    );
                  } catch (e) {
                    if (!messenger.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.settingsImportFailed('$e'))),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              _NavTile(
                icon: Icons.history_toggle_off_rounded,
                title: l10n.settingsAutoBackupRestore,
                subtitle: l10n.settingsAutoBackupRestoreSub,
                color: F3Colors.catMary,
                onTap: () => _showAutoBackupSheet(context),
              ),
              const SizedBox(height: 8),
              _NavTile(
                icon: Icons.delete_forever_rounded,
                title: l10n.settingsDeleteAllData,
                subtitle: l10n.settingsDeleteAllDataSub,
                color: Colors.red.shade700,
                onTap: () => _confirmDeleteAllData(context),
              ),
              const SizedBox(height: 28),

              // ── F3 Nation ─────────────────────────────────────────────────
              const _F3NationLinksSection(),

              // ── About ─────────────────────────────────────────────────────
              _SectionHeader(l10n.settingsAbout),
              const SizedBox(height: 8),
              _NavTile(
                icon: Icons.menu_book_rounded,
                title: l10n.settingsF3Glossary,
                subtitle: l10n.settingsF3GlossarySub,
                color: F3Colors.catCoupon,
                onTap: () => showF3GlossarySheet(context),
              ),
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final count = context
                    .watch<HistoryService>()
                    .all
                    .where((e) => !e.isTemplate)
                    .length;
                if (count == 0) return const SizedBox.shrink();
                return _InfoTile(
                  icon: Icons.local_fire_department_rounded,
                  title: l10n.settingsBeatdownsPlanned(count),
                  subtitle: l10n.settingsBeatdownsPlannedSub,
                );
              }),
              const _VersionTile(),
              _InfoTile(
                icon: Icons.fitness_center_rounded,
                title: l10n.settingsExiconCount,
                subtitle: l10n.settingsExiconCountSub,
              ),
              const _CodexSyncTile(),
              _InfoTile(
                icon: Icons.wifi_off_rounded,
                title: l10n.settingsFullyOffline,
                subtitle: l10n.settingsFullyOfflineSub,
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _confirmDeleteAllData(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.settingsDeleteAllDataConfirmTitle),
      content: Text(l10n.settingsDeleteAllDataConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
          child: const Text('DELETE EVERYTHING'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  // Local-only wipe — this app has no F3 Nation account-deletion capability
  // of its own, only what's stored on this device (history, achievements,
  // custom exercises, EH prospects, tokens, emergency info, settings).
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  await const FlutterSecureStorage().deleteAll();

  if (!messenger.mounted) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(l10n.settingsDeleteAllDataDone),
      duration: const Duration(seconds: 8),
    ),
  );
}

Future<void> _showAutoBackupSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final profile = context.read<AppProfileService>();
  final history = context.read<HistoryService>();
  final region = context.read<RegionService>();
  final messenger = ScaffoldMessenger.of(context);
  final backups = await LocalBackupService.listAutoBackups();
  if (!context.mounted) return;

  final localeCode = Localizations.localeOf(context).languageCode;
  String label(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final period = d.hour < 12 ? 'AM' : 'PM';
    final m = d.minute.toString().padLeft(2, '0');
    return '${shortMonthDayYear(d, localeCode)} · $h:$m $period';
  }

  await showModalBottomSheet(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: backups.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.settingsAutoBackupNone,
                  style: TextStyle(color: sheetContext.f3textSecondary)),
            )
          : ListView(
              shrinkWrap: true,
              children: [
                for (final file in backups)
                  ListTile(
                    leading: const Icon(Icons.restore_rounded),
                    title: Text(
                      label(LocalBackupService.autoBackupTimestamp(file) ??
                          DateTime.now()),
                    ),
                    onTap: () async {
                      final timestamp =
                          LocalBackupService.autoBackupTimestamp(file) ??
                              DateTime.now();
                      final confirmed = await showDialog<bool>(
                        context: sheetContext,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(l10n.settingsAutoBackupConfirmTitle),
                          content: Text(l10n
                              .settingsAutoBackupConfirmBody(label(timestamp))),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('CANCEL'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      await LocalBackupService.restoreAutoBackup(
                        file: file,
                        profile: profile,
                        history: history,
                        region: region,
                      );
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                      if (messenger.mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                              content:
                                  Text(l10n.settingsAutoBackupRestored)),
                        );
                      }
                    },
                  ),
              ],
            ),
    ),
  );
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.f3card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.f3divider),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      color: context.f3textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              Text(subtitle,
                  style: TextStyle(
                      color: context.f3textSecondary, fontSize: 12)),
            ]),
          ),
          Icon(Icons.chevron_right_rounded,
              color: context.f3textMuted, size: 20),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: context.f3textMuted,
            letterSpacing: 1.5,
          ),
    );
  }
}

// ── F3 Nation links ───────────────────────────────────────────────────────────
// From the real apps.f3nation.com tool directory (confirmed URLs, 2026-08-12).
// "Everyday Use" tools need no special access — anyone can open them. "Region
// Admins" tools are gated behind an actual editor/admin role on the signed-in
// user's F3 Nation profile, not just a manual toggle. Slack Bot/SyncBot are
// deliberately left out — they're documentation links, not tools to open.

class _F3NationLinksSection extends StatefulWidget {
  const _F3NationLinksSection();

  @override
  State<_F3NationLinksSection> createState() => _F3NationLinksSectionState();
}

class _F3NationLinksSectionState extends State<_F3NationLinksSection> {
  bool _checked = false;
  bool _checking = false;
  bool _isAdmin = false;

  bool _isLinked(AuthService auth) =>
      auth.currentUser?.identities
          .any((i) => i.provider == AuthProvider.f3nation) ??
      false;

  void _maybeCheck(bool linked) {
    if (!linked || _checked || _checking) return;
    _checking = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAdmin().whenComplete(() {
          if (mounted) _checking = false;
        }));
  }

  /// Role-name casing hasn't been confirmed against a live payload (only an
  /// illustrative doc comment exists), so this checks case-insensitively
  /// rather than trusting an exact string match.
  Future<void> _checkAdmin() async {
    final auth = context.read<AuthService>();
    final api = context.read<F3ApiService>();
    if (!_isLinked(auth)) return;
    final token = await auth.getF3AccessToken();
    if (token == null) return;
    final f3 = await api.getMyProfile(userAccessToken: token);
    if (f3 == null || !mounted) return;
    final isAdmin = f3.roles.any((r) {
      final name = r.roleName.toLowerCase();
      return name == 'editor' || name == 'admin';
    });
    setState(() {
      _isAdmin = isAdmin;
      _checked = true;
    });
  }

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        _maybeCheck(_isLinked(auth));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader('F3 NATION'),
            const SizedBox(height: 8),
            _NavTile(
              icon: Icons.map_rounded,
              title: 'F3 Map',
              subtitle: 'Every workout group across the nation',
              color: const Color(0xFF2196F3),
              onTap: () => _open('https://map.f3nation.com'),
            ),
            const SizedBox(height: 8),
            _NavTile(
              icon: Icons.near_me_rounded,
              title: 'F3 Near Me',
              subtitle: 'Fast map to find a workout — no account needed',
              color: F3Colors.catBodyweight,
              onTap: () => _open('https://f3near.me'),
            ),
            const SizedBox(height: 8),
            _NavTile(
              icon: Icons.badge_rounded,
              title: 'F3 Me',
              subtitle: 'Your official F3 Nation profile',
              color: F3Colors.phaseMary,
              onTap: () => _open('https://me.f3nation.com'),
            ),
            const SizedBox(height: 8),
            _NavTile(
              icon: Icons.bar_chart_rounded,
              title: 'PAX Vault',
              subtitle: 'Region analytics — participation, attendance trends',
              color: F3Colors.catCoupon,
              onTap: () => _open('https://pax-vault.f3nation.com'),
            ),
            const SizedBox(height: 8),
            _NavTile(
              icon: Icons.menu_book_rounded,
              title: 'The Codex',
              subtitle: 'Live F3 Exicon & Lexicon on the web',
              color: F3Colors.catWarmup,
              onTap: () => _open('https://codex.f3nation.com'),
            ),
            const SizedBox(height: 8),
            _NavTile(
              icon: Icons.account_tree_rounded,
              title: 'Org Chart',
              subtitle: 'Sectors, Areas, and Regions on a map',
              color: F3Colors.accent,
              onTap: () => _open('https://org.f3nation.com'),
            ),
            if (_isAdmin) ...[
              const SizedBox(height: 28),
              const _SectionHeader('ADMIN TOOLS'),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "Visible because your F3 Nation account has an editor/admin role.",
                  style: TextStyle(color: context.f3textMuted, fontSize: 11.5),
                ),
              ),
              _NavTile(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Admin Portal',
                subtitle: 'Manage locations, events, and org settings',
                color: Colors.red.shade700,
                onTap: () => _open('https://admin.f3nation.com'),
              ),
              const SizedBox(height: 8),
              _NavTile(
                icon: Icons.edit_location_alt_rounded,
                title: 'Edit AO Location',
                subtitle: "Edit an AO's address, coordinates, and details — right here in the app",
                color: F3Colors.catBodyweight,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLocationsScreen()),
                ),
              ),
              const SizedBox(height: 8),
              _NavTile(
                icon: Icons.web_rounded,
                title: 'Region Pages',
                subtitle: 'Calendars, member directories, contact info',
                color: F3Colors.phaseCOT,
                onTap: () => _open('https://regions.f3nation.com'),
              ),
              const SizedBox(height: 8),
              _NavTile(
                icon: Icons.health_and_safety_rounded,
                title: 'Status',
                subtitle: "Check if F3 Nation's own services are down",
                color: F3Colors.catMary,
                onTap: () => _open('https://status.f3nation.com'),
              ),
            ],
            const SizedBox(height: 28),
          ],
        );
      },
    );
  }
}

// ── Profile banner ───────────────────────────────────────────────────────────

class _ProfileBanner extends StatefulWidget {
  final bool isQ;
  const _ProfileBanner({required this.isQ});

  @override
  State<_ProfileBanner> createState() => _ProfileBannerState();
}

class _ProfileBannerState extends State<_ProfileBanner> {
  bool _synced = false;
  bool _syncing = false;

  bool _isLinked(AuthService auth) =>
      auth.currentUser?.identities
          .any((i) => i.provider == AuthProvider.f3nation) ??
      false;

  /// Schedules a sync if we're linked and haven't synced yet this session.
  /// Called from `build()` (via a post-frame callback, guarded by
  /// `_syncing`) rather than only once from `initState` — `SettingsScreen`
  /// is built once at app startup inside the tab shell's `IndexedStack` and
  /// never rebuilt from scratch, so an initState-only trigger can race
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
  /// F3 Nation database each time Settings opens — their DB is the source of
  /// truth for F3 name, region, and avatar.
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
        final name =
            profile.displayName.isEmpty ? 'PAX' : profile.displayName;
        final linked = _isLinked(auth);
        final banner = Container(
          margin: const EdgeInsets.only(bottom: 24),
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
            // Avatar: local photo → F3 Nation avatar → shield. The whole
            // card (not just this image) opens the full profile — see the
            // InkWell wrapping `banner` below.
            () {
              ImageProvider? img;
              if (profile.localAvatarPath.isNotEmpty &&
                  File(profile.localAvatarPath).existsSync()) {
                img = FileImage(File(profile.localAvatarPath));
              } else if (profile.avatarUrl.isNotEmpty) {
                img = NetworkImage(profile.avatarUrl);
              }
              return CircleAvatar(
                radius: 26,
                backgroundColor: F3Colors.accent.withValues(alpha: 0.14),
                foregroundImage: img,
                onForegroundImageError: img != null ? (e, s) {} : null,
                child: img == null
                    ? const Icon(Icons.shield_rounded,
                        color: F3Colors.accent, size: 26)
                    : null,
              );
            }(),
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
                            color: context.f3textSecondary, fontSize: 13)),
                  if (profile.region.isNotEmpty)
                    Text(profile.region,
                        style: TextStyle(
                            color: context.f3textMuted, fontSize: 12)),
                  if (linked)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                            _synced
                                ? Icons.verified_rounded
                                : Icons.sync_rounded,
                            color: F3Colors.accent, size: 13),
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
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: F3Colors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.isQ ? 'Q' : 'PAX',
                style: const TextStyle(
                    color: F3Colors.accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1),
              ),
            ),
                ]),
              ),
            ),
          ),
        );

        // Pull down on the banner to force a re-sync from the F3 Nation DB.
        if (!linked) return banner;
        return RefreshIndicator(
          onRefresh: _syncFromF3,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            shrinkWrap: true,
            children: [banner],
          ),
        );
      },
    );
  }
}

class _AppLockToggle extends StatefulWidget {
  const _AppLockToggle();

  @override
  State<_AppLockToggle> createState() => _AppLockToggleState();
}

class _AppLockToggleState extends State<_AppLockToggle> {
  // null while checking, then true/false. Hidden entirely (matching the
  // onboarding setup page's own behavior) rather than shown-but-disabled
  // when the device has no biometric/PIN capability at all.
  bool? _supported;

  @override
  void initState() {
    super.initState();
    LocalAppLockService().isSupported.then((v) {
      if (mounted) setState(() => _supported = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_supported != true) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Consumer<AppProfileService>(
      builder: (context, profile, _) => _SwitchRow(
        label: l10n.onboardingAppLockTitle,
        subtitle: l10n.onboardingAppLockSubtitle,
        value: profile.appLockEnabled,
        onChanged: (val) => profile.setAppLockEnabled(val),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  const _SwitchRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.f3divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: context.f3textPrimary, fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(color: context.f3textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ── TTS Voice Selector ────────────────────────────────────────────────────────

class _VoiceSelector extends StatefulWidget {
  final String currentVoice;
  final void Function(String) onVoiceSelected;

  const _VoiceSelector({
    required this.currentVoice,
    required this.onVoiceSelected,
  });

  @override
  State<_VoiceSelector> createState() => _VoiceSelectorState();
}

class _VoiceSelectorState extends State<_VoiceSelector> {
  final FlutterTts _tts = FlutterTts();
  // (displayName, rawName) pairs
  List<(String, String)> _voices = [];
  bool _loading = true;
  String? _previewing;

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  /// A voice picker with no way to hear a voice before committing to it was
  /// exactly backwards — you found out what you picked only once you
  /// already needed it mid-workout. Speaks a fixed sample line in the
  /// tapped voice's own locale (derived from its raw name), not whatever
  /// language the app happens to be set to right now.
  Future<void> _previewVoice(String rawName, void Function(void Function()) setDialogState) async {
    setDialogState(() => _previewing = rawName);
    final parts = rawName.split(RegExp(r'[-_]'));
    final locale =
        parts.length >= 2 ? '${parts[0]}-${parts[1].toUpperCase()}' : 'en-US';
    try {
      await _tts.setVoice({'name': rawName, 'locale': locale});
      await _tts.speak('Starting Warm-O-Rama. Mosey up!');
    } catch (_) {
      // Best-effort — a preview failing silently is fine, the selection
      // flow below doesn't depend on it.
    } finally {
      if (mounted) setDialogState(() => _previewing = null);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    try {
      final raw = await _tts.getVoices;
      if (!mounted) return;

      // English-only, deduplicated
      final englishRaw = (raw as List)
          .map((v) => v is Map ? (v['name'] as String?) ?? '' : '')
          .where((name) {
            if (name.isEmpty) return false;
            final lower = name.toLowerCase();
            return lower.startsWith('en-') || lower.startsWith('en_');
          })
          .toSet()
          .toList()
        ..sort();

      // Group by sub-locale (EN-US, EN-GB, …)
      final Map<String, List<String>> byLocale = {};
      for (final name in englishRaw) {
        final parts = name.split(RegExp(r'[-_]'));
        if (parts.length >= 2) {
          final key = '${parts[0].toUpperCase()}-${parts[1].toUpperCase()}';
          byLocale.putIfAbsent(key, () => []).add(name);
        }
      }

      const localeOrder = ['EN-US', 'EN-GB', 'EN-AU', 'EN-IN', 'EN-CA', 'EN-ZA', 'EN-IE'];
      final known = localeOrder.where((l) => byLocale.containsKey(l)).toList();
      final others = byLocale.keys.where((l) => !localeOrder.contains(l)).toList()..sort();

      final List<(String, String)> pairs = [];
      for (final locale in [...known, ...others]) {
        final voices = byLocale[locale]!;
        final label = _localeName(locale).isNotEmpty ? _localeName(locale) : locale;
        for (int i = 0; i < voices.length; i++) {
          pairs.add(('$label — Voice ${i + 1}', voices[i]));
        }
      }

      setState(() {
        _voices = pairs;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _displayNameForVoice(String rawName) {
    if (rawName.isEmpty) return AppLocalizations.of(context)!.settingsSystemDefault;
    for (final (display, raw) in _voices) {
      if (raw == rawName) return display;
    }
    return rawName;
  }

  static String _localeName(String locale) {
    const map = {
      'EN-US': 'English (US)', 'EN-GB': 'English (UK)',
      'EN-AU': 'English (Australia)', 'EN-IN': 'English (India)',
      'EN-CA': 'English (Canada)', 'EN-IE': 'English (Ireland)',
      'EN-ZA': 'English (South Africa)',
      'ES-US': 'Spanish (US)', 'ES-ES': 'Spanish (Spain)',
      'ES-MX': 'Spanish (Mexico)', 'ES-419': 'Spanish (Latin America)',
      'FR-FR': 'French', 'FR-CA': 'French (Canada)',
      'DE-DE': 'German', 'IT-IT': 'Italian',
      'PT-BR': 'Portuguese (Brazil)', 'PT-PT': 'Portuguese',
      'JA-JP': 'Japanese', 'KO-KR': 'Korean',
      'ZH-CN': 'Chinese (Simplified)', 'ZH-TW': 'Chinese (Traditional)',
      'AR-SA': 'Arabic', 'HI-IN': 'Hindi', 'NL-NL': 'Dutch',
      'PL-PL': 'Polish', 'RU-RU': 'Russian', 'SV-SE': 'Swedish',
      'TR-TR': 'Turkish', 'NB-NO': 'Norwegian', 'DA-DK': 'Danish',
      'FI-FI': 'Finnish', 'CS-CZ': 'Czech', 'HU-HU': 'Hungarian',
      'RO-RO': 'Romanian', 'EL-GR': 'Greek', 'HE-IL': 'Hebrew',
      'TH-TH': 'Thai', 'ID-ID': 'Indonesian', 'VI-VN': 'Vietnamese',
    };
    return map[locale] ?? '';
  }

  void _pick(BuildContext context) {
    if (_voices.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.f3card,
        title: Text(l10n.settingsSelectTtsVoice,
            style: TextStyle(color: context.f3textPrimary, fontSize: 16)),
        content: StatefulBuilder(
          builder: (dialogCtx, setDialogState) => SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _voices.length,
              itemBuilder: (ctx, i) {
                final (displayName, rawName) = _voices[i];
                final selected = rawName == widget.currentVoice;
                final previewing = _previewing == rawName;
                return ListTile(
                  dense: true,
                  title: Text(displayName,
                      style: TextStyle(
                        color: selected ? F3Colors.accent : context.f3textPrimary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                        fontSize: 13,
                      )),
                  leading: IconButton(
                    tooltip: 'Preview this voice',
                    visualDensity: VisualDensity.compact,
                    icon: previewing
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: context.f3textMuted),
                          )
                        : Icon(Icons.play_circle_outline_rounded,
                            size: 20, color: context.f3textMuted),
                    onPressed: previewing
                        ? null
                        : () => _previewVoice(rawName, setDialogState),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check_rounded, color: F3Colors.accent, size: 18)
                      : null,
                  onTap: () => Navigator.pop(ctx, rawName),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: Text(l10n.settingsUseDefault),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.settingsCancel),
          ),
        ],
      ),
    ).then((picked) {
      if (picked != null) widget.onVoiceSelected(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = _displayNameForVoice(widget.currentVoice);
    return GestureDetector(
      onTap: _loading ? null : () => _pick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.f3card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.f3divider),
        ),
        child: Row(children: [
          Icon(Icons.record_voice_over_rounded, color: context.f3textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.settingsTtsVoice,
                  style: TextStyle(color: context.f3textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              Text(
                _loading ? l10n.settingsLoadingVoices : label,
                style: TextStyle(color: context.f3textMuted, fontSize: 12),
              ),
            ]),
          ),
          if (_loading)
            SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: context.f3textMuted))
          else
            Icon(Icons.chevron_right_rounded, color: context.f3textMuted, size: 20),
        ]),
      ),
    );
  }
}


// ── Info tile + tappable version tile ────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _InfoTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.f3card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.f3divider),
        ),
        child: Row(children: [
          Icon(icon, color: context.f3textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: context.f3textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle, style: TextStyle(color: context.f3textMuted, fontSize: 12)),
          ])),
        ]),
      ),
    );
  }
}

// ── Codex sync ────────────────────────────────────────────────────────────────
// Manual, on-demand only — no background network calls, matching the app's
// offline-first default. Pulls demo video links + confirms which custom
// exercises now match the real, live Exicon (see CodexSyncService).

class _CodexSyncTile extends StatefulWidget {
  const _CodexSyncTile();

  @override
  State<_CodexSyncTile> createState() => _CodexSyncTileState();
}

class _CodexSyncTileState extends State<_CodexSyncTile> {
  bool _syncing = false;
  String? _resultMessage;

  Future<void> _sync() async {
    setState(() {
      _syncing = true;
      _resultMessage = null;
    });
    final exerciseSvc = context.read<ExerciseService>();
    final codexSvc = context.read<CodexSyncService>();
    final result = await codexSvc.sync(exerciseSvc.all);
    if (!mounted) return;
    if (result == null) {
      setState(() {
        _syncing = false;
        _resultMessage = "Couldn't reach the Codex — check your connection.";
      });
      return;
    }
    exerciseSvc.applyVideoLinks(codexSvc.videoLinksByName);
    exerciseSvc.applyLiveExiconNames(codexSvc.liveExiconNames);
    setState(() {
      _syncing = false;
      _resultMessage = 'Found demo videos for ${result.matched} of '
          '${result.total} exercises.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final codexSvc = context.watch<CodexSyncService>();
    final lastSynced = codexSvc.lastSyncedAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.f3card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.f3divider),
        ),
        child: Row(children: [
          Icon(Icons.sync_rounded, color: context.f3textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sync with Official Codex',
                    style: TextStyle(
                        color: context.f3textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text(
                  _resultMessage ??
                      (lastSynced == null
                          ? 'Never synced — pulls demo videos and confirms official exercises'
                          : 'Last synced ${shortMonthDayYear(lastSynced, Localizations.localeOf(context).languageCode)}'),
                  style: TextStyle(color: context.f3textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _syncing
              ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton(
                  onPressed: _sync,
                  child: const Text('SYNC'),
                ),
        ]),
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile();

  static const _kPageSize = 3;

  void _showChangelog(BuildContext context) {
    int visibleCount = _kPageSize;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.f3card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => StatefulBuilder(
          builder: (context, setState) {
            const all = AppVersion.releases;
            final shownCount = visibleCount.clamp(0, all.length);
            final hasMore = shownCount < all.length;
            return Column(children: [
              Container(
                width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: context.f3divider, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(children: [
                  Icon(Icons.history_rounded, color: F3Colors.accent, size: 22),
                  SizedBox(width: 10),
                  Text(AppLocalizations.of(context)!.changelogTitle,
                      style: TextStyle(color: context.f3textPrimary, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ]),
              ),
              Divider(color: context.f3divider, height: 1),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  itemCount: shownCount + (hasMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i < shownCount) {
                      return _ReleaseCard(release: all[i]);
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: OutlinedButton(
                        onPressed: () =>
                            setState(() => visibleCount += _kPageSize),
                        child: Text(
                            'Show ${(all.length - shownCount).clamp(0, _kPageSize)} more'),
                      ),
                    );
                  },
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _showChangelog(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.f3card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: F3Colors.accent.withValues(alpha: 0.35)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, color: F3Colors.accent, size: 20),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppVersion.displayName,
                  style: TextStyle(color: context.f3textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
              Text(AppLocalizations.of(context)!.settingsTapToSeeWhatsNew,
                  style: TextStyle(color: F3Colors.accent, fontSize: 12)),
            ])),
            Icon(Icons.chevron_right_rounded, color: F3Colors.accent, size: 20),
          ]),
        ),
      ),
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  final AppRelease release;
  const _ReleaseCard({required this.release});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: F3Colors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('v${release.version}',
                style: const TextStyle(color: F3Colors.accent, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(release.title,
              style: TextStyle(color: context.f3textPrimary, fontWeight: FontWeight.w700, fontSize: 14))),
        ]),
        const SizedBox(height: 6),
        Text(release.summary,
            style: TextStyle(color: context.f3textSecondary, fontSize: 13, height: 1.4)),
        if (release.newItems.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ChangeGroup('NEW', F3Colors.phaseWarmup, release.newItems),
        ],
        if (release.enhancements.isNotEmpty) ...[
          const SizedBox(height: 6),
          _ChangeGroup('IMPROVED', F3Colors.catBodyweight, release.enhancements),
        ],
        if (release.bugFixes.isNotEmpty) ...[
          const SizedBox(height: 6),
          _ChangeGroup('FIXED', F3Colors.phaseMary, release.bugFixes),
        ],
      ]),
    );
  }
}


class _ChangeGroup extends StatelessWidget {
  final String label;
  final Color color;
  final List<String> items;
  const _ChangeGroup(this.label, this.color, this.items);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
      const SizedBox(height: 4),
      ...items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('· ', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          Expanded(child: Text(item, style: TextStyle(color: context.f3textSecondary, fontSize: 13, height: 1.4))),
        ]),
      )),
    ]);
  }
}

// ── Music provider branded icon ───────────────────────────────────────────────

class _MusicProviderIcon extends StatelessWidget {
  final MusicProvider provider;
  const _MusicProviderIcon(this.provider);

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (provider) {
      MusicProvider.spotify      => (const Color(0xFF1DB954), Icons.graphic_eq_rounded),
      MusicProvider.appleMusic   => (const Color(0xFFFC3C44), Icons.music_note_rounded),
      MusicProvider.youtubeMusic => (const Color(0xFFFF0000), Icons.play_circle_filled_rounded),
      MusicProvider.amazonMusic  => (const Color(0xFF00A8E0), Icons.library_music_rounded),
      MusicProvider.custom       => (Colors.grey, Icons.link_rounded),
    };
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Icon(icon, color: Colors.white, size: 14),
    );
  }
}
