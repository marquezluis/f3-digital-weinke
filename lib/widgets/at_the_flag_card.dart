// lib/widgets/at_the_flag_card.dart
// "I'm at the flag" — a one-tap personal check-in for today. Explicitly NOT
// a broadcast: there's no relay to other PAX's devices, this only shows on
// this PAX's own Home screen. Real value is reducing friction on logging
// attendance in the moment, rather than reconstructing it later when saving
// a backblast.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/region_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

String _shortTime(DateTime d) {
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final period = d.hour < 12 ? 'AM' : 'PM';
  return '$h12:${d.minute.toString().padLeft(2, '0')} $period';
}

class AtTheFlagCard extends StatelessWidget {
  const AtTheFlagCard({super.key});

  Future<void> _checkIn(BuildContext context) async {
    final region = context.read<RegionService>();
    final settings = context.read<SettingsService>();
    final controller = TextEditingController();
    final aoName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: sheetContext.f3card,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("I'm at the flag",
                  style: TextStyle(
                      color: sheetContext.f3textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Just for you — no one else sees this, it just saves you retyping the AO later.',
                style: TextStyle(color: sheetContext.f3textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              if (region.aos.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: region.aos
                      .map((ao) => ActionChip(
                            label: Text(ao.name),
                            onPressed: () =>
                                Navigator.pop(sheetContext, ao.name),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: controller,
                autofocus: region.aos.isEmpty,
                style: TextStyle(color: sheetContext.f3textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Or type an AO name',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (v) =>
                    Navigator.pop(sheetContext, v.trim()),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pop(sheetContext, controller.text.trim()),
                  child: const Text("CHECK IN"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (aoName != null && aoName.isNotEmpty) {
      await settings.checkInAtTheFlag(aoName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final aoName = settings.atTheFlagAo;
    final since = settings.atTheFlagSince;

    if (aoName == null || since == null) {
      return OutlinedButton.icon(
        onPressed: () => _checkIn(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: F3Colors.accent,
          side: BorderSide(color: F3Colors.accent.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: const Icon(Icons.location_on_rounded, size: 18),
        label: const Text("I'm at the flag"),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: F3Colors.phaseWarmup.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: F3Colors.phaseWarmup.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(Icons.location_on_rounded, color: F3Colors.phaseWarmup, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text('At $aoName since ${_shortTime(since)}',
              style: TextStyle(
                  color: context.f3textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700)),
        ),
        IconButton(
          icon: Icon(Icons.close_rounded, color: context.f3textMuted, size: 18),
          tooltip: 'Clear check-in',
          onPressed: () => context.read<SettingsService>().clearAtTheFlag(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }
}
