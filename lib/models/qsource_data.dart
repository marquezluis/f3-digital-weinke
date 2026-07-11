// lib/models/qsource_data.dart
// Offline Q/QSource field guide data — structured sections for new Qs at 5:30 AM.
// No Flutter dependencies; pure Dart model.
//
// NOTE: This is an unofficial condensed guide built by PAX for PAX.
// Before public/nationwide distribution, verify permission, branding,
// and content usage with appropriate F3 leadership.

/// A named section of the Q/QSource guide.
class QGuideSection {
  final String title;
  final String? subtitle;
  final List<QGuideEntry> entries;

  const QGuideSection({
    required this.title,
    this.subtitle,
    required this.entries,
  });
}

/// A single entry within a guide section — either a checklist item or
/// a descriptive block with an optional detail.
class QGuideEntry {
  final String label;
  final String? detail;
  final QEntryStyle style;

  const QGuideEntry({
    required this.label,
    this.detail,
    this.style = QEntryStyle.bullet,
  });
}

enum QEntryStyle {
  bullet,    // •  standard bullet point
  check,     //    checklist item (displayed with checkbox icon)
  numbered,  // 1. numbered step
  heading,   //    sub-heading inside a section
  note,      //    italicised advisory note
}

// ─────────────────────────────────────────────────────────────────────────────
// Static data — all sections of the Q/QSource field guide
// ─────────────────────────────────────────────────────────────────────────────

class QSourceData {
  QSourceData._();

  // ── 1. Five Core F3 Workout Principles ──────────────────────────────────────
  static const QGuideSection workoutPrinciples = QGuideSection(
    title: 'F3 WORKOUT PRINCIPLES',
    subtitle: 'A workout must meet all five to be an official F3 beatdown.',
    entries: [
      QGuideEntry(
        label: 'Free',
        detail: 'There is no charge to participate. Ever.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Open to all men',
        detail: 'Any man can show up. No invite, no screening.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Outdoors — rain or shine',
        detail: 'Held outside in all weather conditions. Only lightning or true safety threats cancel.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Peer-led in rotating fashion',
        detail: 'Led by a PAX member, not a hired professional. No certification required. Leadership rotates.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Ends with COT',
        detail: 'Circle of Trust closes every beatdown: Count-O-Rama, Name-O-Rama, FNGs, announcements, closing word.',
        style: QEntryStyle.check,
      ),
    ],
  );

  // ── 2. Standard Disclaimer ───────────────────────────────────────────────────
  static const QGuideSection disclaimer = QGuideSection(
    title: 'DISCLAIMER',
    subtitle: 'Read at the start of every beatdown — verbatim or close to it.',
    entries: [
      QGuideEntry(
        label: 'This is a free, volunteer, peer-led workout.',
        style: QEntryStyle.bullet,
      ),
      QGuideEntry(
        label: 'I am not a professional.',
        style: QEntryStyle.bullet,
      ),
      QGuideEntry(
        label: 'I have no knowledge of your injuries or fitness considerations.',
        style: QEntryStyle.bullet,
      ),
      QGuideEntry(
        label: 'You are responsible for your own safety.',
        style: QEntryStyle.bullet,
      ),
      QGuideEntry(
        label: 'Modify anything as needed. Know your limits.',
        style: QEntryStyle.bullet,
      ),
    ],
  );

  // ── 3. Sample Workout Structure ──────────────────────────────────────────────
  static const QGuideSection workoutStructure = QGuideSection(
    title: 'WORKOUT STRUCTURE',
    subtitle: 'Standard 50-minute beatdown phases.',
    entries: [
      QGuideEntry(
        label: 'Disclaimer',
        detail: '~1 min · Read disclaimer, call out FNGs.',
        style: QEntryStyle.numbered,
      ),
      QGuideEntry(
        label: 'Warm-O-Rama / CoP',
        detail: '~7 min · Circle of Pain — SSH, Windmills, Arm Circles, Imperial Walkers, etc.',
        style: QEntryStyle.numbered,
      ),
      QGuideEntry(
        label: 'The Thang',
        detail: '~32 min · Main workout: circuits, Doras, AMRAPs, Tabatas, or free choice. Mix bodyweight + coupons.',
        style: QEntryStyle.numbered,
      ),
      QGuideEntry(
        label: '6MoM / Mary',
        detail: '~6 min · Six Minutes of Mary: core/ab work, PAX call exercises.',
        style: QEntryStyle.numbered,
      ),
      QGuideEntry(
        label: 'COT',
        detail: '~4 min · Circle of Trust: count, names, FNGs, announcements, words/prayer.',
        style: QEntryStyle.numbered,
      ),
    ],
  );

