// lib/models/mumblechatter_lines.dart
// A curated bank of Q call-outs for Q Mode — nothing F3-Nation-API-shaped
// here, just flavor text a Q can fire off mid-beatdown without having to
// think one up on the spot.

class MumblechatterLines {
  MumblechatterLines._();

  static const List<String> lines = [
    "Pain is just weakness leaving the body!",
    "Embrace the suck!",
    "Modify, don't quit!",
    "If you ain't sweatin', you ain't tryin'!",
    "Nobody said this would be easy, they said it'd be worth it!",
    "Check your ego, not your effort!",
    "Slow is smooth, smooth is fast — keep the form!",
    "You're stronger than your excuses!",
    "Leave no PAX behind!",
    "This is why we call it a beatdown, not a walk-down!",
    "Fast feet, big heart!",
    "The only easy day was yesterday!",
    "Find your Two-and-a-half Man and pick him up!",
    "Mumblechatter means you've got breath to spare — let's fix that!",
    "Fourth quarter is where beatdowns are won!",
  ];

  static String random() => (List.of(lines)..shuffle()).first;
}
