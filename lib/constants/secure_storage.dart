import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();

  static const _keys = <String>{
    'userEmail', 'user_email', 'password', 'username', 'session',
    'cdsNumber', 'accountStatus', 'userNIDA', 'nida_number',
    'savedUsername', 'saved_email', 'saved_phone',
    'user_fullname', 'user_mobile', 'user_address',
    'user_names', 'first_name', 'middle_name', 'last_name',
    'broker_ref', 'broker_name', 'gender', 'nationality', 'dob',
    'physical_address', 'region', 'country',
    'cds_number', 'user_first_name', 'user_surname',
    'user_phone', 'user_bank', 'user_accountNo', 'user_accountName',
    'user_branch',
  };
  static const _migrationKey = '_migration_done';

  static final FlutterSecureStorage _secure = const FlutterSecureStorage();
  static bool _checkedMigration = false;

  /// Migrate legacy keys out of plaintext SharedPreferences into secure storage.
  /// Runs once per install. After migration, SharedPreferences values are deleted.
  static Future<void> _ensureMigrated() async {
    if (_checkedMigration) return;
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
          } catch (_) {}
        }
      }

      try {
        await _secure.write(key: _migrationKey, value: DateTime.now().toIso8601String());
      } catch (_) {}
    } catch (_) {
    } finally {
      _checkedMigration = true;
    }
  }

  static Future<String?> read(String key) async {
    if (!_keys.contains(key)) return null;
    await _ensureMigrated();
    try {
      return await _secure.read(key: key);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> write(String key, String value) async {
    if (!_keys.contains(key)) return false;
    await _ensureMigrated();
    try {
      await _secure.write(key: key, value: value);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> remove(String key) async {
    if (!_keys.contains(key)) return false;
    await _ensureMigrated();
    try {
      await _secure.delete(key: key);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> clear() async {
    await _ensureMigrated();
    for (final k in _keys) {
      try {
        await _secure.delete(key: k);
      } catch (_) {}
    }
  }
}