  // ── 4. Q Prep Reminders ──────────────────────────────────────────────────────
  static const QGuideSection qPrepReminders = QGuideSection(
    title: 'Q PREP REMINDERS',
    subtitle: 'Things new Qs forget. Review the night before.',
    entries: [
      QGuideEntry(
        label: 'Start and end on time',
        detail: 'Wear a watch. PAX have jobs and families.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Expect cadence to be harder than practice',
        detail: 'Counting out loud while exercising is a different skill. Do a dry run.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Ask for help or Co-Q',
        detail: 'No shame in splitting the Q. Experienced PAX love being asked.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Keep calm and keep moving',
        detail: 'If you blank, call a mosey. Motion is your default filler.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'No man left behind',
        detail: 'The Six sets the pace. Don\'t lose the Six.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Offer extra credit to frontrunners',
        detail: 'Send fast PAX on extra laps or reps while the Six catches up.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Avoid unnecessary risks',
        detail: 'Check the site beforehand. No dark trails, unsecured equipment, or traffic.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Think of COT words in advance',
        detail: 'What\'s the one thing you want to leave the PAX with today?',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Have fun',
        detail: 'Your energy is contagious. If you\'re having fun, the PAX will too.',
        style: QEntryStyle.check,
      ),
    ],
  );

  // ── 5. Cadence Assistant ─────────────────────────────────────────────────────
  static const QGuideSection cadenceAssistant = QGuideSection(
    title: 'CADENCE ASSISTANT',
    subtitle: 'The sequence for calling an exercise in cadence.',
    entries: [
      QGuideEntry(
        label: 'Announce the exercise',
        detail: '"The next exercise is [exercise name]."',
        style: QEntryStyle.numbered,
      ),
      QGuideEntry(
        label: 'Call starting position',
        detail: '"Starting position… Move!" — PAX get into position.',
        style: QEntryStyle.numbered,
      ),
      QGuideEntry(
        label: 'Call the exercise',
        detail: '"In cadence… Exercise!" — begin counting.',
        style: QEntryStyle.numbered,
      ),
      QGuideEntry(
        label: 'Q counts 1–2–3',
        detail: 'Leader calls "One, Two, Three —" PAX call the rep number.',
        style: QEntryStyle.numbered,
      ),
      QGuideEntry(
        label: 'PAX counts the rep',
        detail: '"One!" "Two!" "Three!" etc. until the target rep count is reached.',
        style: QEntryStyle.numbered,
      ),
      QGuideEntry(
        label: 'Recover / Halt',
        detail: '"Recover!" — PAX return to rest position.',
        style: QEntryStyle.numbered,
      ),
      QGuideEntry(
        label: 'Watch form — halt if it breaks',
        detail: 'Quality over quantity. Call "Halt!" and correct form rather than grinding through bad reps.',
        style: QEntryStyle.note,
      ),
    ],
  );

  // ── 6. COT Checklist ─────────────────────────────────────────────────────────
  static const QGuideSection cotChecklist = QGuideSection(
    title: 'COT CHECKLIST',
    subtitle: 'Circle of Trust — closes every beatdown.',
    entries: [
      QGuideEntry(
        label: 'Count-O-Rama',
        detail: 'PAX count off around the circle to get total attendance.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Name-O-Rama',
        detail: 'Each PAX says their F3 name.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'FNGs',
        detail: 'Welcome any First Namers. Give them their F3 name now if the group is ready.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Announcements',
        detail: 'Region events, convergences, service opportunities, prayer requests.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Shoutout / BOM / words / prayer / reflection',
        detail: 'Brief and personal. Q closes with a word, shoutout, or prayer as appropriate for the audience.',
        style: QEntryStyle.check,
      ),
    ],
  );

