import 'package:shared_preferences/shared_preferences.dart';

/// Fuente de datos local (clave-valor). Aísla a los repositorios del plugin.
class LocalStorage {
  Future<String?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> write(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}
