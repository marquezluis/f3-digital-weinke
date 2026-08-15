// lib/screens/brotherhood_screen.dart
// Brotherhood Board — Q/PAX dashboard with hero card, FNG pipeline, AOs,
// crew, hard commits, and recent beatdowns.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/region_models.dart';
import '../models/f3_api_models.dart';
import '../services/region_service.dart';
import '../services/app_profile_service.dart';
import '../services/f3_api_service.dart';
import '../services/settings_service.dart' hide AppRole;
import '../theme/app_theme.dart';
import 'f3_moments_screen.dart';
import 'heatmap_screen.dart';
import 'achievements_screen.dart';
import 'activity_feed_screen.dart';
import 'chat_screen.dart';
import '../utils/date_format.dart';

class BrotherhoodScreen extends StatefulWidget {
  const BrotherhoodScreen({super.key});

  @override
  State<BrotherhoodScreen> createState() => _BrotherhoodScreenState();
}

class _BrotherhoodScreenState extends State<BrotherhoodScreen> {
  bool _crewExpanded = false;

  // Quick-jump anchors — same Scrollable.ensureVisible technique as
  // QSource's bookmark jump (qsource_screen.dart) — this board has 7 named
  // sections stacked on one long scroll with no way to skip ahead.
  static const _sectionTitles = [
    'EH PROSPECTS',
    'FNG PIPELINE',
    'YOUR AOs',
    'YOUR CREW',
    'HARD COMMITS',
    'RECENT BEATDOWNS',
    'YOUR STATS',
  ];
  final Map<String, GlobalKey> _sectionKeys = {
    for (final title in _sectionTitles) title: GlobalKey(),
  };

