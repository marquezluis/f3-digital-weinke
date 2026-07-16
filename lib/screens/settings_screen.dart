// lib/screens/settings_screen.dart
// Workout generation settings: coupon mode, intensity filter.

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_version.dart';
import 'package:share_plus/share_plus.dart';
import '../models/auth_models.dart';
import '../models/exercise.dart';
import '../models/workout_settings.dart';
import '../services/app_profile_service.dart' hide AppRole;
import '../services/auth_service.dart';
import '../services/history_service.dart';
import '../services/local_backup_service.dart';
import '../services/music_launcher.dart';
import '../services/region_service.dart';
import '../services/f3_api_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../utils/greeting.dart';
import 'achievements_screen.dart';
import 'browse_aos_screen.dart';
import 'deck_of_pain_screen.dart';
import 'heatmap_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: context.f3bg,
      ),
      body: Consumer<SettingsService>(
        builder: (context, service, _) {
          final settings = service.settings;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Profile banner ────────────────────────────────────────────
              _ProfileBanner(isQ: service.appRole == AppRole.q),

              // ── Coupon Mode ───────────────────────────────────────────────
              const _SectionHeader('COUPON / EQUIPMENT'),
              const SizedBox(height: 8),
              _SegmentedRow<CouponMode>(
                options: CouponMode.values,
                selected: settings.couponMode,
                label: (m) => m.displayName,
                onSelect: (m) =>
                    service.update(settings.copyWith(couponMode: m)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Controls whether coupon (weighted) exercises appear in '
                  'The Thang. "Mixed" splits it 50/50.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

              const SizedBox(height: 28),

              // ── App Role ──────────────────────────────────────────────────
              const _SectionHeader('YOUR ROLE'),
              const SizedBox(height: 8),
              _SegmentedRow<AppRole>(
                options: AppRole.values,
                selected: service.appRole,
                label: (r) => r == AppRole.q ? 'Q (Leader)' : 'PAX (Member)',
                onSelect: (r) => service.updateRole(r),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Adjusts the app interface. Qs get planning tools; PAX get a simplified view.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

              const SizedBox(height: 12),
              TextFormField(
                initialValue: service.myF3Name,
                decoration: const InputDecoration(
                  labelText: 'My F3 Name',
                  hintText: 'Your F3 handle (auto-fills the Q field)',
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
                onChanged: (val) => service.setMyF3Name(val.trim()),
              ),

              const SizedBox(height: 28),

              // ── Appearance ────────────────────────────────────────────────
              const _SectionHeader('APPEARANCE'),
              const SizedBox(height: 8),
              _ThemePicker(
                current: service.themeMode,
                onSelect: (mode) => service.setThemeMode(mode),
              ),
              const SizedBox(height: 12),
              _LanguagePicker(
                current: service.locale.languageCode,
                onSelect: (code) => service.setLocale(Locale(code)),
              ),
              const SizedBox(height: 28),

              // ── Voice & Accessibility ───────────────────────────────────────
              const _SectionHeader('VOICE & ACCESSIBILITY'),
              const SizedBox(height: 8),
              _SwitchRow(
                label: 'Enable Voice Callouts',
                subtitle: 'TTS for phase changes and exercises.',
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
                label: 'Reduced Motion',
                subtitle: 'Disables non-essential animations.',
                value: service.reducedMotion,
                onChanged: (val) => service.updateReducedMotion(val),
              ),
              const SizedBox(height: 28),

              // ── Intensity ─────────────────────────────────────────────────
              const _SectionHeader('INTENSITY LEVELS'),
              const SizedBox(height: 8),
              ...Intensity.values.map((intensity) {
                final enabled = settings.intensities.contains(intensity);
                final color = F3Colors.forIntensity(intensity.name);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      final current = Set<Intensity>.from(settings.intensities);
                      if (enabled) {
                        // Don't allow disabling all
                        if (current.length > 1) current.remove(intensity);
                      } else {
                        current.add(intensity);
                      }
                      service.update(settings.copyWith(intensities: current));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        color: enabled
                            ? color.withValues(alpha: 0.12)
                            : context.f3card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: enabled
                              ? color.withValues(alpha: 0.6)
                              : context.f3divider,
                          width: enabled ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: enabled ? color : context.f3textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              intensity.displayName,
                              style: TextStyle(
                                color: enabled
                                    ? context.f3textPrimary
                                    : context.f3textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          if (enabled)
                            Icon(Icons.check_rounded,
                                color: color, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Select which difficulty levels to include. '
                  'At least one must remain active.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

              const SizedBox(height: 28),

              // -- F3 Nation Account ---------------------------------------------------
              const _SectionHeader('F3 NATION ACCOUNT'),
              const SizedBox(height: 8),
              const _F3NationAccountCard(),
              const SizedBox(height: 28),

              // -- Slack Integration -------------------------------------------------
              const _SectionHeader('SLACK INTEGRATION'),
              const SizedBox(height: 8),
              Consumer<F3ApiService>(
                builder: (context, api, _) {
                  if (api.isConfigured) {
                    // API path: user pastes channel ID once; F3 Nation app delivers.
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      TextFormField(
                        initialValue: service.slackChannelId,
                        decoration: const InputDecoration(
                          labelText: 'Slack Channel ID',
                          hintText: 'C0XXXXXXXX  (right-click channel → Copy link)',
                          prefixIcon: Icon(Icons.tag_rounded),
                        ),
                        onChanged: (val) => service.updateSlackChannelId(val.trim()),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Text(
                          'Posts directly to your region\'s Slack via the F3 Nation app — no webhook setup needed.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ]);
                  }
                  // Fallback: manual webhook URL.
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    TextFormField(
                      initialValue: service.slackWebhookUrl,
                      decoration: const InputDecoration(
                        labelText: 'Slack Webhook URL',
                        hintText: 'Paste your Incoming Webhook URL here',
                        prefixIcon: Icon(Icons.link_rounded),
                      ),
                      onChanged: (val) => service.updateSlackWebhookUrl(val.trim()),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Text(
                        'Enables the "Post to Slack" button on the backblast screen.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ]);
                },
              ),
              const SizedBox(height: 28),

              // ── Music ─────────────────────────────────────────────────────
              const _SectionHeader('MUSIC'),
              const SizedBox(height: 8),
              _SwitchRow(
                label: 'Launch music on workout start',
                subtitle: 'Opens your music app when you tap START WORKOUT.',
                value: service.musicEnabled,
                onChanged: (val) => service.setMusicEnabled(val),
              ),
              if (service.musicEnabled) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<MusicProvider>(
                  initialValue: service.musicProvider,
                  dropdownColor: context.f3card,
                  decoration: InputDecoration(
                    labelText: 'Music Provider',
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
                  onChanged: (p) { if (p != null) service.setMusicProvider(p); },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: service.musicPlaylistUrl,
                  decoration: const InputDecoration(
                    labelText: 'Playlist URL (optional)',
                    hintText: 'Paste a Spotify / Apple Music / YouTube link',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                  onChanged: (val) => service.setMusicPlaylistUrl(val.trim()),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    'Leave blank to just open the app. Paste a share link to jump straight to your beatdown playlist.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // ── Explore ───────────────────────────────────────────────────
              const _SectionHeader('EXPLORE'),
              const SizedBox(height: 8),
              _NavTile(
                icon: Icons.whatshot_rounded,
                title: 'Activity Heatmap',
                subtitle: '52-week workout calendar',
                color: F3Colors.phaseThang,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HeatmapScreen())),
              ),
              const SizedBox(height: 8),
              _NavTile(
                icon: Icons.emoji_events_rounded,
                title: 'Achievements',
                subtitle: 'Badges earned from your history',
                color: const Color(0xFFFFD700),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AchievementsScreen())),
              ),
              const SizedBox(height: 8),
              _NavTile(
                icon: Icons.explore_rounded,
                title: 'Browse AOs',
                subtitle: 'Find F3 Nation AOs near you',
                color: const Color(0xFF2196F3),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BrowseAosScreen())),
              ),
              const SizedBox(height: 8),
              _NavTile(
                icon: Icons.style_rounded,
                title: 'Deck of Pain',
                subtitle: 'Draw a card, do the work',
                color: const Color(0xFFE53935),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DeckOfPainScreen())),
              ),
              const SizedBox(height: 28),

              // ── Data ──────────────────────────────────────────────────────
              const _SectionHeader('DATA'),
              const SizedBox(height: 8),
              _NavTile(
                icon: Icons.upload_rounded,
                title: 'Export Backup',
                subtitle: 'Share all sessions as a JSON file',
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
                title: 'Import Backup',
                subtitle: 'Paste backup JSON from clipboard',
                color: F3Colors.catCoupon,
                onTap: () async {
                  final profile   = context.read<AppProfileService>();
                  final history   = context.read<HistoryService>();
                  final region    = context.read<RegionService>();
                  final messenger = ScaffoldMessenger.of(context);
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  final raw = data?.text ?? '';
                  if (raw.isEmpty) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Clipboard is empty.')),
                    );
                    return;
                  }
                  try {
                    await LocalBackupService.importJson(
                      raw: raw,
                      profile: profile,
                      history: history,
                      region: region,
                    );
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Backup imported successfully!')),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Import failed: $e')),
                    );
                  }
                },
              ),
              const SizedBox(height: 28),

              // ── About ─────────────────────────────────────────────────────
              const _SectionHeader('ABOUT'),
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
                  title: '$count beatdown${count == 1 ? '' : 's'} planned',
                  subtitle: 'Every one of them, posted in the gloom.',
                );
              }),
              const _VersionTile(),
              const _InfoTile(
                icon: Icons.fitness_center_rounded,
                title: '907 Exicon exercises',
                subtitle: 'Full F3 Codex, bundled offline.',
              ),
              const _InfoTile(
                icon: Icons.wifi_off_rounded,
                title: 'Fully offline',
                subtitle: 'No account or internet required.',
              ),
            ],
          );
        },
      ),
    );
  }
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