  // ── 7. Backblast Template ────────────────────────────────────────────────────
  static const QGuideSection backblastTemplate = QGuideSection(
    title: 'BACKBLAST TEMPLATE',
    subtitle: 'Post within 24h to Slack, newsletter, or whatever your region uses.',
    entries: [
      QGuideEntry(
        label: 'Title',
        detail: 'e.g. "Beatdown at [AO Name] — [Date]"',
        style: QEntryStyle.bullet,
      ),
      QGuideEntry(
        label: 'Date',
        style: QEntryStyle.bullet,
      ),
      QGuideEntry(
        label: 'AO / Location',
        style: QEntryStyle.bullet,
      ),
      QGuideEntry(
        label: 'PAX',
        detail: 'List all F3 names, FNGs listed as "FNG [name]".',
        style: QEntryStyle.bullet,
      ),
      QGuideEntry(
        label: 'FNG count',
        style: QEntryStyle.bullet,
      ),
      QGuideEntry(
        label: 'Q',
        detail: 'Your F3 name.',
        style: QEntryStyle.bullet,
      ),
      QGuideEntry(
        label: 'Count',
        detail: 'Total PAX including Q.',
        style: QEntryStyle.bullet,
      ),
      QGuideEntry(
        label: 'The Thang',
        detail: 'What you did — exercises, reps, format. Bullet list is fine.',
        style: QEntryStyle.bullet,
      ),
      QGuideEntry(
        label: 'Observations / Spreadsheets from the Gloom',
        detail: 'Memorable moments, quotes, callouts. This is the soul of the backblast.',
        style: QEntryStyle.bullet,
      ),
    ],
  );

  // ── 8. Spartan's Q Coaching ───────────────────────────────────────────────────
  static const QGuideSection spartanCoaching = QGuideSection(
    title: 'SPARTAN\'S Q COACHING',
    subtitle: 'Pro-tips to tighten your beatdown and lead the PAX effectively.',
    entries: [
      QGuideEntry(
        label: 'Avoid: Too much complexity',
        detail: 'If it takes more than 30 seconds to explain the evolution, it\'s too complicated. Keep it simple.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Avoid: Unsafe fatigue stacking',
        detail: 'Don\'t stack heavy shoulder exercises (like Merkins) back-to-back without a transitional leg or core movement. Mix up the muscle groups.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Scaling for FNGs (Friendly New Guys)',
        detail: 'Never isolate an FNG. Emphasize "modify as necessary." Use AMRAPs (As Many Reps As Possible) in a set time rather than strict rep counts so everyone finishes together.',
        style: QEntryStyle.bullet,
      ),
      QGuideEntry(
        label: 'Gloom Prep: Rain & Cold',
        detail: 'If it\'s below freezing, skip exercises that keep PAX motionless on their backs for too long (like long Mary sessions). Keep them moving.',
        style: QEntryStyle.bullet,
      ),
      QGuideEntry(
        label: 'Mumblechatter Control',
        detail: 'Mumblechatter means they have too much breath. Call for Burpees or a "Code Red" to quiet the crowd and empty the tank.',
        style: QEntryStyle.bullet,
      ),
      QGuideEntry(
        label: 'Keep the 6',
        detail: 'The Six is the man in the back. When running, circle back for him. When doing reps, hold Al Gore or Plank until the Six completes his reps.',
        style: QEntryStyle.bullet,
      ),
    ],
  );

  // ── 8. QSource Best Practices ────────────────────────────────────────────────
  static const QGuideSection qsourceBestPractices = QGuideSection(
    title: 'QSOURCE BEST PRACTICES',
    subtitle: 'For facilitating a QSource leadership discussion.',
    entries: [
      QGuideEntry(
        label: 'Announce it early',
        detail: 'Give the group notice so they can prep.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Send a reminder with topic',
        detail: '24–48h before. Keep it short.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Respect time commitment',
        detail: 'Start and end on time. Typical session is 30–45 min.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Bring substantive content',
        detail: 'Come prepared with a statement and questions, not just a topic.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Facilitate, don\'t lecture',
        detail: 'You are not the expert. Draw out the room.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Use open-ended Socratic questions',
        detail: '"What does this look like at home?" is better than "Agree or disagree?"',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Encourage quiet members',
        detail: '"[Name], what\'s your take?" — gently, not on the spot.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Make it actionable',
        detail: 'Connect to marriage, family, work, and community. Abstract = forgotten.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Close on time',
        detail: 'State the action item and next week\'s topic before dismissing.',
        style: QEntryStyle.check,
      ),
    ],
  );

