// lib/services/feed_reaction_service.dart
// Local "salute" reactions on Activity Feed items — a single-user app has
// no honest way to show "12 people reacted", so this is deliberately a
// personal acknowledgment toggle (did I salute this), not a fake shared
// counter. Keyed by FeedItem.id since feed items are recomputed fresh on
// every build rather than persisted with their own stored id.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedReactionService extends ChangeNotifier {
  static const _key = 'feed_reactions_v1';

  Set<String> _saluted = {};
  SharedPreferences? _prefs;

  bool isSaluted(String feedItemId) => _saluted.contains(feedItemId);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _saluted = (_prefs!.getStringList(_key) ?? const []).toSet();
  }

  Future<void> toggle(String feedItemId) async {
    if (_saluted.contains(feedItemId)) {
      _saluted.remove(feedItemId);
    } else {
      _saluted.add(feedItemId);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    if (_prefs == null) return;
    await _prefs!.setStringList(_key, _saluted.toList());
  }
}
