import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'secure_storage.dart';
import 'local_database.dart';
import 'cache_manager.dart';
import 'models/cache_item.dart';

/// Storage migration service for handling data migration
class StorageMigration {
  static const String _versionKey = 'storage_version';
  static const String _migrationHistoryKey = 'migration_history';
  static const int _currentVersion = 1;

  /// Initialize migration service
  static Future<void> initialize() async {
    // Check if migration is needed
    await _checkAndMigrate();
  }

  /// Check if migration is needed and perform it
  static Future<void> _checkAndMigrate() async {
    final currentVersion = await _getCurrentVersion();

    if (currentVersion < _currentVersion) {
      await _performMigration(currentVersion, _currentVersion);
    }
  }

  /// Get current storage version
  static Future<int> _getCurrentVersion() async {
    try {
      final version = await SecureStorage.getInt(_versionKey, decrypt: false);
      return version ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Set current storage version
  static Future<void> _setCurrentVersion(int version) async {
    await SecureStorage.setInt(_versionKey, version, encrypt: false);
  }

  /// Perform migration from one version to another
  static Future<void> _performMigration(int fromVersion, int toVersion) async {
    log('Starting migration from version $fromVersion to $toVersion');

    final history = await _getMigrationHistory();

    for (int version = fromVersion + 1; version <= toVersion; version++) {
      if (!history.contains(version)) {
        await _migrateToVersion(version);
        history.add(version);
        await _setMigrationHistory(history);
      }
    }

    await _setCurrentVersion(toVersion);
    log('Migration completed successfully');
  }

  /// Migrate to a specific version
  static Future<void> _migrateToVersion(int version) async {
    switch (version) {
      case 1:
        await _migrateToVersion1();
        break;
      // Add more migration cases as needed
      default:
        throw Exception('Unknown migration version: $version');
    }
  }

  /// Migration to version 1
  static Future<void> _migrateToVersion1() async {
    log('Migrating to version 1...');

    // Example migration: Convert old format to new format
    // This is just an example - adjust based on your needs

    try {
      // Migrate old SharedPreferences data to secure storage
      final oldKeys = await _getOldSharedPreferencesKeys();
      if (oldKeys.isNotEmpty) {
        await SecureStorage.migrateFromSharedPreferences(oldKeys);
      }

      // Migrate old database format
      await _migrateOldDatabaseFormat();

      // Migrate old cache format
      await _migrateOldCacheFormat();
    } catch (e) {
      log('Error during migration to version 1: $e');
      rethrow;
    }
  }

  /// Get old SharedPreferences keys that need migration
  static Future<List<String>> _getOldSharedPreferencesKeys() async {
    // This would depend on your specific implementation
    // For now, return an empty list
    return [];
  }

  /// Migrate old database format
  static Future<void> _migrateOldDatabaseFormat() async {
    // Example: Convert old database format to new format
    // This would depend on your specific database structure

    try {
      // Export old data
      final oldData = await _exportOldDatabaseData();

      // Clear old data
      await _clearOldDatabaseData();

      // Import with new format
      await _importNewDatabaseData(oldData);
    } catch (e) {
      log('Error migrating database format: $e');
      rethrow;
    }
  }

  /// Migrate old cache format
  static Future<void> _migrateOldCacheFormat() async {
    // Example: Convert old cache format to new format
    // This would depend on your specific cache structure

    try {
      // Export old cache data
      final oldCacheData = await _exportOldCacheData();

      // Clear old cache
      await _clearOldCacheData();

      // Import with new format
      await _importNewCacheData(oldCacheData);
    } catch (e) {
      log('Error migrating cache format: $e');
      rethrow;
    }
  }

  /// Export old database data
  static Future<Map<String, dynamic>> _exportOldDatabaseData() async {
    // This would export data from the old database format
    // For now, return empty map
    return {};
  }

  /// Clear old database data
  static Future<void> _clearOldDatabaseData() async {
    // This would clear the old database
    // Implementation depends on your specific database
  }

  /// Import new database data
  static Future<void> _importNewDatabaseData(Map<String, dynamic> data) async {
    // This would import data to the new database format
    // Implementation depends on your specific database
  }

  /// Export old cache data
  static Future<Map<String, dynamic>> _exportOldCacheData() async {
    // This would export data from the old cache format
    // For now, return empty map
    return {};
  }

  /// Clear old cache data
  static Future<void> _clearOldCacheData() async {
    // This would clear the old cache
    // Implementation depends on your specific cache
  }

  /// Import new cache data
  static Future<void> _importNewCacheData(Map<String, dynamic> data) async {
    // This would import data to the new cache format
    // Implementation depends on your specific cache
  }

  /// Get migration history
  static Future<List<int>> _getMigrationHistory() async {
    try {
      final history = await SecureStorage.getList(
        _migrationHistoryKey,
        decrypt: false,
      );
      return history?.cast<int>() ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Set migration history
  static Future<void> _setMigrationHistory(List<int> history) async {
    await SecureStorage.setList(_migrationHistoryKey, history, encrypt: false);
  }

  /// Force migration to a specific version
  static Future<void> forceMigration(int targetVersion) async {
    final currentVersion = await _getCurrentVersion();
    await _performMigration(currentVersion, targetVersion);
  }

  /// Reset migration history
  static Future<void> resetMigrationHistory() async {
    await SecureStorage.remove(_migrationHistoryKey);
    await SecureStorage.remove(_versionKey);
  }

  /// Get migration status
  static Future<Map<String, dynamic>> getMigrationStatus() async {
    final currentVersion = await _getCurrentVersion();
    final history = await _getMigrationHistory();

    return {
      'currentVersion': currentVersion,
      'targetVersion': _currentVersion,
      'migrationHistory': history,
      'needsMigration': currentVersion < _currentVersion,
      'pendingMigrations': _currentVersion - currentVersion,
    };
  }

  /// Backup data before migration
  static Future<Map<String, dynamic>> backupData() async {
    final backup = <String, dynamic>{};

    try {
      // Backup secure storage
      final secureKeys = await SecureStorage.getKeys();
      for (final key in secureKeys) {
        final value = await SecureStorage.getString(key, decrypt: false);
        backup['secure_$key'] = value;
      }

      // Backup database
      final dbData = await LocalDatabase.exportToJson(decrypt: false);
      backup['database'] = dbData;

      // Backup cache
      final cacheItems = await CacheManager.getAllItems();
      backup['cache'] = cacheItems.map((item) => item.toJson()).toList();
    } catch (e) {
      log('Error creating backup: $e');
    }

    return backup;
  }

  /// Restore data from backup
  static Future<void> restoreData(Map<String, dynamic> backup) async {
    try {
      // Restore secure storage
      for (final entry in backup.entries) {
        if (entry.key.startsWith('secure_')) {
          final key = entry.key.substring(7);
          final value = entry.value as String;
          await SecureStorage.setString(key, value, encrypt: false);
        }
      }

      // Restore database
      if (backup.containsKey('database')) {
        final dbData = backup['database'] as Map<String, dynamic>;
        await LocalDatabase.importFromJson(dbData);
      }

      // Restore cache
      if (backup.containsKey('cache')) {
        final cacheData = backup['cache'] as List<dynamic>;
        for (final itemData in cacheData) {
          final item = CacheItem.fromJson(itemData as Map<String, dynamic>);
          // Note: This would require a method to add items to cache
          // Implementation depends on your cache structure
        }
      }
    } catch (e) {
      log('Error restoring backup: $e');
      rethrow;
    }
  }

  /// Export migration data to file
  static Future<String> exportMigrationData() async {
    final backup = await backupData();
    final jsonString = jsonEncode(backup);

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/tamimah_storage_backup.json');
    await file.writeAsString(jsonString);

    return file.path;
  }

  /// Import migration data from file
  static Future<void> importMigrationData(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Backup file not found: $filePath');
    }

    final jsonString = await file.readAsString();
    final backup = jsonDecode(jsonString) as Map<String, dynamic>;

    await restoreData(backup);
  }
}
