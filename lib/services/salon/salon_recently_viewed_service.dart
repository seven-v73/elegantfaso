import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/salon/salon_item.dart';

class SalonRecentlyViewedService {
  static const _key = 'salon_recently_viewed_items';

  Future<List<SalonItem>> load({int limit = 12}) async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_key) ?? const [];
    return values
        .map(_decode)
        .whereType<SalonItem>()
        .take(limit)
        .toList(growable: false);
  }

  Future<void> remember(SalonItem item, {int limit = 24}) async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_key) ?? const [];
    final encoded = jsonEncode({
      ...item.toRecentMap(),
      'viewedAt': DateTime.now().toIso8601String(),
    });
    final next = <String>[encoded];
    for (final value in values) {
      final recent = _decode(value);
      if (recent == null) continue;
      if (recent.id == item.id && recent.type == item.type) continue;
      next.add(value);
      if (next.length >= limit) break;
    }
    await prefs.setStringList(_key, next);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  SalonItem? _decode(String raw) {
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return null;
      return SalonItem.fromRecentMap(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }
}
