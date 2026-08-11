// lib/models/cot_quotes.dart
// A closing-moment quote for the Circle of Trust, distinct from Home's
// daily mottos — those are "get up and go" energy for the start of a day;
// this is reflective, grounded in the 3 F's specifically, for the moment
// the workout is actually over and the circle has formed.

const List<String> cotQuotes = [
  'Fitness is the front door. Fellowship is why you stay. Faith is what it\'s really about.',
  'The workout ends. The brotherhood doesn\'t.',
  'No man is made better alone. Iron sharpens iron — that\'s why we\'re circled up right now.',
  'Fitness fades by tomorrow. What you just did for the man next to you doesn\'t.',
  'Faith isn\'t a fourth F bolted on at the end — it\'s the reason the other two matter at all.',
  'Every rep was for your body. This circle is for everything else.',
  'A man who trains alone gets stronger. A man who trains in this circle gets better.',
  'Fellowship is fitness for the parts of you a scale can\'t measure.',
  'You came for the gloom. You\'re leaving with brothers who\'ll show up when it actually matters.',
  'Fitness, fellowship, faith — in that order, none of it means much without the other two.',
  'The hardest rep today wasn\'t physical. It was showing up in the first place.',
  'This is the part of the workout that actually lasts.',
];

/// Deterministic per-day pick so the quote doesn't change mid-session if the
/// COT card rebuilds, same rotation approach as Home's daily motto.
String cotQuoteFor(DateTime day) {
  final dayOfYear = day.difference(DateTime(day.year, 1, 1)).inDays;
  return cotQuotes[dayOfYear % cotQuotes.length];
}
