import 'package:flutter_test/flutter_test.dart';

import 'package:tamimah_storage/tamimah_storage.dart';

void main() {
  group('TamimahStorage Tests', () {
    setUpAll(() async {
      // Initialize storage for tests
      await TamimahStorage.initialize(
        encryptionKey: 'test-encryption-key-32-chars-long',
        cacheExpiration: Duration(minutes: 5),
      );
    });

    tearDownAll(() async {
      // Clean up after tests
      await TamimahStorage.dispose();
    });

    group('SecureStorage Tests', () {
      test('should store and retrieve string securely', () async {
        const key = 'test_string';
        const value = 'test_value';

        // Store string
        final success = await SecureStorage.setString(key, value);
        expect(success, isTrue);

        // Retrieve string
        final retrieved = await SecureStorage.getString(key);
        expect(retrieved, equals(value));
      });

      test('should store and retrieve object securely', () async {
        const key = 'test_object';
        final object = {'name': 'John', 'age': 30};

        // Store object
        final success = await SecureStorage.setObject(key, object);
        expect(success, isTrue);

        // Retrieve object
        final retrieved = await SecureStorage.getObject(key);
        expect(retrieved, equals(object));
      });

      test('should store and retrieve list securely', () async {
        const key = 'test_list';
        final list = [1, 2, 3, 'test'];

        // Store list
        final success = await SecureStorage.setList(key, list);
        expect(success, isTrue);

        // Retrieve list
        final retrieved = await SecureStorage.getList(key);
        expect(retrieved, equals(list));
      });

      test('should check if key exists', () async {
        const key = 'test_exists';
        const value = 'test_value';

        // Store value
        await SecureStorage.setString(key, value);

        // Check if exists
        final exists = await SecureStorage.containsKey(key);
        expect(exists, isTrue);

        // Check non-existent key
        final notExists = await SecureStorage.containsKey('non_existent');
        expect(notExists, isFalse);
      });

      test('should remove key', () async {
        const key = 'test_remove';
        const value = 'test_value';

        // Store value
        await SecureStorage.setString(key, value);

        // Verify it exists
        final exists = await SecureStorage.containsKey(key);
        expect(exists, isTrue);

        // Remove key
        final removed = await SecureStorage.remove(key);
        expect(removed, isTrue);

        // Verify it's gone
        final stillExists = await SecureStorage.containsKey(key);
        expect(stillExists, isFalse);
      });
    });

    group('LocalDatabase Tests', () {
      test('should store and retrieve data', () async {
        const key = 'test_db_key';
        final data = {'name': 'Jane', 'email': 'jane@example.com'};

        // Store data
        await LocalDatabase.set(key, data);

        // Retrieve data
        final retrieved = await LocalDatabase.get(key);
        expect(retrieved, equals(data));
      });

      test('should store and retrieve encrypted data', () async {
        const key = 'test_encrypted_key';
        final data = {'password': 'secret123', 'token': 'jwt_token'};

        // Store encrypted data
        await LocalDatabase.set(key, data, encrypt: true);

        // Retrieve encrypted data
        final retrieved = await LocalDatabase.get(key, decrypt: true);
        expect(retrieved, equals(data));
      });

      test('should check if key exists', () async {
        const key = 'test_db_exists';
        final data = {'test': 'data'};

        // Store data
        await LocalDatabase.set(key, data);

        // Check if exists
        final exists = await LocalDatabase.containsKey(key);
        expect(exists, isTrue);

        // Check non-existent key
        final notExists = await LocalDatabase.containsKey('non_existent');
        expect(notExists, isFalse);
      });

      test('should remove key', () async {
        const key = 'test_db_remove';
        final data = {'test': 'data'};

        // Store data
        await LocalDatabase.set(key, data);

        // Verify it exists
        final exists = await LocalDatabase.containsKey(key);
        expect(exists, isTrue);

        // Remove key
        await LocalDatabase.remove(key);

        // Verify it's gone
        final stillExists = await LocalDatabase.containsKey(key);
        expect(stillExists, isFalse);
      });

      test('should get all keys', () async {
        // Clear database first
        await LocalDatabase.clear();

        // Add some test data
        await LocalDatabase.set('key1', 'value1');
        await LocalDatabase.set('key2', 'value2');
        await LocalDatabase.set('key3', 'value3');

        // Get all keys
        final keys = await LocalDatabase.getKeys();
        expect(keys, containsAll(['key1', 'key2', 'key3']));
      });
    });

    group('CacheManager Tests', () {
      test('should store and retrieve cache item', () async {
        const key = 'test_cache_key';
        final data = {'cached': 'data'};

        // Store cache item
        await CacheManager.set(key, data);

        // Retrieve cache item
        final retrieved = await CacheManager.get(key);
        expect(retrieved, equals(data));
      });

      test('should store cache item with expiration', () async {
        const key = 'test_cache_expiration';
        final data = {'expires': 'soon'};

        // Store with short expiration
        await CacheManager.set(key, data, expiration: Duration(seconds: 1));

        // Should be available immediately
        final retrieved = await CacheManager.get(key);
        expect(retrieved, equals(data));

        // Wait for expiration
        await Future.delayed(Duration(seconds: 2));

        // Should be expired
        final expired = await CacheManager.get(key);
        expect(expired, isNull);
      });

      test('should store cache item with tag', () async {
        const key = 'test_cache_tag';
        final data = {'tagged': 'data'};

        // Store with tag
        await CacheManager.set(key, data, tag: 'test_tag');

        // Get items by tag
        final taggedItems = await CacheManager.getItemsByTag('test_tag');
        expect(taggedItems.length, equals(1));
        expect(taggedItems.first.data, equals(data));
      });

      test('should clear cache by tag', () async {
        // Add items with different tags
        await CacheManager.set('key1', 'data1', tag: 'tag1');
        await CacheManager.set('key2', 'data2', tag: 'tag1');
        await CacheManager.set('key3', 'data3', tag: 'tag2');

        // Clear by tag1
        await CacheManager.clearByTag('tag1');

        // Check remaining items
        final tag1Items = await CacheManager.getItemsByTag('tag1');
        final tag2Items = await CacheManager.getItemsByTag('tag2');

        expect(tag1Items.length, equals(0));
        expect(tag2Items.length, equals(1));
      });

      test('should check if cache key exists', () async {
        const key = 'test_cache_exists';
        final data = {'test': 'data'};

        // Store cache item
        await CacheManager.set(key, data);

        // Check if exists
        final exists = await CacheManager.containsKey(key);
        expect(exists, isTrue);

        // Check non-existent key
        final notExists = await CacheManager.containsKey('non_existent');
        expect(notExists, isFalse);
      });
    });

    group('EncryptionService Tests', () {
      test('should encrypt and decrypt string', () {
        const original = 'test_string_to_encrypt';

        // Encrypt
        final encrypted = EncryptionService.encryptString(original);
        expect(encrypted, isNot(equals(original)));

        // Decrypt
        final decrypted = EncryptionService.decryptString(encrypted);
        expect(decrypted, equals(original));
      });

      test('should encrypt and decrypt object', () {
        final original = {'name': 'John', 'age': 30};

        // Encrypt
        final encrypted = EncryptionService.encryptObject(original);
        expect(encrypted, isNot(equals(original.toString())));

        // Decrypt
        final decrypted = EncryptionService.decryptObject(encrypted);
        expect(decrypted, equals(original));
      });

      test('should encrypt and decrypt list', () {
        final original = [
          1,
          2,
          3,
          'test',
          {'nested': 'data'},
        ];

        // Encrypt
        final encrypted = EncryptionService.encryptList(original);
        expect(encrypted, isNot(equals(original.toString())));

        // Decrypt
        final decrypted = EncryptionService.decryptList(encrypted);
        expect(decrypted, equals(original));
      });

      test('should generate random key', () {
        final key1 = EncryptionService.generateRandomKey();
        final key2 = EncryptionService.generateRandomKey();

        expect(key1, isNot(equals(key2)));
        expect(key1.length, equals(32));
        expect(key2.length, equals(32));
      });

      test('should hash string', () {
        const input = 'test_string';
        final hash1 = EncryptionService.hashString(input);
        final hash2 = EncryptionService.hashString(input);

        expect(hash1, equals(hash2));
        expect(hash1, isNot(equals(input)));
      });

      test('should verify hash', () {
        const input = 'test_string';
        final hash = EncryptionService.hashString(input);

        final isValid = EncryptionService.verifyHash(input, hash);
        final isInvalid = EncryptionService.verifyHash('wrong_input', hash);

        expect(isValid, isTrue);
        expect(isInvalid, isFalse);
      });
    });

    group('StorageMigration Tests', () {
      test('should get migration status', () async {
        final status = await StorageMigration.getMigrationStatus();

        expect(status, contains('currentVersion'));
        expect(status, contains('targetVersion'));
        expect(status, contains('migrationHistory'));
        expect(status, contains('needsMigration'));
        expect(status, contains('pendingMigrations'));
      });

      test('should backup and restore data', () async {
        // Add some test data
        await SecureStorage.setString('test_backup', 'test_value');
        await LocalDatabase.set('test_backup_db', {'test': 'data'});

        // Create backup
        final backup = await StorageMigration.backupData();
        expect(backup, isNotEmpty);

        // Clear data
        await SecureStorage.clear();
        await LocalDatabase.clear();

        // Restore data
        await StorageMigration.restoreData(backup);

        // Verify data is restored
        final restoredValue = await SecureStorage.getString('test_backup');
        expect(restoredValue, equals('test_value'));

        final restoredDbValue = await LocalDatabase.get('test_backup_db');
        expect(restoredDbValue, equals({'test': 'data'}));
      });
    });

    group('OfflineSync Tests', () {
      test('should add sync item', () async {
        final syncId = await OfflineSync.addSyncItem(
          endpoint: '/api/test',
          operation: SyncOperation.create,
          data: {'test': 'data'},
        );

        expect(syncId, isNotEmpty);

        // Get sync item
        final syncItem = await OfflineSync.getSyncItem(syncId);
        expect(syncItem, isNotNull);
        expect(syncItem!.endpoint, equals('/api/test'));
        expect(syncItem.operation, equals(SyncOperation.create));
        expect(syncItem.data, equals({'test': 'data'}));
      });

      test('should get pending sync items', () async {
        // Add multiple sync items
        await OfflineSync.addSyncItem(
          endpoint: '/api/test1',
          operation: SyncOperation.create,
          data: {'test1': 'data1'},
        );

        await OfflineSync.addSyncItem(
          endpoint: '/api/test2',
          operation: SyncOperation.update,
          data: {'test2': 'data2'},
        );

        // Get pending items
        final pendingItems = await OfflineSync.getPendingSyncItems();
        expect(pendingItems.length, greaterThanOrEqualTo(2));
      });

      test('should get sync statistics', () async {
        final stats = await OfflineSync.getSyncStats();

        expect(stats, contains('totalItems'));
        expect(stats, contains('pendingItems'));
        expect(stats, contains('inProgressItems'));
        expect(stats, contains('completedItems'));
        expect(stats, contains('failedItems'));
        expect(stats, contains('retryableItems'));
        expect(stats, contains('isOnline'));
        expect(stats, contains('initialized'));
      });

      test('should check online status', () {
        final isOnline = OfflineSync.isOnline;
        expect(isOnline, isA<bool>());
      });
    });

    group('Integration Tests', () {
      test('should work with all services together', () async {
        const userId = 'user_123';
        final userData = {
          'name': 'John Doe',
          'email': 'john@example.com',
          'preferences': {'theme': 'dark', 'notifications': true},
        };

        // Store in secure storage (sensitive data)
        await SecureStorage.setString('auth_token_$userId', 'jwt_token_123');
        await SecureStorage.setObject(
          'user_preferences_$userId',
          userData['preferences'] as Map<String, dynamic>,
        );

        // Store in database (structured data)
        await LocalDatabase.set('user_$userId', userData, type: 'User');

        // Cache API response
        await CacheManager.set('api_user_$userId', userData, tag: 'users');

        // Add sync item for offline sync
        await OfflineSync.addSyncItem(
          endpoint: '/api/users/$userId',
          operation: SyncOperation.update,
          data: userData,
        );

        // Verify all data is stored correctly
        final token = await SecureStorage.getString('auth_token_$userId');
        expect(token, equals('jwt_token_123'));

        final preferences = await SecureStorage.getObject(
          'user_preferences_$userId',
        );
        expect(preferences, equals(userData['preferences']));

        final dbUser = await LocalDatabase.get('user_$userId');
        expect(dbUser, equals(userData));

        final cachedUser = await CacheManager.get('api_user_$userId');
        expect(cachedUser, equals(userData));

        final pendingSync = await OfflineSync.getPendingSyncItems();
        expect(pendingSync.length, greaterThan(0));
      });
    });
  });
}
