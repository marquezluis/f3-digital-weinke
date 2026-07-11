// lib/screens/brotherhood_screen.dart
// Brotherhood Board — Q/PAX dashboard with hero card, FNG pipeline, AOs,
// crew, hard commits, and recent beatdowns.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/region_models.dart';
import '../services/region_service.dart';
import '../services/app_profile_service.dart';
import '../theme/app_theme.dart';

class BrotherhoodScreen extends StatefulWidget {
  const BrotherhoodScreen({super.key});

  @override
  State<BrotherhoodScreen> createState() => _BrotherhoodScreenState();
}

class _BrotherhoodScreenState extends State<BrotherhoodScreen> {
  bool _crewExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: F3Colors.background,
      appBar: AppBar(
        title: const Text(
          'BROTHERHOOD BOARD',
          style: TextStyle(
            color: F3Colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: F3Colors.background,
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
                  const SizedBox(height: 24),

                  // ── FNG Pipeline ──────────────────────────────────────────
                  _FngPipelineSection(
                    region: region,
                    onAddPax: () => _showPaxSheet(context),
                  ),

                  // ── Your AOs ──────────────────────────────────────────────
                  _SectionHeader(
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
                  const _SectionHeader(title: 'RECENT BEATDOWNS'),
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
              color: F3Colors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: F3Colors.divider),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: F3Colors.card,
      builder: (_) => _SimpleFormSheet(
        title: 'Add AO',
        children: [
          _Field(controller: name, label: 'AO Name', icon: Icons.flag_rounded),
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
      ),
    );
  }

  static void _showPaxSheet(BuildContext context) {
    final name = TextEditingController();
    final contact = TextEditingController();
    final sponsor = TextEditingController();
    final notes = TextEditingController();
    DateTime? pickedFirstPost;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: F3Colors.card,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return _SimpleFormSheet(
            title: 'Add PAX',
            children: [
              _Field(
                  controller: name,
                  label: 'F3 Name',
                  icon: Icons.person_rounded),
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
                        colorScheme: const ColorScheme.dark(
                          primary: F3Colors.accent,
                          onPrimary: Colors.white,
                          surface: F3Colors.card,
                          onSurface: F3Colors.textPrimary,
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
                    color: F3Colors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: F3Colors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: F3Colors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        pickedFirstPost != null
                            ? 'First Post: ${_shortDate(pickedFirstPost!)}'
                            : 'First Post Date (optional)',
                        style: TextStyle(
                          color: pickedFirstPost != null
                              ? F3Colors.textPrimary
                              : F3Colors.textMuted,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      if (pickedFirstPost != null)
                        GestureDetector(
                          onTap: () =>
                              setSheetState(() => pickedFirstPost = null),
                          child: const Icon(Icons.clear_rounded,
                              color: F3Colors.textMuted, size: 18),
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
  }

  static void _showHcSheet(BuildContext context) {
    final region = context.read<RegionService>();
    final pax = TextEditingController();
    final q = TextEditingController();
    var selectedAo = region.aos.first.id;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: F3Colors.card,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => _SimpleFormSheet(
          title: 'Add HC',
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedAo,
              dropdownColor: F3Colors.card,
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
            _Field(
              controller: pax,
              label: 'HC Names',
              hint: 'Comma-separated',
              icon: Icons.group_add_rounded,
            ),
            _Field(controller: q, label: 'Q', icon: Icons.person_rounded),
          ],
          onSave: () async {
            final names = pax.text
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList();
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
  }

  static String _shortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

// ── Hero Card ─────────────────────────────────────────────────────────────────

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
        gradient: const LinearGradient(
          colors: [F3Colors.elevated, F3Colors.card],
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
          // Title row: name + role badge
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: F3Colors.textPrimary,
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
                  ? F3Colors.textSecondary
                  : F3Colors.textMuted,
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
              style: const TextStyle(
                color: F3Colors.textMuted,
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
        color: F3Colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: F3Colors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
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
                        style: const TextStyle(
                          color: F3Colors.textPrimary,
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
                    style: const TextStyle(
                      color: F3Colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (pax.notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    pax.notes,
                    style: const TextStyle(
                      color: F3Colors.textMuted,
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
        color: F3Colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: F3Colors.divider),
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
                  style: const TextStyle(
                    color: F3Colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitleParts.isNotEmpty)
                  Text(
                    subtitleParts.join(' · '),
                    style: const TextStyle(
                      color: F3Colors.textSecondary,
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
        color: F3Colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: F3Colors.divider),
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
              style: const TextStyle(
                color: F3Colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (pax.phoneOrSlack.isNotEmpty)
            const Icon(Icons.phone_iphone_rounded,
                color: F3Colors.textMuted, size: 16),
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

  static String _shortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

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
        color: F3Colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: F3Colors.divider),
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
                  style: const TextStyle(
                    color: F3Colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${_shortDate(hc.date)} · $subtitle',
                  style: const TextStyle(
                    color: F3Colors.textSecondary,
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

  static String _shortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      _shortDate(entry.date),
      '${entry.totalCount} PAX',
      if (entry.fngCount > 0) '${entry.fngCount} FNG',
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: F3Colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: F3Colors.divider),
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
                  style: const TextStyle(
                    color: F3Colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: F3Colors.textSecondary,
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
            color: accentTitle ? F3Colors.accent : F3Colors.textMuted,
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
                color: F3Colors.accent,
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
        color: F3Colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: F3Colors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: F3Colors.textMuted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: F3Colors.textSecondary,
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

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: F3Colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
