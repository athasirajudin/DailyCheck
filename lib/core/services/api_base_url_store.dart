import 'package:shared_preferences/shared_preferences.dart';

class ApiBaseUrlStore {
  static const String _prefsKey = 'api_base_url';

  static Future<String> load({required String fallback}) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored == null || stored.trim().isEmpty) {
      return normalize(fallback);
    }
    return normalize(stored);
  }

  static Future<String> save(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = normalize(value);
    await prefs.setString(_prefsKey, normalized);
    return normalized;
  }

  static String normalize(String value) {
    var normalized = value.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  static bool isValidHttpUrl(String value) {
    final normalized = normalize(value);
    if (normalized.isEmpty) {
      return false;
    }
    final uri = Uri.tryParse(normalized);
    if (uri == null) {
      return false;
    }
    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}
