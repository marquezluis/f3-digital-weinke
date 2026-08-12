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
import 'package:shared_preferences/shared_preferences.dart';
import '../models/qsource_data.dart';
import '../theme/app_theme.dart';

class QSourceScreen extends StatefulWidget {
  const QSourceScreen({super.key});

  @override
  State<QSourceScreen> createState() => _QSourceScreenState();
}

class _QSourceScreenState extends State<QSourceScreen> {
  static const _keyBookmarks = 'qsource_bookmarks_v1';
  static const _keyRecent = 'qsource_recent_v1';
  static const _maxRecent = 5;

  // Track which sections are expanded; start with first two open.
  late final List<bool> _expanded;
  late final List<GlobalKey> _sectionKeys;
  Set<String> _bookmarks = {};
  List<String> _recent = [];

  @override
  void initState() {
    super.initState();
    _expanded = List.generate(
      QSourceData.allSections.length,
      (i) => i < 2, // first two sections open by default
    );
    _sectionKeys =
        List.generate(QSourceData.allSections.length, (_) => GlobalKey());
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _bookmarks = (prefs.getStringList(_keyBookmarks) ?? []).toSet();
      _recent = prefs.getStringList(_keyRecent) ?? [];
    });
  }

  Future<void> _toggleBookmark(String title) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_bookmarks.contains(title)) {
        _bookmarks.remove(title);
      } else {
        _bookmarks.add(title);
      }
    });
    await prefs.setStringList(_keyBookmarks, _bookmarks.toList());
  }

  Future<void> _recordRecentlyViewed(String title) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recent.remove(title);
      _recent.insert(0, title);
      if (_recent.length > _maxRecent) {
        _recent = _recent.sublist(0, _maxRecent);
      }
    });
    await prefs.setStringList(_keyRecent, _recent);
  }

  void _jumpTo(String title) {
    final index =
        QSourceData.allSections.indexWhere((s) => s.title == title);
    if (index == -1) return;
    if (!_expanded[index]) {
      setState(() => _expanded[index] = true);
    }
    _recordRecentlyViewed(title);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _sectionKeys[index].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 300), alignment: 0.05);
      }
    });
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

            // ── Quick jump (bookmarks + recently viewed) ─────────────────────
            if (_bookmarks.isNotEmpty || _recent.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _QuickJumpRow(
                    bookmarks: _bookmarks,
                    recent: _recent,
                    onTap: _jumpTo,
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
                      key: _sectionKeys[index],
                      section: section,
                      isExpanded: _expanded[index],
                      isBookmarked: _bookmarks.contains(section.title),
                      onToggle: () {
                        final opening = !_expanded[index];
                        setState(() => _expanded[index] = opening);
                        if (opening) _recordRecentlyViewed(section.title);
                      },
                      onToggleBookmark: () => _toggleBookmark(section.title),
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

// ─── Quick jump row ───────────────────────────────────────────────────────────
// Bookmarks first, then recently-viewed sections not already bookmarked —
// a Q prepping before a workout used to re-search from scratch every time.

class _QuickJumpRow extends StatelessWidget {
  final Set<String> bookmarks;
  final List<String> recent;
  final ValueChanged<String> onTap;

  const _QuickJumpRow({
    required this.bookmarks,
    required this.recent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final recentOnly = recent.where((t) => !bookmarks.contains(t));
    final chips = [...bookmarks, ...recentOnly];
    if (chips.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final title = chips[i];
          final isBookmark = bookmarks.contains(title);
          return ActionChip(
            avatar: Icon(
              isBookmark ? Icons.bookmark_rounded : Icons.history_rounded,
              size: 15,
              color: isBookmark ? F3Colors.accent : context.f3textMuted,
            ),
            label: Text(title, style: const TextStyle(fontSize: 12)),
            onPressed: () => onTap(title),
            backgroundColor: context.f3card,
            side: BorderSide(color: context.f3divider),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final QGuideSection section;
  final bool isExpanded;
  final bool isBookmarked;
  final VoidCallback onToggle;
  final VoidCallback onToggleBookmark;

  const _SectionCard({
    super.key,
    required this.section,
    required this.isExpanded,
    required this.isBookmarked,
    required this.onToggle,
    required this.onToggleBookmark,
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
                      IconButton(
                        tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark this section',
                        icon: Icon(
                          isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: isBookmarked
                              ? F3Colors.accent
                              : context.f3textMuted,
                          size: 20,
                        ),
                        onPressed: onToggleBookmark,
                        visualDensity: VisualDensity.compact,
                      ),
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
