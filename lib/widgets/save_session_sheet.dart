// lib/widgets/save_session_sheet.dart
// Bottom sheet form to save the current workout session to local history.
// Accepts a pre-built list of HistoryBlocks extracted from the active plan.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_history.dart';
import '../services/app_profile_service.dart' hide AppRole;
import '../services/history_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class SaveSessionSheet extends StatefulWidget {
  /// Pre-populated blocks from the current WorkoutPlan.
  final List<HistoryBlock> blocks;
  /// Optional PAX names pre-filled from Name-O-Rama roll call.
  final String initialPax;
  /// Real minutes the Q Mode timer ran, if this came from a live session.
  final int? actualDurationMinutes;

  const SaveSessionSheet({
    super.key,
    required this.blocks,
    this.initialPax = '',
    this.actualDurationMinutes,
  });

  /// Convenience: push as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required List<HistoryBlock> blocks,
    String initialPax = '',
    int? actualDurationMinutes,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.f3card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SaveSessionSheet(
        blocks: blocks,
        initialPax: initialPax,
        actualDurationMinutes: actualDurationMinutes,
      ),
    );
  }

  @override
  State<SaveSessionSheet> createState() => _SaveSessionSheetState();
}

class _SaveSessionSheetState extends State<SaveSessionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _aoCtrl;
  late final TextEditingController _qCtrl;
  late final TextEditingController _paxCtrl;
  late final TextEditingController _fngCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _cotCtrl;
  late final TextEditingController _wotdCtrl;

  bool _saving = false;
  BeatdownType _beatdownType = BeatdownType.bootCamp;
  EventTag? _eventTag;
  List<String> _historyAOs  = [];
  List<String> _historyPax  = [];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: 'Digital Weinke Beatdown');
    _aoCtrl    = TextEditingController();
    _qCtrl     = TextEditingController();
    _paxCtrl   = TextEditingController(text: widget.initialPax);
    _fngCtrl   = TextEditingController(text: '0');
    _notesCtrl = TextEditingController();
    _cotCtrl   = TextEditingController();
    _wotdCtrl  = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = context.read<SettingsService>();
      final history  = context.read<HistoryService>();

      final profile = context.read<AppProfileService>();
      // Prefer the explicit "My F3 Name" setting, else the synced F3 Nation
      // profile name — a signed-in PAX shouldn't have to type their own Q.
      final myName = settings.myF3Name.isNotEmpty
          ? settings.myF3Name
          : profile.displayName;
      if (_qCtrl.text.isEmpty && myName.isNotEmpty) {
        _qCtrl.text = myName;
      }

      final sessions = history.all.where((e) => !e.isTemplate).toList();

      if (_aoCtrl.text.isEmpty && sessions.isNotEmpty) {
        final lastAo = sessions.first.ao;
        if (lastAo.isNotEmpty) _aoCtrl.text = lastAo;
      }

      // VQ auto-suggest: if the current Q has never logged a session at this
      // AO before, this may be their VQ (first time leading that AO) — default
      // the tag so they don't forget it. Q can clear it. Only fires when both
      // Q and AO are known and no tag was already chosen.
      if (_eventTag == null &&
          myName.isNotEmpty &&
          _aoCtrl.text.isNotEmpty) {
        final ledHereBefore = sessions.any((s) =>
            s.ao.toLowerCase() == _aoCtrl.text.toLowerCase() &&
            s.q.toLowerCase().contains(myName.toLowerCase()));
        if (!ledHereBefore) _eventTag = EventTag.vq;
      }

      // Unique AOs in recency order (up to 6)
      final seenAOs = <String>{};
      final aos = <String>[];
      for (final s in sessions) {
        if (s.ao.isNotEmpty && seenAOs.add(s.ao)) {
          aos.add(s.ao);
          if (aos.length >= 6) break;
        }
      }

      // All unique PAX across history, sorted A-Z
      final allPax = <String>{};
      for (final s in sessions) {
        allPax.addAll(s.pax);
      }
      final sortedPax = allPax.toList()..sort();

      setState(() {
        _historyAOs = aos;
        _historyPax = sortedPax;
      });
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _aoCtrl.dispose();
    _qCtrl.dispose();
    _paxCtrl.dispose();
    _fngCtrl.dispose();
    _notesCtrl.dispose();
    _cotCtrl.dispose();
    _wotdCtrl.dispose();
    super.dispose();
  }

  List<String> _parsePax() => _paxCtrl.text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  void _togglePax(String name) {
    setState(() {
      final list = _parsePax();
      if (list.contains(name)) {
        list.remove(name);
      } else {
        list.add(name);
      }
      _paxCtrl.text = list.join(', ');
    });
  }

  Future<void> _importFromSlack() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text ?? '';
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty.')),
        );
      }
      return;
    }
    setState(() {
      final aoMatch = RegExp(r'AO:\s*(.+)').firstMatch(text);
      if (aoMatch != null) _aoCtrl.text = (aoMatch.group(1) ?? '').trim();

      final qMatch = RegExp(r'Q:\s*(.+)').firstMatch(text);
      if (qMatch != null) {
        _qCtrl.text = (qMatch.group(1) ?? '').replaceAll('@', '').trim();
      }

      final paxMatch = RegExp(r'PAX:\s*(.+)').firstMatch(text) ??
          RegExp(r'HCs:\s*(.+)').firstMatch(text);
      if (paxMatch != null) {
        _paxCtrl.text = (paxMatch.group(1) ?? '').replaceAll('@', '').trim();
      }

      final fngMatch = RegExp(r'FNG[s]?:\s*([0-9]+)').firstMatch(text);
      if (fngMatch != null) _fngCtrl.text = (fngMatch.group(1) ?? '0').trim();

      // Extract ANNOUNCEMENTS section
      final announcementsMatch =
          RegExp(r'ANNOUNCEMENTS:\s*\n([\s\S]*?)(?=\nCOT:|\nCOT\s|\Z)',
                  caseSensitive: false)
              .firstMatch(text);
      if (announcementsMatch != null) {
        _notesCtrl.text = announcementsMatch.group(1)?.trim() ?? '';
      }

      // Extract COT section
      final cotMatch =
          RegExp(r'COT:\s*\n([\s\S]*?)$', caseSensitive: false)
              .firstMatch(text);
      if (cotMatch != null) {
        _cotCtrl.text = cotMatch.group(1)?.trim() ?? '';
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final paxRaw = _paxCtrl.text.trim();
    final paxList = paxRaw.isEmpty
        ? <String>[]
        : paxRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    final entry = WorkoutHistory(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      date: DateTime.now(),
      ao: _aoCtrl.text.trim(),
      q: _qCtrl.text.trim(),
      pax: paxList,
      fngCount: int.tryParse(_fngCtrl.text.trim()) ?? 0,
      notes: _notesCtrl.text.trim(),
      cot: _cotCtrl.text.trim(),
      wotd: _wotdCtrl.text.trim(),
      blocks: widget.blocks,
      beatdownType: _beatdownType,
      eventTag: _eventTag,
      actualDurationMinutes: widget.actualDurationMinutes,
    );

    await context.read<HistoryService>().add(entry);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session saved to history!'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle + title ─────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.f3divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SAVE BEATDOWN',
                    style: TextStyle(
                      color: F3Colors.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _importFromSlack,
                    icon: const Icon(Icons.content_paste_rounded, size: 16),
                    label: const Text('PASTE SLACK', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Record this session to your local history.',
                style: TextStyle(color: context.f3textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // ── Form fields ────────────────────────────────────────────
              _Field(
                controller: _titleCtrl,
                label: 'Title',
                hint: 'Digital Weinke Beatdown',
                icon: Icons.title_rounded,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // ── Beatdown Type ──────────────────────────────────────────
              Text(
                'Beatdown Type',
                style: TextStyle(color: context.f3textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: BeatdownType.values.map((type) {
                  final selected = _beatdownType == type;
                  return ChoiceChip(
                    label: Text(type.displayName,
                        style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => setState(() => _beatdownType = type),
                    backgroundColor: context.f3elevated,
                    selectedColor: F3Colors.accent.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                        color: selected ? F3Colors.accent : context.f3textSecondary,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal),
                    side: BorderSide(
                        color: selected ? F3Colors.accent : context.f3divider),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // ── Event Tag (optional) ────────────────────────────────────
              Text(
                'Event Tag (optional)',
                style: TextStyle(color: context.f3textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [null, ...EventTag.values].map((tag) {
                  final selected = _eventTag == tag;
                  return ChoiceChip(
                    label: Text(tag?.displayName ?? 'None',
                        style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => setState(() => _eventTag = tag),
                    backgroundColor: context.f3elevated,
                    selectedColor: F3Colors.accent.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                        color: selected ? F3Colors.accent : context.f3textSecondary,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal),
                    side: BorderSide(
                        color: selected ? F3Colors.accent : context.f3divider),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _aoCtrl,
                label: 'AO / Location',
                hint: 'e.g. The Shovel Flag, Central Park',
                icon: Icons.place_rounded,
              ),
              if (_historyAOs.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: _historyAOs.map((ao) {
                    final selected = _aoCtrl.text.trim() == ao;
                    return ChoiceChip(
                      label: Text(ao, style: const TextStyle(fontSize: 11)),
                      selected: selected,
                      onSelected: (_) => setState(() => _aoCtrl.text = ao),
                      backgroundColor: context.f3elevated,
                      selectedColor: F3Colors.accent.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                          color: selected ? F3Colors.accent : context.f3textSecondary),
                      side: BorderSide(
                          color: selected ? F3Colors.accent : context.f3divider),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              _Field(
                controller: _qCtrl,
                label: 'Q Name',
                hint: 'Your F3 name',
                icon: Icons.person_rounded,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _paxCtrl,
                label: 'PAX Names (comma-separated)',
                hint: 'Dredd, Mayhem, Roscoe…',
                icon: Icons.group_rounded,
                maxLines: 2,
              ),
              if (_historyPax.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _historyPax.map((name) {
                    final selected = _parsePax().contains(name);
                    return FilterChip(
                      label: Text(name, style: const TextStyle(fontSize: 11)),
                      selected: selected,
                      onSelected: (_) => _togglePax(name),
                      backgroundColor: context.f3elevated,
                      selectedColor: F3Colors.accent.withValues(alpha: 0.18),
                      checkmarkColor: F3Colors.accent,
                      labelStyle: TextStyle(
                          color: selected ? F3Colors.accent : context.f3textSecondary),
                      side: BorderSide(
                          color: selected ? F3Colors.accent : context.f3divider),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              _Field(
                controller: _fngCtrl,
                label: 'FNG Count',
                hint: '0',
                icon: Icons.new_label_rounded,
                keyboard: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (int.tryParse(v) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _notesCtrl,
                label: 'Announcements',
                hint: 'CPR training Aug 2 · check #general for details',
                icon: Icons.campaign_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _cotCtrl,
                label: 'COT (Closing Time)',
                hint: 'Prayers for the PAX, families, and community.',
                icon: Icons.volunteer_activism_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _wotdCtrl,
                label: 'Word of the Day (WOTD)',
                hint: 'e.g. Perseverance',
                icon: Icons.menu_book_rounded,
              ),
              const SizedBox(height: 24),

              // ── Save button ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'SAVING…' : 'SAVE SESSION'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reusable form field ──────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboard;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboard = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: TextStyle(color: context.f3textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.f3textSecondary, fontSize: 13),
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
      ),
      validator: validator,
    );
  }
}
