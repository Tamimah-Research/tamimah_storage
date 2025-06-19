<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# Tamimah Storage

A comprehensive Flutter local storage package with secure storage, database management, cache, encryption, and offline sync capabilities.

## Features

- 🔐 **Secure Storage**: Encrypted storage for sensitive data using AES-256
- 🗄️ **Local Database**: Hive-based database with encryption support
- ⚡ **Cache Management**: Intelligent caching with expiration and tagging
- 🔒 **Data Encryption**: AES-256 encryption/decryption for all data types
- 🔄 **Storage Migration**: Automatic data migration between versions
- 📡 **Offline Sync**: Queue-based synchronization when connectivity is restored

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  tamimah_storage: ^0.0.1
```

## Quick Start

### 1. Initialize the package

```dart
import 'package:tamimah_storage/tamimah_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize all storage services
  await TamimahStorage.initialize(
    encryptionKey: 'your-secure-encryption-key',
    databasePath: '/path/to/database', // Optional
    cacheExpiration: Duration(hours: 2), // Optional
  );
  
  runApp(MyApp());
}
```

### 2. Use secure storage for sensitive data

```dart
// Store sensitive data
await SecureStorage.setString('auth_token', 'your-jwt-token');
await SecureStorage.setObject('user_profile', {
  'id': 123,
  'email': 'user@example.com',
  'preferences': {'theme': 'dark'}
});

// Retrieve data
final token = await SecureStorage.getString('auth_token');
final profile = await SecureStorage.getObject('user_profile');
```

### 3. Use local database for structured data

```dart
// Store data in database
await LocalDatabase.set('user_123', {
  'name': 'John Doe',
  'email': 'john@example.com',
  'created_at': DateTime.now().toIso8601String()
}, encrypt: true);

// Query data
final userData = await LocalDatabase.get('user_123');
final users = await LocalDatabase.getItemsByType('User');
```

### 4. Use cache for performance optimization

```dart
// Cache API responses
await CacheManager.set('api_users', userList, 
  expiration: Duration(minutes: 30),
  tag: 'users'
);

// Get cached data
final cachedUsers = await CacheManager.get('api_users');

// Clear cache by tag
await CacheManager.clearByTag('users');
```

### 5. Use offline sync for data synchronization

```dart
// Add sync item when offline
final syncId = await OfflineSync.addSyncItem(
  endpoint: '/api/users',
  operation: SyncOperation.create,
  data: {'name': 'New User', 'email': 'new@example.com'}
);

