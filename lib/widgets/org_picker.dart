// lib/widgets/org_picker.dart
// Searchable region picker — search by org name or numeric id. Fetches the
// org list itself (with a manual refresh affordance) rather than taking a
// static list, so a failed/empty fetch isn't a dead end.

import 'package:flutter/material.dart';
import '../models/f3_api_models.dart';
import '../theme/app_theme.dart';

/// Shows a searchable list of orgs (loaded via [fetchOrgs]) and returns the
/// chosen one, or null if dismissed without a choice.
Future<F3Org?> showOrgPickerSheet(
  BuildContext context, {
  required Future<List<F3Org>> Function() fetchOrgs,
}) {
  return showModalBottomSheet<F3Org?>(
    context: context,
    backgroundColor: context.f3card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _OrgPickerSheet(fetchOrgs: fetchOrgs),
  );
}

class _OrgPickerSheet extends StatefulWidget {
  final Future<List<F3Org>> Function() fetchOrgs;
  const _OrgPickerSheet({required this.fetchOrgs});

  @override
  State<_OrgPickerSheet> createState() => _OrgPickerSheetState();
}

class _OrgPickerSheetState extends State<_OrgPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  List<F3Org> _orgs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orgs = await widget.fetchOrgs();
    if (!mounted) return;
    setState(() {
      _orgs = orgs;
      _loading = false;
    });
  }

  List<F3Org> get _filtered {
    if (_query.isEmpty) return _orgs;
    final q = _query.toLowerCase();
    return _orgs
        .where((o) => o.name.toLowerCase().contains(q) || o.id.contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: context.f3divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    style: TextStyle(color: context.f3textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search by region name or org id',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: context.f3elevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loading ? null : _load,
                  tooltip: 'Refresh regions',
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ]),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _orgs.isEmpty
                                    ? 'Couldn\'t load regions.'
                                    : 'No regions match "$_query".',
                                style:
                                    TextStyle(color: context.f3textMuted),
                              ),
                              if (_orgs.isEmpty) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _load,
                                  icon: const Icon(Icons.refresh_rounded,
                                      size: 18),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (context, i) {
                            final org = results[i];
                            return ListTile(
                              title: Text(org.name,
                                  style:
                                      TextStyle(color: context.f3textPrimary)),
                              subtitle: Text('Org ${org.id}',
                                  style: TextStyle(color: context.f3textMuted)),
                              onTap: () => Navigator.pop(context, org),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
