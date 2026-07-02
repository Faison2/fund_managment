import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// SecureStorage centralizes access to secrets. It replaces plain
/// SharedPreferences usage for sensitive keys with `flutter_secure_storage`.
///
/// Behavior:
///  - On first use it will migrate any existing values from
///    SharedPreferences into FlutterSecureStorage and remove the plain values.
///  - After migration all reads/writes go to secure storage.
class SecureStorage {
  SecureStorage._();

  // Include common variants so migration/reads work regardless of underscore/camelCase
  static const _keys = <String>{'userEmail', 'user_email', 'password', 'username', 'session'};
  static const _migrationKey = '_migration_done';

  static final FlutterSecureStorage _secure = const FlutterSecureStorage();
  static bool _checkedMigration = false;

  static Future<void> _ensureMigrated() async {
    if (_checkedMigration) return;
    // If a migration marker exists in secure storage we assume migration ran.
    try {
      final marker = await _secure.read(key: _migrationKey);
      if (marker != null) {
        _checkedMigration = true;
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      for (final k in _keys) {
        final v = prefs.getString(k);
        if (v != null) {
          try {
            await _secure.write(key: k, value: v);
            await prefs.remove(k);
          } catch (e) {
            // If secure storage fails for some reason, keep plain value and continue.
            // Log and skip deleting the plain preference.
            // ignore: avoid_print
            print('SecureStorage migration failed for key $k: $e');
          }
        }
      }

      // Persist migration marker so future app launches skip migration.
      try {
        await _secure.write(key: _migrationKey, value: DateTime.now().toIso8601String());
      } catch (e) {
        // ignore: avoid_print
        print('Failed to write migration marker: $e');
      }
    } catch (e) {
      // If anything at top-level fails (e.g., plugin unsupported on platform),
      // log and continue without throwing so app can proceed using SharedPreferences
      // as a fallback.
      // ignore: avoid_print
      print('SecureStorage migration aborted: $e');
    } finally {
      _checkedMigration = true;
    }
  }

  /// Read a value. Returns `null` when key is absent.
  static Future<String?> read(String key) async {
    if (!_keys.contains(key)) return null;
    await _ensureMigrated();
    try {
      return await _secure.read(key: key);
    } catch (e) {
      // Fallback to SharedPreferences if secure storage unavailable.
      // ignore: avoid_print
      print('SecureStorage.read failed for $key: $e');
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
  }

  /// Persist a value.
  static Future<bool> write(String key, String value) async {
    if (!_keys.contains(key)) return false;
    await _ensureMigrated();
    try {
      await _secure.write(key: key, value: value);
      return true;
    } catch (e) {
      // Fallback to SharedPreferences on error.
      // ignore: avoid_print
      print('SecureStorage.write failed for $key: $e');
      final prefs = await SharedPreferences.getInstance();
      return prefs.setString(key, value);
    }
  }

  /// Remove a key.
  static Future<bool> remove(String key) async {
    if (!_keys.contains(key)) return false;
    await _ensureMigrated();
    try {
      await _secure.delete(key: key);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('SecureStorage.remove failed for $key: $e');
      final prefs = await SharedPreferences.getInstance();
      return prefs.remove(key);
    }
  }

  /// Wipe all known keys (e.g. on logout).
  static Future<void> clear() async {
    await _ensureMigrated();
    for (final k in _keys) {
      await _secure.delete(key: k);
    }
    // Keep migration marker so we don't attempt migration again.
  }
}
