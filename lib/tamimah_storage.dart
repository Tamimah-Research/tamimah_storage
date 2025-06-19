library tamimah_storage;

import 'package:tamimah_storage/src/cache_manager.dart';
import 'package:tamimah_storage/src/local_database.dart';
import 'package:tamimah_storage/src/offline_sync.dart';
import 'package:tamimah_storage/src/secure_storage.dart';

export 'src/secure_storage.dart';
export 'src/local_database.dart';
export 'src/cache_manager.dart';
export 'src/encryption_service.dart';
export 'src/storage_migration.dart';
export 'src/offline_sync.dart';
export 'src/models/storage_item.dart';
export 'src/models/cache_item.dart';
export 'src/models/sync_item.dart';

/// Main class for Tamimah Storage package
class TamimahStorage {
  static const String _version = '0.0.1';

  /// Get the current version of the package
  static String get version => _version;

  /// Initialize all storage services
  static Future<void> initialize({
    String? encryptionKey,
    String? databasePath,
    Duration? cacheExpiration,
  }) async {
    await SecureStorage.initialize(encryptionKey: encryptionKey);
    await LocalDatabase.initialize(databasePath: databasePath);
    await CacheManager.initialize(expiration: cacheExpiration);
    await OfflineSync.initialize();
  }

  /// Dispose all storage services
  static Future<void> dispose() async {
    await SecureStorage.dispose();
    await LocalDatabase.dispose();
    await CacheManager.dispose();
    await OfflineSync.dispose();
  }
}
