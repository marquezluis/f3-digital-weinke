// lib/screens/schedule_screen.dart
// Tier 1 of the "unified app" loop: the weekly schedule of upcoming beatdowns
// for the signed-in PAX's region, with HC (sign up), take-Q, and preblast
// actions. Reads/writes the F3 Nation API; requires F3 login for the write
// actions (self-signup uses the user's own token, no editor role needed).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_models.dart';
import '../models/f3_api_models.dart';
import '../services/app_profile_service.dart' hide AppRole;
import '../services/auth_service.dart';
import '../services/f3_api_service.dart';
import '../theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _loading = true;
  List<F3EventInstance> _events = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final api = context.read<F3ApiService>();
    final token = await auth.getF3AccessToken();
    final events = await api.getUpcomingBeatdowns(userAccessToken: token);
    if (!mounted) return;
    setState(() {
      _events = events;
      _loading = false;
    });
  }

  Future<void> _openEvent(F3EventInstance event) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.f3card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EventDetailSheet(event: event),
    );
    _load(); // refresh counts after any action
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<F3ApiService>();
    return Scaffold(
      backgroundColor: context.f3bg,
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: context.f3bg,
      ),
      body: !api.isConfigured
          ? const _Empty(
              icon: Icons.cloud_off_rounded,
              title: 'F3 Nation API not configured',
              subtitle: 'This build isn\'t connected to the F3 Nation API.')
          : RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _events.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 120),
                          _Empty(
                            icon: Icons.event_busy_rounded,
                            title: 'No upcoming beatdowns',
                            subtitle:
                                'Nothing scheduled for your region yet, or your '
                                'home region isn\'t set. Pull to refresh.',
                          ),
                        ])
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _events.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) => _EventCard(
                            event: _events[i],
                            onTap: () => _openEvent(_events[i]),
                          ),
                        ),
            ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final F3EventInstance event;
  final VoidCallback onTap;
  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.f3card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.f3divider),
          ),
          child: Row(children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(_month(event.date),
                    style: const TextStyle(
                        color: F3Colors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
                Text('${event.date.day}',
                    style: TextStyle(
                        color: context.f3textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.orgName ?? event.locationName ?? 'Beatdown',
                      style: TextStyle(
                          color: context.f3textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (event.startTime != null) event.startTime,
                      event.hasQ ? 'Q: ${event.qF3Name ?? "set"}' : 'Q needed',
                    ].join(' · '),
                    style: TextStyle(
                        color: event.hasQ
                            ? context.f3textSecondary
                            : F3Colors.accent,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            if ((event.hcCount ?? 0) > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: F3Colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${event.hcCount} HC',
                    style: const TextStyle(
                        color: F3Colors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
            Icon(Icons.chevron_right_rounded,
                color: context.f3textMuted, size: 20),
          ]),
        ),
      ),
    );
  }

  String _month(DateTime d) => const [
        'JAN','FEB','MAR','APR','MAY','JUN',
        'JUL','AUG','SEP','OCT','NOV','DEC'
      ][d.month - 1];
}

/// Detail sheet: shows preblast + HC count and the action buttons (HC / take Q
/// / post preblast), gated on F3 login.
class _EventDetailSheet extends StatefulWidget {
  final F3EventInstance event;
  const _EventDetailSheet({required this.event});

  @override
  State<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<_EventDetailSheet> {
  bool _busy = false;
  String? _flash;

  bool get _linked =>
      context.read<AuthService>().currentUser?.identities.any(
            (i) => i.provider == AuthProvider.f3nation,
          ) ??
      false;

  Future<({String? token, int? uid, String? org})> _creds() async {
    final auth = context.read<AuthService>();
    final api = context.read<F3ApiService>();
    final profile = context.read<AppProfileService>();
    final token = await auth.getF3AccessToken();
    return (
      token: token,
      uid: int.tryParse(profile.authUserId),
      org: api.orgId,
    );
  }

  Future<void> _run(Future<String?> Function(int eiId, int uid, String token) op,
      String okMsg) async {
    final id = widget.event.numericId;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      final c = await _creds();
      if (c.token == null || c.uid == null) {
        setState(() => _flash = 'Sign in to F3 Nation first.');
        return;
      }
      final err = await op(id, c.uid!, c.token!);
      setState(() => _flash = err ?? okMsg);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _hc() => _run(
        (id, uid, token) => context.read<F3ApiService>().signUpForEvent(
            eventInstanceId: id, userId: uid, userAccessToken: token),
        'You\'re HC\'d — see you in the gloom.',
      );

  Future<void> _takeQ() => _run(
        (id, uid, token) => context.read<F3ApiService>().takeQ(
            eventInstanceId: id, userId: uid, userAccessToken: token),
        'You\'ve got the Q. Time to build a Weinke.',
      );

  Future<void> _postPreblast() async {
    final ctrl = TextEditingController(text: widget.event.preblast ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.f3card,
        title: const Text('Post Preblast'),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          autofocus: true,
          style: TextStyle(color: context.f3textPrimary),
          decoration: const InputDecoration(
              hintText: 'The plan, the theme, coupons, what to expect...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Post')),
        ],
      ),
    );
    if (text == null || text.isEmpty || !mounted) return;
    final api = context.read<F3ApiService>();
    final id = widget.event.numericId;
    final c = await _creds();
    if (id == null || c.org == null || c.org!.isEmpty) {
      setState(() => _flash = 'Need your region synced to post a preblast.');
      return;
    }
    setState(() => _busy = true);
    final err = await api.postPreblast(
        eventInstanceId: id, orgId: c.org!, preblast: text);
    if (mounted) {
      setState(() {
        _busy = false;
        _flash = err ?? 'Preblast posted.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: context.f3divider,
                borderRadius: BorderRadius.circular(2)),
          ),
          Text(e.orgName ?? e.locationName ?? 'Beatdown',
              style: TextStyle(
                  color: context.f3textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            [
              '${e.date.month}/${e.date.day}',
              if (e.startTime != null) e.startTime,
              e.hasQ ? 'Q: ${e.qF3Name ?? "set"}' : 'Q needed',
              if ((e.hcCount ?? 0) > 0) '${e.hcCount} HC',
            ].join(' · '),
            style: TextStyle(color: context.f3textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if ((e.preblast ?? '').isNotEmpty) ...[
            Text('PREBLAST',
                style: TextStyle(
                    color: context.f3textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
            const SizedBox(height: 6),
            Text(e.preblast!,
                style: TextStyle(
                    color: context.f3textSecondary, fontSize: 14, height: 1.4)),
            const SizedBox(height: 16),
          ],
          if (!_linked)
            Text('Sign in to F3 Nation (Settings) to HC or take the Q.',
                style: TextStyle(color: context.f3textMuted, fontSize: 12))
          else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _hc,
                icon: const Icon(Icons.how_to_reg_rounded),
                label: const Text('HC — I\'m in'),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              if (!e.hasQ)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _takeQ,
                    icon: const Icon(Icons.sports_rounded, size: 18),
                    label: const Text('Take Q'),
                  ),
                ),
              if (!e.hasQ) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _postPreblast,
                  icon: const Icon(Icons.campaign_rounded, size: 18),
                  label: Text(
                      (e.preblast ?? '').isEmpty ? 'Post Preblast' : 'Edit Preblast'),
                ),
              ),
            ]),
          ],
          if (_flash != null) ...[
            const SizedBox(height: 12),
            Text(_flash!,
                style: const TextStyle(
                    color: F3Colors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
          if (_busy) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Empty(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: context.f3textMuted, size: 48),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.f3textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.f3textSecondary, fontSize: 13)),
        ]),
      ),
    );
  }
}
