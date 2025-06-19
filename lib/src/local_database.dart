import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'models/storage_item.dart';
import 'encryption_service.dart';

/// Local database service using Hive
class LocalDatabase {
  static const String _boxName = 'tamimah_storage';
  static const String _encryptedBoxName = 'tamimah_encrypted_storage';
  static late Box<StorageItem> _box;
  static late Box<StorageItem> _encryptedBox;
  static bool _initialized = false;

  /// Initialize local database
  static Future<void> initialize({String? databasePath}) async {
    if (_initialized) return;

    // Initialize Hive
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(StorageItemAdapter());
    }

    // Set up database path
    if (databasePath != null) {
      Hive.init(databasePath);
    } else {
      await Hive.initFlutter();
    }

    // Initialize encryption service
    EncryptionService.initialize();

    // Open boxes
    _box = await Hive.openBox<StorageItem>(_boxName);
    _encryptedBox = await Hive.openBox<StorageItem>(_encryptedBoxName);

    _initialized = true;
  }

  /// Store a value in the database
  static Future<void> set(
    String key,
    dynamic value, {
    String? type,
    bool encrypt = false,
    Map<String, dynamic>? metadata,
  }) async {
    _ensureInitialized();

    final item = StorageItem(
      key: key,
      value: value,
      type: type ?? value.runtimeType.toString(),
      isEncrypted: encrypt,
      metadata: metadata,
    );

    final targetBox = encrypt ? _encryptedBox : _box;
    await targetBox.put(key, item);
  }

  /// Get a value from the database
  static Future<dynamic> get(String key, {bool decrypt = true}) async {
    _ensureInitialized();

    // Try regular box first
    StorageItem? item = _box.get(key);

    // If not found, try encrypted box
    if (item == null) {
      item = _encryptedBox.get(key);
    }

    if (item == null) return null;

    if (item.isEncrypted && decrypt) {
      try {
        if (item.value is String) {
          return EncryptionService.decryptString(item.value);
        } else if (item.value is Map) {
          return EncryptionService.decryptObject(item.value.toString());
        }
      } catch (e) {
        return item.value; // Return as-is if decryption fails
      }
    }

    return item.value;
  }

  /// Get a storage item with metadata
  static Future<StorageItem?> getItem(String key) async {
    _ensureInitialized();

    StorageItem? item = _box.get(key);
    if (item == null) {
      item = _encryptedBox.get(key);
    }

    return item;
  }

  /// Check if a key exists
  static Future<bool> containsKey(String key) async {
    _ensureInitialized();
    return _box.containsKey(key) || _encryptedBox.containsKey(key);
  }

  /// Remove a key
  static Future<void> remove(String key) async {
    _ensureInitialized();
    await _box.delete(key);
    await _encryptedBox.delete(key);
  }

  /// Clear all data
  static Future<void> clear() async {
    _ensureInitialized();
    await _box.clear();
    await _encryptedBox.clear();
  }

  /// Get all keys
  static Future<List<String>> getKeys() async {
    _ensureInitialized();
    final regularKeys = _box.keys.cast<String>();
    final encryptedKeys = _encryptedBox.keys.cast<String>();
    return [...regularKeys, ...encryptedKeys];
  }

  /// Get all values
  static Future<List<dynamic>> getValues({bool decrypt = true}) async {
    _ensureInitialized();
    final items = <dynamic>[];

    for (final item in _box.values) {
      items.add(
        decrypt && item.isEncrypted
            ? await _decryptValue(item.value)
            : item.value,
      );
    }

    for (final item in _encryptedBox.values) {
      items.add(
        decrypt && item.isEncrypted
            ? await _decryptValue(item.value)
            : item.value,
      );
    }

    return items;
  }

  /// Get all items with metadata
  static Future<List<StorageItem>> getAllItems() async {
    _ensureInitialized();
    final items = <StorageItem>[];
    items.addAll(_box.values);
    items.addAll(_encryptedBox.values);
    return items;
  }

  /// Query items by type
  static Future<List<StorageItem>> getItemsByType(String type) async {
    _ensureInitialized();
    final items = <StorageItem>[];

    for (final item in _box.values) {
      if (item.type == type) items.add(item);
    }

    for (final item in _encryptedBox.values) {
      if (item.type == type) items.add(item);
    }

    return items;
  }

  /// Query items by metadata
  static Future<List<StorageItem>> getItemsByMetadata(
    String key,
    dynamic value,
  ) async {
    _ensureInitialized();
    final items = <StorageItem>[];

    for (final item in _box.values) {
      if (item.metadata?[key] == value) items.add(item);
    }

    for (final item in _encryptedBox.values) {
      if (item.metadata?[key] == value) items.add(item);
    }

    return items;
  }

  /// Get database statistics
  static Future<Map<String, dynamic>> getStats() async {
    _ensureInitialized();

    final regularCount = _box.length;
    final encryptedCount = _encryptedBox.length;
    final totalCount = regularCount + encryptedCount;

    int totalSize = 0;
    for (final item in _box.values) {
      totalSize += item.value.toString().length;
    }
    for (final item in _encryptedBox.values) {
      totalSize += item.value.toString().length;
    }

    return {
      'totalItems': totalCount,
      'regularItems': regularCount,
      'encryptedItems': encryptedCount,
      'totalSize': totalSize,
      'initialized': _initialized,
    };
  }

  /// Export database to JSON
  static Future<Map<String, dynamic>> exportToJson({
    bool decrypt = true,
  }) async {
    _ensureInitialized();

    final data = <String, dynamic>{};

    for (final item in _box.values) {
      data[item.key] = {
        'value': decrypt && item.isEncrypted
            ? await _decryptValue(item.value)
            : item.value,
        'type': item.type,
        'createdAt': item.createdAt.toIso8601String(),
        'updatedAt': item.updatedAt?.toIso8601String(),
        'isEncrypted': item.isEncrypted,
        'metadata': item.metadata,
      };
    }

    for (final item in _encryptedBox.values) {
      data[item.key] = {
        'value': decrypt && item.isEncrypted
            ? await _decryptValue(item.value)
            : item.value,
        'type': item.type,
        'createdAt': item.createdAt.toIso8601String(),
        'updatedAt': item.updatedAt?.toIso8601String(),
        'isEncrypted': item.isEncrypted,
        'metadata': item.metadata,
      };
    }

    return data;
  }

  /// Import data from JSON
  static Future<void> importFromJson(Map<String, dynamic> data) async {
    _ensureInitialized();

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value as Map<String, dynamic>;

      final item = StorageItem(
        key: key,
        value: value['value'],
        type: value['type'],
        createdAt: DateTime.parse(value['createdAt']),
        updatedAt: value['updatedAt'] != null
            ? DateTime.parse(value['updatedAt'])
            : null,
        isEncrypted: value['isEncrypted'] ?? false,
        metadata: value['metadata'],
      );

      final targetBox = item.isEncrypted ? _encryptedBox : _box;
      await targetBox.put(key, item);
    }
  }

  /// Compact the database
  static Future<void> compact() async {
    _ensureInitialized();
    await _box.compact();
    await _encryptedBox.compact();
  }

  /// Get database path
  static Future<String> getDatabasePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/hive';
  }

  static Future<dynamic> _decryptValue(dynamic value) async {
    try {
      if (value is String) {
        return EncryptionService.decryptString(value);
      } else if (value is Map) {
        return EncryptionService.decryptObject(value.toString());
      }
    } catch (e) {
      return value; // Return as-is if decryption fails
    }
    return value;
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'LocalDatabase must be initialized before use. Call LocalDatabase.initialize() first.',
      );
    }
  }

  /// Dispose local database
  static Future<void> dispose() async {
    if (_initialized) {
      await _box.close();
      await _encryptedBox.close();
      _initialized = false;
    }
  }
}
