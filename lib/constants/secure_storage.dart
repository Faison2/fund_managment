import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences that keeps the key names in one
/// place.  In a production app this would be replaced with
/// `flutter_secure_storage` (AES-encrypted at rest).
///
/// Adding flutter_secure_storage:
///   flutter pub add flutter_secure_storage
/// Then replace every `SharedPreferences.getInstance()` + `getString` /
/// `setString` call with `FlutterSecureStorage().read() / .write()`.
class SecureStorage {
  SecureStorage._();

  static const _keys = <String>{'userEmail', 'password', 'username', 'session'};

  /// Read a value. Returns `null` when key is absent.
  static Future<String?> read(String key) async {
    if (!_keys.contains(key)) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Persist a value.
  static Future<bool> write(String key, String value) async {
    if (!_keys.contains(key)) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  /// Remove a key.
  static Future<bool> remove(String key) async {
    if (!_keys.contains(key)) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(key);
  }

  /// Wipe all known keys (e.g. on logout).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in _keys) {
      await prefs.remove(k);
    }
  }
}