  // ── 9. QSource Agenda ────────────────────────────────────────────────────────
  static const QGuideSection qsourceAgenda = QGuideSection(
    title: 'QSOURCE AGENDA',
    subtitle: 'A repeatable session structure. Adapt as needed.',
    entries: [
      QGuideEntry(
        label: 'Disclaimer',
        detail: 'Remind the group: peer-led discussion, not professional advice.',
        style: QEntryStyle.numbered,
      ),
      QGuideEntry(
        label: 'Optional prayer / reflection',
        detail: 'Read the room. Keep it brief and inclusive.',
        style: QEntryStyle.numbered,
      ),
      QGuideEntry(
        label: 'Prior week recap',
        detail: 'Did anyone act on last week\'s Spur? What happened?',
        style: QEntryStyle.numbered,
      ),
      QGuideEntry(
        label: 'Statement',
        detail: 'One clear, direct statement that frames the discussion.',
        style: QEntryStyle.numbered,
      ),
      QGuideEntry(
        label: 'Optional scripture / context',
        detail: 'A supporting reference if relevant. Keep it short.',
        style: QEntryStyle.numbered,
      ),
      QGuideEntry(
        label: 'Socratic questions',
        detail: 'Two to four open-ended questions to drive discussion. Don\'t rush.',
        style: QEntryStyle.numbered,
      ),
      QGuideEntry(
        label: 'Spurs / action plan',
        detail: 'One concrete action each man can take this week. Specific beats vague.',
        style: QEntryStyle.numbered,
      ),
      QGuideEntry(
        label: 'Closing action statement',
        detail: 'Summarise the one takeaway in a single sentence.',
        style: QEntryStyle.numbered,
      ),
      QGuideEntry(
        label: 'Next week preview',
        detail: 'Name the topic so men can think about it in advance.',
        style: QEntryStyle.numbered,
      ),
    ],
  );

  // ── 10. QSource Backblast & Follow-Up ────────────────────────────────────────
  static const QGuideSection qsourceFollowUp = QGuideSection(
    title: 'QSOURCE FOLLOW-UP',
    subtitle: 'After the session.',
    entries: [
      QGuideEntry(
        label: 'Send backblast within 24h',
        detail: 'Statement, questions asked, action item / Spur, next topic.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'KISH — Keep It Simple, High Impact',
        detail: 'Short backblast beats no backblast. Bullet points are fine.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Touch base with quiet members',
        detail: 'A brief 1:1 message goes a long way.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Seek feedback / AAR',
        detail: 'After Action Review: what worked, what to improve.',
        style: QEntryStyle.check,
      ),
      QGuideEntry(
        label: 'Share leadership',
        detail: 'Invite another PAX to Q the next session. Develop leaders.',
        style: QEntryStyle.check,
      ),
    ],
  );

  // ── 11. QSource Execution Types ──────────────────────────────────────────────
  static const QGuideSection qsourceFormats = QGuideSection(
    title: 'QSOURCE FORMATS',
    subtitle: 'How and when to run a QSource session.',
    entries: [
      QGuideEntry(
        label: 'After the beatdown',
        detail: 'Most common. Men are already gathered; momentum is high. Keep to 30 min.',
        style: QEntryStyle.bullet,
      ),
      QGuideEntry(
        label: 'Before the beatdown',
        detail: 'Works well at early AOs. Sets the tone for the workout. Keep it tight — 15 min max.',
        style: QEntryStyle.bullet,
      ),
      QGuideEntry(
        label: 'During a ruck',
        detail: 'Natural, conversational format. Walking reduces performance pressure. Good for deeper topics.',
        style: QEntryStyle.bullet,
      ),
      QGuideEntry(
        label: 'Virtual',
        detail: 'Video call or async channel. Widens participation across regions. Follow-up is especially important.',
        style: QEntryStyle.bullet,
      ),
    ],
  );

  // ── All sections in display order ────────────────────────────────────────────
  static const List<QGuideSection> allSections = [
    workoutPrinciples,
    disclaimer,
    workoutStructure,
    qPrepReminders,
    cadenceAssistant,
    cotChecklist,
    backblastTemplate,
    spartanCoaching,
    qsourceBestPractices,
    qsourceAgenda,
    qsourceFollowUp,
    qsourceFormats,
  ];
}
