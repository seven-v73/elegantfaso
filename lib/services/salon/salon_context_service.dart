import 'package:shared_preferences/shared_preferences.dart';

import '../../models/salon/salon_context.dart';

class SalonContextService {
  static const _recentKey = 'salon_recent_contexts';

  Future<List<SalonContext>> loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_recentKey) ?? const [];
    return values
        .map((value) => SalonContext.fromQuery(value, source: 'recent'))
        .where((context) => !context.isEmpty)
        .toList();
  }

  Future<void> remember(SalonContext context) async {
    final query = context.displayQuery.trim();
    if (query.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_recentKey) ?? const [];
    final next =
        [query, ...values.where((item) => item != query)].take(8).toList();
    await prefs.setStringList(_recentKey, next);
  }

  Future<void> remove(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_recentKey) ?? const [];
    await prefs.setStringList(
      _recentKey,
      values.where((item) => item.trim() != clean).toList(),
    );
  }

  Future<void> clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
  }
}
