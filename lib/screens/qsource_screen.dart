// lib/screens/qsource_screen.dart
// Q & QSource Field Guide — offline reference for new Qs at 5:30 AM.
//
// Layout: scrollable list of collapsible section cards.
// Tap a card header to expand/collapse.  All high-contrast F3 styling.
//
// NOTE: Unofficial condensed guide built by PAX for PAX.
// Verify permission and content usage with F3 leadership before
// public or nationwide distribution.

import 'package:flutter/material.dart';
import '../models/qsource_data.dart';
import '../theme/app_theme.dart';

class QSourceScreen extends StatefulWidget {
  const QSourceScreen({super.key});

  @override
  State<QSourceScreen> createState() => _QSourceScreenState();
}

class _QSourceScreenState extends State<QSourceScreen> {
  // Track which sections are expanded; start with first two open.
  late final List<bool> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = List.generate(
      QSourceData.allSections.length,
      (i) => i < 2, // first two sections open by default
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.f3bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: 'Q ',
                          style: TextStyle(
                            color: context.f3textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            height: 1,
                          ),
                        ),
                        TextSpan(
                          text: 'FIELD GUIDE',
                          style: TextStyle(
                            color: F3Colors.accent,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            height: 1,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Prep, cadence, COT, backblast & QSource',
                      style: TextStyle(
                        color: context.f3textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Disclaimer banner ────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: F3Colors.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: F3Colors.accent.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: F3Colors.accent, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Unofficial condensed guide — PAX-built for PAX. '
                          'Verify with F3 leadership before wide distribution.',
                          style: TextStyle(
                            color: context.f3textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Expand / Collapse All ────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          final allExpanded = _expanded.every((e) => e);
                          for (int i = 0; i < _expanded.length; i++) {
                            _expanded[i] = !allExpanded;
                          }
                        });
                      },
                      icon: Icon(
                        _expanded.every((e) => e)
                            ? Icons.unfold_less_rounded
                            : Icons.unfold_more_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _expanded.every((e) => e)
                            ? 'Collapse All'
                            : 'Expand All',
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: context.f3textSecondary,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Section cards ────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final section = QSourceData.allSections[index];
                    return _SectionCard(
                      section: section,
                      isExpanded: _expanded[index],
                      onToggle: () {
                        setState(() => _expanded[index] = !_expanded[index]);
                      },
                    );
                  },
                  childCount: QSourceData.allSections.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final QGuideSection section;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _SectionCard({
    required this.section,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: context.f3card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded
                ? F3Colors.accent.withValues(alpha: 0.35)
                : context.f3divider,
          ),
        ),
        child: Column(
          children: [
            // Header — always visible, full tap area
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggle,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                    bottom: Radius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.title,
                              style: TextStyle(
                                color: isExpanded
                                    ? F3Colors.accent
                                    : context.f3textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                            if (section.subtitle != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                section.subtitle!,
                                style: TextStyle(
                                  color: context.f3textMuted,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: context.f3textSecondary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Expandable content
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  Divider(
                      height: 1, thickness: 1, color: context.f3divider),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: Column(
                      children: section.entries
                          .map((entry) => _EntryRow(entry: entry))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Entry row ────────────────────────────────────────────────────────────────

class _EntryRow extends StatelessWidget {
  final QGuideEntry entry;

  const _EntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LeadingIcon(style: entry.style),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: TextStyle(
                    color: entry.style == QEntryStyle.note
                        ? context.f3textSecondary
                        : context.f3textPrimary,
                    fontSize: 15,
                    fontWeight: entry.style == QEntryStyle.heading
                        ? FontWeight.w800
                        : FontWeight.w600,
                    fontStyle: entry.style == QEntryStyle.note
                        ? FontStyle.italic
                        : FontStyle.normal,
                    height: 1.3,
                  ),
                ),
                if (entry.detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.detail!,
                    style: TextStyle(
                      color: context.f3textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
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

// ─── Leading icon by style ────────────────────────────────────────────────────

class _LeadingIcon extends StatelessWidget {
  final QEntryStyle style;

  const _LeadingIcon({required this.style});

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case QEntryStyle.check:
        return const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.check_box_outline_blank_rounded,
              color: F3Colors.accent, size: 20),
        );
      case QEntryStyle.numbered:
        // Numbered entries use an accent dot; the number comes from content.
        return const Padding(
          padding: EdgeInsets.only(top: 3),
          child: Icon(Icons.arrow_right_rounded,
              color: F3Colors.phaseThang, size: 20),
        );
      case QEntryStyle.heading:
        return const SizedBox(width: 20);
      case QEntryStyle.note:
        return const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.lightbulb_outline_rounded,
              color: F3Colors.phaseCOT, size: 18),
        );
      case QEntryStyle.bullet:
        return Padding(
          padding: EdgeInsets.only(top: 6),
          child: CircleAvatar(
            backgroundColor: context.f3textSecondary,
            radius: 3,
          ),
        );
    }
  }
}