  void _jumpTo(String title) {
    final ctx = _sectionKeys[title]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 300), alignment: 0.05);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: Text(
          'BROTHERHOOD BOARD',
          style: TextStyle(
            color: context.f3textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: context.f3bg,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Add AO',
            icon: const Icon(Icons.add_location_alt_rounded),
            onPressed: () => _showAoSheet(context),
          ),
          IconButton(
            tooltip: 'Add PAX',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () => _showPaxSheet(context),
          ),
          IconButton(
            tooltip: 'Add EH Prospect',
            icon: const Icon(Icons.record_voice_over_rounded),
            onPressed: () => _showEhProspectSheet(context),
          ),
        ],
      ),
      body: Consumer<AppProfileService>(
        builder: (context, profile, _) {
          return Consumer<RegionService>(
            builder: (context, region, _) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  // ── Hero card ─────────────────────────────────────────────
                  _HeroCard(profile: profile, region: region),
                  const SizedBox(height: 16),

                  // ── PAX of the Quarter ────────────────────────────────────
                  if (region.paxOfTheQuarter != null) ...[
                    _PaxOfTheQuarterCard(pick: region.paxOfTheQuarter!),
                    const SizedBox(height: 16),
                  ],

                  // ── Region Chat ───────────────────────────────────────────
                  _ChatEntryCard(region: profile.region),
                  const SizedBox(height: 16),

                  // ── Quick jump ────────────────────────────────────────────
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _sectionTitles.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final title = _sectionTitles[i];
                        return ActionChip(
                          label: Text(title,
                              style: const TextStyle(
                                  fontSize: 11.5, fontWeight: FontWeight.w700)),
                          backgroundColor: context.f3card,
                          side: BorderSide(color: context.f3divider),
                          labelStyle: TextStyle(color: context.f3textSecondary),
                          onPressed: () => _jumpTo(title),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── EH Prospects ──────────────────────────────────────────
                  KeyedSubtree(
                    key: _sectionKeys['EH PROSPECTS'],
                    child: _EhProspectsSection(
                      region: region,
                      onAdd: () => _showEhProspectSheet(context),
                    ),
                  ),

                  // ── FNG Pipeline ──────────────────────────────────────────
                  KeyedSubtree(
                    key: _sectionKeys['FNG PIPELINE'],
                    child: _FngPipelineSection(
                      region: region,
                      onAddPax: () => _showPaxSheet(context),
                    ),
                  ),

                  // ── Your AOs ──────────────────────────────────────────────
                  _SectionHeader(
                    key: _sectionKeys['YOUR AOs'],
                    title: 'YOUR AOs',
                    action: 'ADD +',
                    onAction: () => _showAoSheet(context),
                  ),
                  const SizedBox(height: 8),
                  if (region.aos.isEmpty)
                    const _EmptyState(
                      icon: Icons.flag_rounded,
                      message:
                          'No AOs yet — add your regular beatdown spots to track HCs and attendance.',
                    )
                  else
                    ...region.aos.map(
                      (ao) => _AoCard(
                        ao: ao,
                        hcCount: region.hardCommits
                            .where((hc) => hc.aoId == ao.id)
                            .length,
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ── Your Crew ─────────────────────────────────────────────
                  _SectionHeader(
                    key: _sectionKeys['YOUR CREW'],
                    title: 'YOUR CREW',
                    action: 'ADD +',
                    onAction: () => _showPaxSheet(context),
                  ),
                  const SizedBox(height: 8),
                  if (region.pax.isEmpty)
                    const _EmptyState(
                      icon: Icons.group_rounded,
                      message:
                          'No PAX saved yet — build your local directory to track the crew.',
                    )
                  else
                    ..._buildCrewSection(region.pax, context),
                  const SizedBox(height: 24),

                  // ── Hard Commits ──────────────────────────────────────────
                  _SectionHeader(
                    key: _sectionKeys['HARD COMMITS'],
                    title: 'HARD COMMITS',
                    action: region.aos.isEmpty ? null : 'ADD +',
                    onAction:
                        region.aos.isEmpty ? null : () => _showHcSheet(context),
                  ),
                  const SizedBox(height: 8),
                  if (region.hardCommits.isEmpty)
                    const _EmptyState(
                      icon: Icons.how_to_reg_rounded,
                      message:
                          'Track who committed for the next beatdown. Reliability starts before the gloom.',
                    )
                  else ..._buildHcCards(region),
                  const SizedBox(height: 24),

                  // ── Recent Beatdowns ──────────────────────────────────────
                  _SectionHeader(
                      key: _sectionKeys['RECENT BEATDOWNS'],
                      title: 'RECENT BEATDOWNS'),
                  const SizedBox(height: 8),
                  if (region.recentAttendance.isEmpty)
                    const _EmptyState(
                      icon: Icons.fact_check_rounded,
                      message:
                          'Attendance appears here when you save a completed beatdown.',
                    )
                  else
                    ...region.recentAttendance
                        .take(6)
                        .map((entry) => _BeatdownTile(entry: entry)),

                  // ── Your Stats ────────────────────────────────────────────
                  const SizedBox(height: 24),
                  if (region.monthlyRecap != null) ...[
                    _MonthlyRecapCard(recap: region.monthlyRecap!),
                    const SizedBox(height: 16),
                  ],
                  _SectionHeader(
                      key: _sectionKeys['YOUR STATS'], title: 'YOUR STATS'),
                  const SizedBox(height: 8),
                  Material(
                    color: context.f3card,
                    borderRadius: BorderRadius.circular(12),
                    child: Column(children: [
                      ListTile(
                        leading: const Icon(Icons.dynamic_feed_rounded,
                            color: F3Colors.accent),
                        title: const Text('Activity Feed'),
                        subtitle: const Text(
                            'Backblasts, achievements, and hard commits'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ActivityFeedScreen())),
                      ),
                      ListTile(
                        leading: const Icon(Icons.whatshot_rounded,
                            color: F3Colors.phaseThang),
                        title: const Text('Activity Heatmap'),
                        subtitle: const Text('52-week workout calendar'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HeatmapScreen())),
                      ),
                      ListTile(
                        leading: const Icon(Icons.emoji_events_rounded,
                            color: Color(0xFFFFD700)),
                        title: const Text('Achievements'),
                        subtitle:
                            const Text('Badges earned from your history'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AchievementsScreen())),
                      ),
                      ListTile(
                        leading: Icon(Icons.photo_library_rounded,
                            color: F3Colors.catCoupon),
                        title: const Text('F3 Moments'),
                        subtitle: const Text(
                            'Every Pic-o-Rama photo, one timeline'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const F3MomentsScreen())),
                      ),
                    ]),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildCrewSection(
      List<PaxProfile> pax, BuildContext context) {
    const pageSize = 8;
    final showAll = _crewExpanded || pax.length <= pageSize;
    final visible = showAll ? pax : pax.take(pageSize).toList();
    return [
      ...visible.map((p) => _PaxTile(pax: p)),
      if (pax.length > pageSize && !_crewExpanded)
        GestureDetector(
          onTap: () => setState(() => _crewExpanded = true),
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: context.f3card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.f3divider),
            ),
            child: Center(
              child: Text(
                'View all ${pax.length} PAX',
                style: const TextStyle(
                  color: F3Colors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildHcCards(RegionService region) {
    final sorted = [...region.hardCommits]
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted.take(5).map((hc) {
      final aoName = region.aos
          .where((ao) => ao.id == hc.aoId)
          .map((ao) => ao.name)
          .firstOrNull;
      return _HcCard(hc: hc, aoName: aoName ?? 'AO');
    }).toList();
  }

  // ── Sheets ────────────────────────────────────────────────────────────────

  static void _showAoSheet(BuildContext context) {
    final name = TextEditingController();
    final location = TextEditingController();
    final terrain = TextEditingController();
    final api = context.read<F3ApiService>();
    List<F3Location> matches = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.f3card,
      builder: (_) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          // Real F3 Nation AO data (already fetched/cached for Browse AOs)
          // beats retyping a name and address from memory — best-effort
          // only, never blocks manual entry if the API's unavailable.
          Future<void> onNameChanged(String value) async {
            final q = value.trim().toLowerCase();
            if (q.length < 2 || !api.isConfigured) {
              if (matches.isNotEmpty) setSheetState(() => matches = []);
              return;
            }
            final locations = await api.getLocations();
            final found = locations
                .where((l) => (l.aoName ?? l.name).toLowerCase().contains(q))
                .take(4)
                .toList();
            // The sheet can close (e.g. Save tapped) while this lookup is
            // still in flight — setSheetState on a defunct StatefulBuilder
            // throws "setState() called after dispose()".
            if (sheetContext.mounted) setSheetState(() => matches = found);
          }

          return _SimpleFormSheet(
            title: 'Add AO',
            children: [
              _Field(
                  controller: name,
                  label: 'AO Name',
                  icon: Icons.flag_rounded,
                  onChanged: onNameChanged),
              if (matches.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: matches.map((loc) {
                    final locName = loc.aoName ?? loc.name;
                    return ActionChip(
                      label: Text(locName),
                      onPressed: () {
                        name.text = locName;
                        final parts = [loc.street, loc.city, loc.state]
                            .where((p) => p != null && p.isNotEmpty)
                            .join(', ');
                        if (parts.isNotEmpty) location.text = parts;
                        setSheetState(() => matches = []);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 4),
              ],
              _Field(
                  controller: location,
                  label: 'Location',
                  icon: Icons.place_rounded),
              _Field(
                  controller: terrain,
                  label: 'Terrain',
                  hint: 'Track, hill, trail, parking lot',
                  icon: Icons.terrain_rounded),
            ],
            onSave: () async {
              if (name.text.trim().isEmpty) return;
              await context.read<RegionService>().upsertAo(
                    name: name.text,
                    location: location.text,
                    terrain: terrain.text,
                  );
              if (context.mounted) Navigator.pop(context);
            },
          );
        },
      ),
    );
    // Not disposed: showModalBottomSheet's Future resolves on Navigator.pop,
    // before the sheet's slide-down exit animation finishes, so an immediate
    // dispose() here raced the still-live TextFields and crashed with "used
    // after being disposed". These controllers have no listeners of our own
    // and are torn down with the sheet's widget tree once the animation
    // completes — nothing real leaks by skipping an explicit dispose. Same
    // reasoning applies to the other three sheets below.
  }

  static void _showPaxSheet(BuildContext context) {
    final name = TextEditingController();
    final contact = TextEditingController();
    final sponsor = TextEditingController();
    final notes = TextEditingController();
    DateTime? pickedFirstPost;
    F3UserProfile? f3Result;
    bool f3Searching = false;
    final api = context.read<F3ApiService>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.f3card,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return _SimpleFormSheet(
            title: 'Add PAX',
            children: [
              _Field(
                  controller: name,
                  label: 'F3 Name',
                  icon: Icons.person_rounded),
              // F3 Nation lookup (only when API configured)
              if (api.isConfigured) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: f3Result != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: F3Colors.accent.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: F3Colors.accent.withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.verified_rounded, color: F3Colors.accent, size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${f3Result!.f3Name}${f3Result!.homeRegionName != null ? ' · ${f3Result!.homeRegionName}' : ''}',
                                      style: TextStyle(
                                        color: ctx.f3textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setSheetState(() => f3Result = null),
                                    child: Icon(Icons.close_rounded, size: 14, color: ctx.f3textMuted),
                                  ),
                                ],
                              ),
                            )
                          : GestureDetector(
                              onTap: () async {
                                final q = name.text.trim();
                                if (q.isEmpty) return;
                                setSheetState(() => f3Searching = true);
                                final result = await api.findPaxByF3Name(q);
                                // The sheet can close while this lookup is in
                                // flight — setSheetState on a defunct
                                // StatefulBuilder throws "setState() called
                                // after dispose()".
                                if (!ctx.mounted) return;
                                setSheetState(() {
                                  f3Result = result;
                                  f3Searching = false;
                                  if (result != null && name.text.trim().isEmpty) {
                                    name.text = result.f3Name;
                                  }
                                  if (result?.phone != null &&
                                      result!.phone!.isNotEmpty &&
                                      contact.text.trim().isEmpty) {
                                    contact.text = result.phone!;
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: ctx.f3elevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: ctx.f3divider),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (f3Searching)
                                      const SizedBox(
                                        width: 11, height: 11,
                                        child: CircularProgressIndicator(strokeWidth: 1.5, color: F3Colors.accent),
                                      )
                                    else
                                      const Icon(Icons.search_rounded, size: 13, color: F3Colors.accent),
                                    const SizedBox(width: 5),
                                    Text(
                                      f3Searching ? 'Searching…' : 'Look up on F3 Nation',
                                      style: TextStyle(
                                        color: f3Searching ? ctx.f3textMuted : F3Colors.accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ],
              _Field(
                  controller: contact,
                  label: 'Phone / Slack',
                  icon: Icons.alternate_email_rounded),
              _Field(
                  controller: sponsor,
                  label: 'Sponsor',
                  icon: Icons.handshake_rounded),
              // First Post date picker
              GestureDetector(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: pickedFirstPost ?? now,
                    firstDate: DateTime(2010),
                    lastDate: now,
                    helpText: 'FIRST POST DATE',
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: F3Colors.accent,
                          onPrimary: Colors.white,
                          surface: context.f3card,
                          onSurface: context.f3textPrimary,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setSheetState(() => pickedFirstPost = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: context.f3card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.f3divider),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: context.f3textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        pickedFirstPost != null
                            ? 'First Post: ${shortMonthDay(pickedFirstPost!, Localizations.localeOf(context).languageCode)}'
                            : 'First Post Date (optional)',
                        style: TextStyle(
                          color: pickedFirstPost != null
                              ? context.f3textPrimary
                              : context.f3textMuted,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      if (pickedFirstPost != null)
                        GestureDetector(
                          onTap: () =>
                              setSheetState(() => pickedFirstPost = null),
                          child: Icon(Icons.clear_rounded,
                              color: context.f3textMuted, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              _Field(
                  controller: notes,
                  label: 'FNG / Follow-up Notes',
                  icon: Icons.notes_rounded,
                  maxLines: 3),
            ],
            onSave: () async {
              if (name.text.trim().isEmpty) return;
              await ctx.read<RegionService>().upsertPax(
                    name: name.text,
                    phoneOrSlack: contact.text,
                    sponsor: sponsor.text,
                    firstPost: pickedFirstPost,
                    notes: notes.text,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
          );
        },
      ),
    );
    // Not disposed — see _showAoSheet above: disposing immediately after
    // the sheet's Future resolves races its still-animating-out TextFields.
  }

  static void _showEhProspectSheet(BuildContext context) {
    final name = TextEditingController();
    final contact = TextEditingController();
    final notes = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.f3card,
      builder: (sheetContext) => _SimpleFormSheet(
        title: 'Add EH Prospect',
        children: [
          _Field(controller: name, label: 'Name', icon: Icons.person_rounded),
          _Field(
              controller: contact,
              label: 'Phone / Slack (optional)',
              icon: Icons.chat_bubble_outline_rounded),
          _Field(
              controller: notes,
              label: 'Where you met, what to follow up on',
              icon: Icons.notes_rounded,
              maxLines: 3),
        ],
        onSave: () async {
          if (name.text.trim().isEmpty) return;
          await sheetContext.read<RegionService>().addEhProspect(
                name: name.text,
                contactInfo: contact.text,
                notes: notes.text,
              );
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
    // Not disposed — see _showAoSheet above: disposing immediately after
    // the sheet's Future resolves races its still-animating-out TextFields.
  }

  static void _showHcSheet(BuildContext context) {
    final region = context.read<RegionService>();
    final settings = context.read<SettingsService>();
    final profile = context.read<AppProfileService>();
    final myName =
        settings.myF3Name.isNotEmpty ? settings.myF3Name : profile.displayName;
    final pax = TextEditingController();
    final q = TextEditingController(text: myName);
    final selectedPax = <String>{};
    // Default to wherever you actually are today, not whichever AO sorts
    // first alphabetically — both sources are already in hand above.
    final flagAo = settings.atTheFlagAo?.toLowerCase();
    final homeAo = profile.homeAo.toLowerCase();
    var selectedAo = region.aos
        .where((ao) =>
            ao.name.toLowerCase() == flagAo ||
            (flagAo == null && ao.name.toLowerCase() == homeAo))
        .firstOrNull
        ?.id ??
        region.aos.first.id;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.f3card,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => _SimpleFormSheet(
          title: 'Add HC',
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedAo,
              dropdownColor: context.f3card,
              decoration: const InputDecoration(
                labelText: 'AO',
                prefixIcon: Icon(Icons.flag_rounded),
              ),
              items: region.aos
                  .map((ao) => DropdownMenuItem(
                        value: ao.id,
                        child: Text(ao.name),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setSheetState(() => selectedAo = value);
              },
            ),
            if (region.pax.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('HC Names',
                  style: TextStyle(
                      color: context.f3textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: region.pax.map((p) {
                  final picked = selectedPax.contains(p.name);
                  return FilterChip(
                    label: Text(p.name),
                    selected: picked,
                    onSelected: (v) => setSheetState(() {
                      if (v) {
                        selectedPax.add(p.name);
                      } else {
                        selectedPax.remove(p.name);
                      }
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
            _Field(
              controller: pax,
              label:
                  region.pax.isEmpty ? 'HC Names' : 'Other HC Names',
              hint: 'Comma-separated',
              icon: Icons.group_add_rounded,
            ),
            _Field(controller: q, label: 'Q', icon: Icons.person_rounded),
          ],
          onSave: () async {
            final typed = pax.text
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty);
            final names = {...selectedPax, ...typed}.toList();
            await context.read<RegionService>().addHardCommit(
                  aoId: selectedAo,
                  date: DateTime.now(),
                  paxNames: names,
                  q: q.text,
                );
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
    // Not disposed — see _showAoSheet above: disposing immediately after
    // the sheet's Future resolves races its still-animating-out TextFields.
  }

}

// ── Hero Card ─────────────────────────────────────────────────────────────────

/// Recognizes whoever's shown up most in this Q's own logged attendance
/// over the last 90 days. Local-only, honestly scoped — no nation-wide
/// leaderboard exists to pull a real "quarter" ranking from.
class _PaxOfTheQuarterCard extends StatelessWidget {
  final ({String paxName, int postCount}) pick;
  const _PaxOfTheQuarterCard({required this.pick});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: F3Colors.phaseCOT.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: F3Colors.phaseCOT.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: F3Colors.phaseCOT.withValues(alpha: 0.18),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.emoji_events_rounded,
              color: F3Colors.phaseCOT, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PAX OF THE QUARTER',
                  style: TextStyle(
                      color: F3Colors.phaseCOT,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
              const SizedBox(height: 2),
              Text(pick.paxName,
                  style: TextStyle(
                      color: context.f3textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900)),
              Text('${pick.postCount} posts in the last 90 days',
                  style: TextStyle(
                      color: context.f3textMuted, fontSize: 12)),
            ],
          ),
        ),
      ]),
    );
  }
}

/// This calendar month's recap — most-active AO and FNGs welcomed, from
/// this device's own logged attendance. Same local-only honesty as PAX of
/// the Quarter above.
class _MonthlyRecapCard extends StatelessWidget {
  final ({String topAoName, int topAoPosts, int fngCount, int totalPosts})
      recap;
  const _MonthlyRecapCard({required this.recap});

  @override
  Widget build(BuildContext context) {
    final monthName = fullMonth(
        DateTime.now(), Localizations.localeOf(context).languageCode);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.f3divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.calendar_month_rounded,
                color: F3Colors.accent, size: 18),
            const SizedBox(width: 8),
            Text('${monthName.toUpperCase()} RECAP',
                style: TextStyle(
                    color: context.f3textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _RecapStat(
                icon: Icons.flag_rounded,
                value: recap.topAoName,
                label: 'Most-active AO (${recap.topAoPosts} posts)',
              ),
            ),
            Expanded(
              child: _RecapStat(
                icon: Icons.emoji_people_rounded,
                value: '${recap.fngCount}',
                label: recap.fngCount == 1
                    ? 'FNG welcomed'
                    : 'FNGs welcomed',
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _RecapStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _RecapStat(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.f3textMuted, size: 18),
        const SizedBox(height: 4),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: context.f3textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: TextStyle(color: context.f3textMuted, fontSize: 11)),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final AppProfileService profile;
  final RegionService region;

  const _HeroCard({required this.profile, required this.region});

  @override
  Widget build(BuildContext context) {
    final name =
        profile.displayName.isNotEmpty ? profile.displayName : 'Iron PAX';
    final hasLocation = profile.homeAo.isNotEmpty || profile.region.isNotEmpty;
    final locationParts = [
      if (profile.homeAo.isNotEmpty) profile.homeAo,
      if (profile.region.isNotEmpty) profile.region,
    ];
    final locationText = hasLocation
        ? locationParts.join(' · ')
        : 'Set your profile in Settings';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.f3elevated, context.f3card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: F3Colors.accent.withValues(alpha: 0.30),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row: home AO logo (when the region has uploaded one) +
          // name + role badge
          Row(
            children: [
              if (profile.homeAo.isNotEmpty) _HomeAoLogo(homeAo: profile.homeAo),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: context.f3textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _RoleBadge(role: profile.role),
            ],
          ),
          const SizedBox(height: 4),
          // Subtitle: location
          Text(
            locationText,
            style: TextStyle(
              color: hasLocation
                  ? context.f3textSecondary
                  : context.f3textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          // Stat row
          Row(
            children: [
              _StatChip(
                value: '${region.aos.length}',
                label: 'AOs',
                color: F3Colors.phaseCOT,
              ),
              const SizedBox(width: 8),
              _StatChip(
                value: '${region.pax.length}',
                label: 'PAX',
                color: F3Colors.catBodyweight,
              ),
              const SizedBox(width: 8),
              _StatChip(
                value: '${region.totalHcCount}',
                label: 'HCs',
                color: F3Colors.phaseWarmup,
              ),
              const SizedBox(width: 8),
              _StatChip(
                value: '${region.attendance.length}',
                label: 'Beatdowns',
                color: F3Colors.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Chat entry point ────────────────────────────────────────────────────────

class _ChatEntryCard extends StatelessWidget {
  final String region;

  const _ChatEntryCard({required this.region});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.f3card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ChatScreen())),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: F3Colors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.forum_rounded, color: F3Colors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      region.isNotEmpty ? '$region Chat' : 'Region Chat',
                      style: TextStyle(
                        color: context.f3textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Message the crew — preview, not connected to Slack yet',
                      style: TextStyle(color: context.f3textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.f3textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// The PAX's real home AO logo, when their region has uploaded one to F3
/// Nation — resolved by matching profile.homeAo's name against the org
/// directory (F3ApiService.getOrgs() is cached, so this doesn't cost a
/// fresh network round-trip if Browse AOs already fetched it). Silently
/// renders nothing when there's no match or no logo — most AOs haven't
/// uploaded one, and this card already reads fine without it.
class _HomeAoLogo extends StatefulWidget {
  final String homeAo;
  const _HomeAoLogo({required this.homeAo});

  @override
  State<_HomeAoLogo> createState() => _HomeAoLogoState();
}

class _HomeAoLogoState extends State<_HomeAoLogo> {
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final api = context.read<F3ApiService>();
    final orgs = await api.getOrgs();
    final match = orgs
        .where((o) =>
            o.name.toLowerCase() == widget.homeAo.toLowerCase() &&
            (o.logoUrl ?? '').isNotEmpty)
        .firstOrNull;
    if (!mounted || match == null) return;
    setState(() => _logoUrl = match.logoUrl);
  }

  @override
  Widget build(BuildContext context) {
    if (_logoUrl == null) return const SizedBox.shrink();
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: F3Colors.accent.withValues(alpha: 0.4)),
      ),
      child: ClipOval(
        child: Image.network(
          _logoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final AppRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: F3Colors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: F3Colors.accent.withValues(alpha: 0.40),
        ),
      ),
      child: Text(
        role.displayName.toUpperCase(),
        style: const TextStyle(
          color: F3Colors.accent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: context.f3textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FNG Pipeline Section ──────────────────────────────────────────────────────

class _FngPipelineSection extends StatelessWidget {
  final RegionService region;
  final VoidCallback onAddPax;
  const _FngPipelineSection({required this.region, required this.onAddPax});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 90));
    final fngs = region.pax.where((p) {
      final hasNotes = p.notes.isNotEmpty;
      final isRecent =
          p.firstPost != null && p.firstPost!.isAfter(cutoff);
      return hasNotes || isRecent;
    }).toList();

    // Always show this section
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'FNG PIPELINE',
          action: 'ADD +',
          onAction: onAddPax,
          accentTitle: true,
        ),
        const SizedBox(height: 8),
        if (fngs.isEmpty)
          const _EmptyState(
            icon: Icons.emoji_people_rounded,
            message:
                'No active FNGs — great retention, or add a PAX with notes to track their journey.',
          )
        else
          ...fngs.map((p) => _FngCard(pax: p, now: now)),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _FngCard extends StatelessWidget {
  final PaxProfile pax;
  final DateTime now;
  const _FngCard({required this.pax, required this.now});

  @override
  Widget build(BuildContext context) {
    final daysSince = pax.firstPost != null
        ? now.difference(pax.firstPost!).inDays
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.f3divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar, ringed with progress through the 90-day FNG window when
          // known — turns the pipeline into something visibly moving toward
          // a finish line instead of just a static name list.
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (daysSince != null)
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: (daysSince / 90).clamp(0, 1).toDouble(),
                      strokeWidth: 2.5,
                      backgroundColor: context.f3divider,
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFFFF9800)),
                    ),
                  ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: F3Colors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: F3Colors.accent.withValues(alpha: 0.35)),
                  ),
                  child: Center(
                    child: Text(
                      pax.name.isNotEmpty ? pax.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: F3Colors.accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pax.name,
                        style: TextStyle(
                          color: context.f3textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (daysSince != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFFFF9800)
                                  .withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'Day $daysSince',
                          style: const TextStyle(
                            color: Color(0xFFFF9800),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (pax.sponsor.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Sponsor: ${pax.sponsor}',
                    style: TextStyle(
                      color: context.f3textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (pax.notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    pax.notes,
                    style: TextStyle(
                      color: context.f3textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── EH Prospects ─────────────────────────────────────────────────────────────

class _EhProspectsSection extends StatelessWidget {
  final RegionService region;
  final VoidCallback onAdd;
  const _EhProspectsSection({required this.region, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final prospects = region.ehProspects;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'EH PROSPECTS',
          action: 'ADD +',
          onAction: onAdd,
        ),
        const SizedBox(height: 8),
        if (prospects.isEmpty)
          const _EmptyState(
            icon: Icons.record_voice_over_rounded,
            message:
                'Nobody in the pipeline yet — add someone you\'ve EH\'d to remember to follow up.',
          )
        else
          ...prospects.map((p) => _EhProspectCard(prospect: p, region: region)),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _EhProspectCard extends StatelessWidget {
  final EhProspect prospect;
  final RegionService region;
  const _EhProspectCard({required this.prospect, required this.region});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysSince = now.difference(prospect.dateAdded).inDays;
    final lastFollowUp = prospect.lastFollowUp;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.f3divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  prospect.name,
                  style: TextStyle(
                    color: context.f3textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                daysSince == 0 ? 'Added today' : '$daysSince days ago',
                style: TextStyle(color: context.f3textMuted, fontSize: 11),
              ),
            ],
          ),
          if (prospect.notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              prospect.notes,
              style: TextStyle(color: context.f3textSecondary, fontSize: 12.5),
            ),
          ],
          if (lastFollowUp != null) ...[
            const SizedBox(height: 4),
            Text(
              'Last followed up ${now.difference(lastFollowUp).inDays}d ago',
              style: TextStyle(color: context.f3textMuted, fontSize: 11),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  region.markProspectFollowedUp(prospect.id);
                },
                icon: const Icon(Icons.chat_rounded, size: 16),
                label: const Text('Followed Up'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  region.promoteProspectToPax(prospect.id);
                },
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('Posted!'),
                style: TextButton.styleFrom(foregroundColor: F3Colors.accent),
              ),
              IconButton(
                tooltip: 'Remove',
                icon: Icon(Icons.close_rounded,
                    size: 18, color: context.f3textMuted),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Remove this prospect?'),
                      content: Text(
                          '${prospect.name} and any notes will be deleted. This can\'t be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('CANCEL'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade700),
                          child: const Text('REMOVE'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  HapticFeedback.mediumImpact();
                  region.removeEhProspect(prospect.id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── AO Card ───────────────────────────────────────────────────────────────────

class _AoCard extends StatelessWidget {
  final AreaOfOperations ao;
  final int hcCount;
  const _AoCard({required this.ao, required this.hcCount});

  @override
  Widget build(BuildContext context) {
    final subtitleParts = [
      if (ao.location.isNotEmpty) ao.location,
      if (ao.terrain.isNotEmpty) ao.terrain,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.f3divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_rounded, color: F3Colors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ao.name,
                  style: TextStyle(
                    color: context.f3textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitleParts.isNotEmpty)
                  Text(
                    subtitleParts.join(' · '),
                    style: TextStyle(
                      color: context.f3textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (hcCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: F3Colors.phaseWarmup.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: F3Colors.phaseWarmup.withValues(alpha: 0.35)),
              ),
              child: Text(
                '$hcCount HC',
                style: const TextStyle(
                  color: F3Colors.phaseWarmup,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── PAX Tile ──────────────────────────────────────────────────────────────────

class _PaxTile extends StatelessWidget {
  final PaxProfile pax;
  const _PaxTile({required this.pax});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.f3divider),
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: F3Colors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                pax.name.isNotEmpty ? pax.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: F3Colors.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              pax.name,
              style: TextStyle(
                color: context.f3textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (pax.phoneOrSlack.isNotEmpty)
            Icon(Icons.phone_iphone_rounded,
                color: context.f3textMuted, size: 16),
        ],
      ),
    );
  }
}

// ── HC Card ───────────────────────────────────────────────────────────────────

class _HcCard extends StatelessWidget {
  final HardCommit hc;
  final String aoName;
  const _HcCard({required this.hc, required this.aoName});

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      '${hc.paxNames.length} HC',
      if (hc.q.isNotEmpty) 'Q: ${hc.q}',
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.f3divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.how_to_reg_rounded,
              color: F3Colors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aoName,
                  style: TextStyle(
                    color: context.f3textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${shortMonthDay(hc.date, Localizations.localeOf(context).languageCode)} · $subtitle',
                  style: TextStyle(
                    color: context.f3textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Beatdown Tile ─────────────────────────────────────────────────────────────

class _BeatdownTile extends StatelessWidget {
  final AttendanceRecord entry;
  const _BeatdownTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      shortMonthDay(entry.date, Localizations.localeOf(context).languageCode),
      '${entry.totalCount} PAX',
      if (entry.fngCount > 0) '${entry.fngCount} FNG',
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.f3divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.fact_check_rounded,
              color: F3Colors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.aoName.isEmpty ? 'Beatdown' : entry.aoName,
                  style: TextStyle(
                    color: context.f3textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.f3textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final bool accentTitle;

  const _SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.accentTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: accentTitle ? F3Colors.accent : context.f3textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              action!,
              style: const TextStyle(
                // Secondary tier — this is a utility action next to a
                // section title, not the screen's primary CTA, so it
                // shouldn't compete with accent red for attention.
                color: F3Colors.accentSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.f3card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.f3divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.f3textMuted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: context.f3textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Simple Form Sheet ─────────────────────────────────────────────────────────

class _SimpleFormSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Future<void> Function() onSave;

  const _SimpleFormSheet({
    required this.title,
    required this.children,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: F3Colors.accent,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          ...children.expand((child) => [child, const SizedBox(height: 12)]),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await onSave();
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('SAVE'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Field ─────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    required this.icon,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: TextStyle(color: context.f3textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
