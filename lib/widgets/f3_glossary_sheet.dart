// lib/widgets/f3_glossary_sheet.dart
// A quick-reference glossary for F3 vocabulary the app uses constantly
// (Q, PAX, AO, HC...) with zero in-app explanation otherwise — the exact
// gap an EH-recruited FNG hits hardest.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const _f3GlossaryTerms = <(String, String)>[
  ('PAX', "A participant at a workout — that's you, once you post."),
  ('Q', 'The PAX leading that day\'s workout.'),
  ('AO', 'Area of Operations — the outdoor spot a workout happens at.'),
  ('Weinke', "A Q's workout plan for the day (this app's whole reason to exist)."),
  ('Preblast', 'A heads-up posted before a workout — what to expect, gear needed.'),
  ('Backblast', 'A recap posted after a workout — who showed, what happened.'),
  ('HC', "Hard Commit — saying you're posting, before you actually show up."),
  ('EH', 'Encourage & Hold accountable — inviting someone new to post.'),
  ('FNG', 'Friendly New Guy — a PAX at their first workout.'),
  ('COT', 'Circle of Trust — the closing moment: prayer requests, announcements.'),
];

Future<void> showF3GlossarySheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.f3card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('F3 Lingo',
                style: TextStyle(
                    color: sheetContext.f3textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('The words you\'ll see everywhere in this app',
                style: TextStyle(
                    color: sheetContext.f3textSecondary, fontSize: 12.5)),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints:
                  BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.5),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (term, def) in _f3GlossaryTerms)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 68,
                              child: Text(term,
                                  style: const TextStyle(
                                      color: F3Colors.accent,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14)),
                            ),
                            Expanded(
                              child: Text(def,
                                  style: TextStyle(
                                      color: sheetContext.f3textSecondary,
                                      fontSize: 13,
                                      height: 1.35)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