// Check sync status
final stats = await OfflineSync.getSyncStats();
print('Pending items: ${stats['pendingItems']}');
```

## API Reference

### TamimahStorage

Main class for initializing and managing all storage services.

#### Methods

- `initialize({String? encryptionKey, String? databasePath, Duration? cacheExpiration})`: Initialize all storage services
- `dispose()`: Dispose all storage services
- `version`: Get the current package version

### SecureStorage

Secure storage service for sensitive data with encryption.

#### Methods

- `setString(String key, String value, {bool encrypt = true})`: Store a string securely
- `getString(String key, {bool decrypt = true})`: Get a string securely
- `setObject(String key, Map<String, dynamic> object, {bool encrypt = true})`: Store an object securely
- `getObject(String key, {bool decrypt = true})`: Get an object securely
- `setList(String key, List<dynamic> list, {bool encrypt = true})`: Store a list securely
- `getList(String key, {bool decrypt = true})`: Get a list securely
- `remove(String key)`: Remove a key
- `clear()`: Clear all secure storage
- `getKeys()`: Get all secure keys
- `getStorageInfo()`: Get storage statistics

### LocalDatabase

Hive-based local database with encryption support.

#### Methods

- `set(String key, dynamic value, {String? type, bool encrypt = false, Map<String, dynamic>? metadata})`: Store data in database
- `get(String key, {bool decrypt = true})`: Get data from database
- `getItem(String key)`: Get storage item with metadata
- `getItemsByType(String type)`: Query items by type
- `getItemsByMetadata(String key, dynamic value)`: Query items by metadata
- `remove(String key)`: Remove a key
- `clear()`: Clear all data
- `getKeys()`: Get all keys
- `getStats()`: Get database statistics
- `exportToJson({bool decrypt = true})`: Export database to JSON
- `importFromJson(Map<String, dynamic> data)`: Import data from JSON

### CacheManager

Intelligent cache management with expiration and tagging.

#### Methods

- `set(String key, dynamic data, {Duration? expiration, String? tag, Map<String, dynamic>? metadata})`: Set cache item
- `get(String key)`: Get cache item
- `getItem(String key)`: Get cache item with metadata
- `containsKey(String key)`: Check if key exists and is not expired
- `remove(String key)`: Remove cache item
- `clear()`: Clear all cache
- `clearByTag(String tag)`: Clear cache by tag
- `getItemsByTag(String tag)`: Get cache items by tag
- `refresh(String key, {Duration? newExpiration})`: Refresh cache item
- `getExpiringSoon(Duration threshold)`: Get items expiring soon
- `getStats()`: Get cache statistics

### EncryptionService

AES-256 encryption service for data security.

#### Methods

- `encryptString(String value)`: Encrypt a string
- `decryptString(String encryptedValue)`: Decrypt a string
- `encryptObject(Map<String, dynamic> object)`: Encrypt an object
- `decryptObject(String encryptedValue)`: Decrypt an object
- `encryptList(List<dynamic> list)`: Encrypt a list
- `decryptList(String encryptedValue)`: Decrypt a list
- `generateRandomKey({int length = 32})`: Generate random encryption key
- `hashString(String value)`: Hash a string using SHA-256
- `verifyHash(String value, String hash)`: Verify hash
- `isEncrypted(String value)`: Check if string is encrypted

### StorageMigration

Data migration service for handling version updates.

#### Methods

- `initialize()`: Initialize migration service
- `forceMigration(int targetVersion)`: Force migration to specific version
- `getMigrationStatus()`: Get migration status
- `backupData()`: Backup data before migration
- `restoreData(Map<String, dynamic> backup)`: Restore data from backup
- `exportMigrationData()`: Export migration data to file
- `importMigrationData(String filePath)`: Import migration data from file

### OfflineSync

Offline synchronization service for data sync when connectivity is restored.

#### Methods

- `addSyncItem({required String endpoint, required SyncOperation operation, required Map<String, dynamic> data, Map<String, dynamic>? headers})`: Add sync item
- `getSyncItem(String id)`: Get sync item by ID
- `getPendingSyncItems()`: Get all pending sync items
- `getSyncItemsByStatus(SyncStatus status)`: Get sync items by status
- `retryFailedItems()`: Retry failed sync items
- `forceSync()`: Force sync now
- `cancelSyncItem(String id)`: Cancel a sync item
- `getSyncStats()`: Get sync statistics
- `isOnline`: Check if device is online

## Data Models

### StorageItem

Represents a storage item with metadata.

```dart
StorageItem({
  required String key,
  required dynamic value,
  String? type,
  DateTime? createdAt,
  DateTime? updatedAt,
  bool isEncrypted = false,
  Map<String, dynamic>? metadata,
})
```

### CacheItem

Represents a cache item with expiration.

```dart
CacheItem({
  required String key,
  required dynamic data,
  required DateTime expiresAt,
  String? tag,
  Map<String, dynamic>? metadata,
})
```

### SyncItem

Represents a sync item for offline synchronization.

```dart
SyncItem({
  required String id,
  required String endpoint,
  required SyncOperation operation,
  required Map<String, dynamic> data,
  SyncStatus status = SyncStatus.pending,
  DateTime? createdAt,
  DateTime? lastAttempt,
  int attemptCount = 0,
  String? errorMessage,
  Map<String, dynamic>? headers,
  String? responseData,
})
```

## Advanced Usage

### Custom Encryption Key

```dart
// Generate a secure encryption key
final encryptionKey = EncryptionService.generateRandomKey(length: 64);

// Initialize with custom key
await TamimahStorage.initialize(encryptionKey: encryptionKey);
```

### Database Querying

```dart
// Query items by type
final userItems = await LocalDatabase.getItemsByType('User');

// Query items by metadata
final premiumUsers = await LocalDatabase.getItemsByMetadata('subscription', 'premium');

// Get all items with metadata
final allItems = await LocalDatabase.getAllItems();
```

### Cache Management

```dart
// Set default expiration
CacheManager.setDefaultExpiration(Duration(hours: 1));

// Get items expiring soon
final expiringSoon = await CacheManager.getExpiringSoon(Duration(minutes: 5));

// Refresh cache item
await CacheManager.refresh('api_data', newExpiration: Duration(hours: 2));
```

### Offline Sync Configuration

```dart
// Set custom base URL
OfflineSync.setBaseUrl('https://your-api.com');

// Add authentication headers
OfflineSync.setAuthHeaders({
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json'
});
```

## Error Handling

All services include proper error handling:

```dart
try {
  await SecureStorage.setString('key', 'value');
} catch (e) {
  print('Error storing data: $e');
}

try {
  final data = await LocalDatabase.get('key');
} catch (e) {
  print('Error retrieving data: $e');
}
```

## Performance Considerations

- Use cache for frequently accessed data
- Implement proper cleanup for expired cache items
- Use appropriate encryption only for sensitive data
- Monitor sync queue size to prevent memory issues

## Security Best Practices

- Use strong encryption keys
- Store sensitive data in SecureStorage
- Regularly rotate encryption keys
- Implement proper access controls
- Validate all input data

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions, please open an issue on GitHub or contact the maintainers.
