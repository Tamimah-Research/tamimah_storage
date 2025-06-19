import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'encryption_service.dart';

/// Secure storage service for sensitive data
class SecureStorage {
  static const String _prefix = 'secure_';
  static late SharedPreferences _prefs;
  static bool _initialized = false;

  /// Initialize secure storage
  static Future<void> initialize({String? encryptionKey}) async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    EncryptionService.initialize(encryptionKey: encryptionKey);
    _initialized = true;
  }

  /// Store a string value securely
  static Future<bool> setString(
    String key,
    String value, {
    bool encrypt = true,
  }) async {
    _ensureInitialized();

    final fullKey = _prefix + key;
    final valueToStore = encrypt
        ? EncryptionService.encryptString(value)
        : value;

    return await _prefs.setString(fullKey, valueToStore);
  }

  /// Get a string value securely
  static Future<String?> getString(String key, {bool decrypt = true}) async {
    _ensureInitialized();

    final fullKey = _prefix + key;
    final value = _prefs.getString(fullKey);

    if (value == null) return null;

    if (decrypt && EncryptionService.isEncrypted(value)) {
      try {
        return EncryptionService.decryptString(value);
      } catch (e) {
        return value; // Return as-is if decryption fails
      }
    }

    return value;
  }

  /// Store a boolean value securely
  static Future<bool> setBool(
    String key,
    bool value, {
    bool encrypt = true,
  }) async {
    return await setString(key, value.toString(), encrypt: encrypt);
  }

  /// Get a boolean value securely
  static Future<bool?> getBool(String key, {bool decrypt = true}) async {
    final value = await getString(key, decrypt: decrypt);
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  /// Store an integer value securely
  static Future<bool> setInt(
    String key,
    int value, {
    bool encrypt = true,
  }) async {
    return await setString(key, value.toString(), encrypt: encrypt);
  }

  /// Get an integer value securely
  static Future<int?> getInt(String key, {bool decrypt = true}) async {
    final value = await getString(key, decrypt: decrypt);
    if (value == null) return null;
    return int.tryParse(value);
  }

  /// Store a double value securely
  static Future<bool> setDouble(
    String key,
    double value, {
    bool encrypt = true,
  }) async {
    return await setString(key, value.toString(), encrypt: encrypt);
  }

  /// Get a double value securely
  static Future<double?> getDouble(String key, {bool decrypt = true}) async {
    final value = await getString(key, decrypt: decrypt);
    if (value == null) return null;
    return double.tryParse(value);
  }

  /// Store a map/object securely
  static Future<bool> setObject(
    String key,
    Map<String, dynamic> object, {
    bool encrypt = true,
  }) async {
    final jsonString = jsonEncode(object);
    return await setString(key, jsonString, encrypt: encrypt);
  }

  /// Get a map/object securely
  static Future<Map<String, dynamic>?> getObject(
    String key, {
    bool decrypt = true,
  }) async {
    final jsonString = await getString(key, decrypt: decrypt);
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Store a list securely
  static Future<bool> setList(
    String key,
    List<dynamic> list, {
    bool encrypt = true,
  }) async {
    final jsonString = jsonEncode(list);
    return await setString(key, jsonString, encrypt: encrypt);
  }

  /// Get a list securely
  static Future<List<dynamic>?> getList(
    String key, {
    bool decrypt = true,
  }) async {
    final jsonString = await getString(key, decrypt: decrypt);
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Check if a key exists
  static Future<bool> containsKey(String key) async {
    _ensureInitialized();
    final fullKey = _prefix + key;
    return _prefs.containsKey(fullKey);
  }

  /// Remove a key
  static Future<bool> remove(String key) async {
    _ensureInitialized();
    final fullKey = _prefix + key;
    return await _prefs.remove(fullKey);
  }

  /// Clear all secure storage
  static Future<bool> clear() async {
    _ensureInitialized();

    final keys = _prefs.getKeys().where((key) => key.startsWith(_prefix));
    bool success = true;

    for (final key in keys) {
      final removed = await _prefs.remove(key);
      if (!removed) success = false;
    }

    return success;
  }

  /// Get all secure keys
  static Future<List<String>> getKeys() async {
    _ensureInitialized();

    final keys = _prefs.getKeys().where((key) => key.startsWith(_prefix));
    return keys.map((key) => key.substring(_prefix.length)).toList();
  }

  /// Get storage info
  static Future<Map<String, dynamic>> getStorageInfo() async {
    _ensureInitialized();

    final keys = await getKeys();
    int totalSize = 0;

    for (final key in keys) {
      final value = await getString(key, decrypt: false);
      if (value != null) {
        totalSize += value.length;
      }
    }

    return {
      'totalKeys': keys.length,
      'totalSize': totalSize,
      'initialized': _initialized,
    };
  }

  /// Migrate data from regular SharedPreferences to secure storage
  static Future<bool> migrateFromSharedPreferences(List<String> keys) async {
    _ensureInitialized();

    bool success = true;
    for (final key in keys) {
      final value = _prefs.getString(key);
      if (value != null) {
        final migrated = await setString(key, value, encrypt: true);
        if (migrated) {
          await _prefs.remove(key); // Remove from regular storage
        } else {
          success = false;
        }
      }
    }

    return success;
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'SecureStorage must be initialized before use. Call SecureStorage.initialize() first.',
      );
    }
  }

  /// Dispose secure storage
  static Future<void> dispose() async {
    _initialized = false;
    EncryptionService.dispose();
  }
}
