import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage(this._preferences);

  final SharedPreferences _preferences;

  String? getString(String key) => _preferences.getString(key);
  Future<bool> setString(String key, String value) => _preferences.setString(key, value);
  bool? getBool(String key) => _preferences.getBool(key);
  Future<bool> setBool(String key, bool value) => _preferences.setBool(key, value);
  Future<bool> remove(String key) => _preferences.remove(key);
}
