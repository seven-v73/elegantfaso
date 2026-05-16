import 'package:shared_preferences/shared_preferences.dart';

class FormDraftService {
  const FormDraftService();

  Future<void> saveDraft(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> loadDraft(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> clearDraft(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