// ── Profile banner ───────────────────────────────────────────────────────────

class _ProfileBanner extends StatefulWidget {
  final bool isQ;
  const _ProfileBanner({required this.isQ});

  @override
  State<_ProfileBanner> createState() => _ProfileBannerState();
}

class _ProfileBannerState extends State<_ProfileBanner> {
  bool _synced = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromF3());
  }

  bool _isLinked(AuthService auth) =>
      auth.currentUser?.identities
          .any((i) => i.provider == AuthProvider.f3nation) ??
      false;

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
        final name =
            profile.displayName.isEmpty ? 'PAX' : profile.displayName;
        final linked = _isLinked(auth);
        final banner = Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: context.f3card,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: F3Colors.accent.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            // Avatar from F3 Nation when available, shield otherwise.
            profile.avatarUrl.isNotEmpty
                ? CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        F3Colors.accent.withValues(alpha: 0.14),
                    foregroundImage: NetworkImage(profile.avatarUrl),
                    onForegroundImageError: (exception, stackTrace) {},
                    child: const Icon(Icons.shield_rounded,
                        color: F3Colors.accent, size: 26),
                  )
                : Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: F3Colors.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: F3Colors.accent.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.shield_rounded,
                        color: F3Colors.accent, size: 30),
                  ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${greetingForNow()},',
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

// ── F3 Nation account card ──────────────────────────────────────────────────

class _F3NationAccountCard extends StatefulWidget {
  const _F3NationAccountCard();

  @override
  State<_F3NationAccountCard> createState() => _F3NationAccountCardState();
}

class _F3NationAccountCardState extends State<_F3NationAccountCard> {
  bool _busy = false;

  LinkedIdentity? _f3Identity(AuthService auth) {
    for (final identity in auth.currentUser?.identities ?? const []) {
      if (identity.provider == AuthProvider.f3nation) return identity;
    }
    return null;
  }

  Future<void> _toggle(AuthService auth, bool linked) async {
    setState(() => _busy = true);
    try {
      if (linked) {
        await auth.unlinkF3Nation();
      } else {
        await auth.signInWithF3Nation();
        // Celebrate the moment a PAX first links their real F3 identity.
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      if (mounted) _showErrorDialog('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Full-detail, copyable error dialog — a transient snackbar is useless
  /// for diagnosing OAuth failures from a screenshot.
  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.f3card,
        title: Text(
          'F3 Nation Sign-In Error',
          style: TextStyle(color: context.f3textPrimary, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            message,
            style: TextStyle(
              color: context.f3textSecondary,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              Navigator.pop(context);
            },
            child: const Text('Copy & Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final identity = _f3Identity(auth);
        final linked = identity != null;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.f3card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.f3divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(
                  linked
                      ? Icons.verified_user_rounded
                      : Icons.person_outline_rounded,
                  color: linked ? F3Colors.accent : context.f3textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    linked
                        ? (identity.email.isNotEmpty ? identity.email : 'Linked')
                        : 'Not linked',
                    style: TextStyle(
                      color: context.f3textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _toggle(auth, linked),
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          linked ? Icons.logout_rounded : Icons.login_rounded),
                  label: Text(_busy
                      ? 'Working… (check your browser)'
                      : linked
                          ? 'Unlink Account'
                          : 'Sign in with F3 Nation'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Links your Digital Weinke profile to your F3 Nation account '
                '(auth2.f3nation.com).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SegmentedRow<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final String Function(T) label;
  final void Function(T) onSelect;

  const _SegmentedRow({
    required this.options,
    required this.selected,
    required this.label,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final isSelected = opt == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onSelect(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? F3Colors.accent.withValues(alpha: 0.15)
                      : context.f3card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? F3Colors.accent : context.f3divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  label(opt),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? F3Colors.accent : context.f3textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
    if (rawName.isEmpty) return 'System Default';
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
    showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.f3card,
        title: Text('Select TTS Voice',
            style: TextStyle(color: context.f3textPrimary, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _voices.length,
            itemBuilder: (ctx, i) {
              final (displayName, rawName) = _voices[i];
              final selected = rawName == widget.currentVoice;
              return ListTile(
                dense: true,
                title: Text(displayName,
                    style: TextStyle(
                      color: selected ? F3Colors.accent : context.f3textPrimary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                      fontSize: 13,
                    )),
                trailing: selected
                    ? const Icon(Icons.check_rounded, color: F3Colors.accent, size: 18)
                    : null,
                onTap: () => Navigator.pop(ctx, rawName),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('USE DEFAULT'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    ).then((picked) {
      if (picked != null) widget.onVoiceSelected(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
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
              Text('TTS Voice',
                  style: TextStyle(color: context.f3textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              Text(
                _loading ? 'Loading voices…' : label,
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

// ── Theme picker ──────────────────────────────────────────────────────────────

class _ThemePicker extends StatelessWidget {
  final ThemeMode current;
  final void Function(ThemeMode) onSelect;

  const _ThemePicker({required this.current, required this.onSelect});

  static const _options = [
    (ThemeMode.dark,   Icons.dark_mode_rounded,       'Dark'),
    (ThemeMode.light,  Icons.light_mode_rounded,      'Light'),
    (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final (mode, icon, label) = opt;
        final selected = mode == current;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onSelect(mode),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? F3Colors.accent.withValues(alpha: 0.14) : context.f3card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? F3Colors.accent : context.f3divider,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon,
                      color: selected ? F3Colors.accent : context.f3textSecondary,
                      size: 22),
                  const SizedBox(height: 4),
                  Text(label,
                      style: TextStyle(
                        color: selected ? F3Colors.accent : context.f3textSecondary,
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      )),
                ]),
              ),
            ),
          ),
        );
      }).toList(),
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

class _VersionTile extends StatelessWidget {
  const _VersionTile();

  void _showChangelog(BuildContext context) {
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
        builder: (_, ctrl) => Column(children: [
          Container(
            width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: context.f3divider, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(children: [
              Icon(Icons.history_rounded, color: F3Colors.accent, size: 22),
              SizedBox(width: 10),
              Text('CHANGELOG',
                  style: TextStyle(color: context.f3textPrimary, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ]),
          ),
          Divider(color: context.f3divider, height: 1),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.all(20),
              itemCount: AppVersion.releases.length,
              itemBuilder: (_, i) => _ReleaseCard(release: AppVersion.releases[i]),
            ),
          ),
        ]),
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
              Text('Tap to see what\'s new',
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

// ── Language picker ───────────────────────────────────────────────────────────

class _LanguagePicker extends StatelessWidget {
  final String current;
  final void Function(String) onSelect;

  const _LanguagePicker({required this.current, required this.onSelect});

  static const _options = [
    ('en', '🇺🇸', 'English'),
    ('es', '🇻🇪', 'Español'),
    ('fr', '🇫🇷', 'Français'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final (code, flag, label) = opt;
        final selected = code == current;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onSelect(code),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? F3Colors.accent.withValues(alpha: 0.14)
                      : context.f3card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? F3Colors.accent : context.f3divider,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(flag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? F3Colors.accent
                          : context.f3textSecondary,
                      fontSize: 11,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        );
      }).toList(),
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
