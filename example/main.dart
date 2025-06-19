import 'package:flutter/material.dart';
import 'package:tamimah_storage/tamimah_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Tamimah Storage
  await TamimahStorage.initialize(
    encryptionKey: 'your-secure-encryption-key-32-chars-long',
    cacheExpiration: Duration(hours: 1),
  );

  runApp(const TamimahStorageExample());
}

class TamimahStorageExample extends StatelessWidget {
  const TamimahStorageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tamimah Storage Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const StorageDemoPage(),
    );
  }
}

class StorageDemoPage extends StatefulWidget {
  const StorageDemoPage({super.key});

  @override
  State<StorageDemoPage> createState() => _StorageDemoPageState();
}

class _StorageDemoPageState extends State<StorageDemoPage> {
  String _secureStorageResult = '';
  String _databaseResult = '';
  String _cacheResult = '';
  String _syncResult = '';
  String _encryptionResult = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tamimah Storage Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(
              'Secure Storage',
              'Store sensitive data with encryption',
              Icons.security,
              Colors.red,
              _secureStorageResult,
              _demoSecureStorage,
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Local Database',
              'Store structured data with Hive',
              Icons.storage,
              Colors.blue,
              _databaseResult,
              _demoLocalDatabase,
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Cache Management',
              'Cache data with expiration',
              Icons.speed,
              Colors.green,
              _cacheResult,
              _demoCacheManager,
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Offline Sync',
              'Queue data for sync when online',
              Icons.sync,
              Colors.orange,
              _syncResult,
              _demoOfflineSync,
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Encryption',
              'Encrypt and decrypt data',
              Icons.lock,
              Colors.purple,
              _encryptionResult,
              _demoEncryption,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showStats,
              child: const Text('Show All Statistics'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String result,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (result.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(result, style: const TextStyle(fontSize: 12)),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                child: Text('Test $title'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _demoSecureStorage() async {
    try {
      // Store sensitive data
      await SecureStorage.setString('auth_token', 'jwt_token_123456');
      await SecureStorage.setObject('user_profile', {
        'id': 123,
        'email': 'user@example.com',
        'preferences': {'theme': 'dark', 'notifications': true},
      });
      await SecureStorage.setList('recent_searches', [
        'flutter',
        'dart',
        'storage',
      ]);

      // Retrieve data
      final token = await SecureStorage.getString('auth_token');
      final profile = await SecureStorage.getObject('user_profile');
      final searches = await SecureStorage.getList('recent_searches');

      setState(() {
        _secureStorageResult =
            '''
Token: $token
Profile: $profile
Searches: $searches
        ''';
      });
    } catch (e) {
      setState(() {
        _secureStorageResult = 'Error: $e';
      });
    }
  }

  Future<void> _demoLocalDatabase() async {
    try {
      // Store data in database
      await LocalDatabase.set(
        'user_123',
        {
          'name': 'John Doe',
          'email': 'john@example.com',
          'created_at': DateTime.now().toIso8601String(),
        },
        type: 'User',
        encrypt: true,
      );

      await LocalDatabase.set('product_456', {
        'name': 'Flutter Widget',
        'price': 29.99,
        'category': 'Development',
      }, type: 'Product');

      // Query data
      final user = await LocalDatabase.get('user_123');
      final product = await LocalDatabase.get('product_456');
      final users = await LocalDatabase.getItemsByType('User');
      final products = await LocalDatabase.getItemsByType('Product');

      setState(() {
        _databaseResult =
            '''
User: $user
Product: $product
Total Users: ${users.length}
Total Products: ${products.length}
        ''';
      });
    } catch (e) {
      setState(() {
        _databaseResult = 'Error: $e';
      });
    }
  }

  Future<void> _demoCacheManager() async {
    try {
      // Cache API responses
      await CacheManager.set(
        'api_users',
        [
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Bob'},
          {'id': 3, 'name': 'Charlie'},
        ],
        expiration: Duration(minutes: 5),
        tag: 'users',
      );

      await CacheManager.set(
        'api_products',
        [
          {'id': 1, 'name': 'Product A', 'price': 10.99},
          {'id': 2, 'name': 'Product B', 'price': 20.99},
        ],
        expiration: Duration(minutes: 10),
        tag: 'products',
      );

      // Retrieve cached data
      final users = await CacheManager.get('api_users');
      final products = await CacheManager.get('api_products');
      final userItems = await CacheManager.getItemsByTag('users');
      final productItems = await CacheManager.getItemsByTag('products');

      setState(() {
        _cacheResult =
            '''
Users: $users
Products: $products
User Cache Items: ${userItems.length}
Product Cache Items: ${productItems.length}
        ''';
      });
    } catch (e) {
      setState(() {
        _cacheResult = 'Error: $e';
      });
    }
  }

  Future<void> _demoOfflineSync() async {
    try {
      // Add sync items
      final syncId1 = await OfflineSync.addSyncItem(
        endpoint: '/api/users',
        operation: SyncOperation.create,
        data: {'name': 'New User', 'email': 'new@example.com'},
      );

      final syncId2 = await OfflineSync.addSyncItem(
        endpoint: '/api/products',
        operation: SyncOperation.update,
        data: {'id': 1, 'name': 'Updated Product'},
      );

      // Get sync status
      final pendingItems = await OfflineSync.getPendingSyncItems();
      final stats = await OfflineSync.getSyncStats();
      final isOnline = OfflineSync.isOnline;

      setState(() {
        _syncResult =
            '''
Sync ID 1: $syncId1
Sync ID 2: $syncId2
Pending Items: ${pendingItems.length}
Total Items: ${stats['totalItems']}
Is Online: $isOnline
        ''';
      });
    } catch (e) {
      setState(() {
        _syncResult = 'Error: $e';
      });
    }
  }

  Future<void> _demoEncryption() async {
    try {
      // Test encryption
      const originalText = 'Hello, Tamimah Storage!';
      final encryptedText = EncryptionService.encryptString(originalText);
      final decryptedText = EncryptionService.decryptString(encryptedText);

      final originalObject = {'key': 'value', 'number': 42};
      final encryptedObject = EncryptionService.encryptObject(originalObject);
      final decryptedObject = EncryptionService.decryptObject(encryptedObject);

      final originalList = [1, 2, 3, 'test'];
      final encryptedList = EncryptionService.encryptList(originalList);
      final decryptedList = EncryptionService.decryptList(encryptedList);

      // Generate random key
      final randomKey = EncryptionService.generateRandomKey(length: 32);

      // Hash string
      const inputString = 'password123';
      final hash = EncryptionService.hashString(inputString);
      final isValid = EncryptionService.verifyHash(inputString, hash);

      setState(() {
        _encryptionResult =
            '''
Text: $originalText
Encrypted: $encryptedText
Decrypted: $decryptedText
Object: $originalObject
Object Encrypted: $encryptedObject
Object Decrypted: $decryptedObject
List: $originalList
List Encrypted: $encryptedList
List Decrypted: $decryptedList
Random Key: $randomKey
Hash: $hash
Valid: $isValid
        ''';
      });
    } catch (e) {
      setState(() {
        _encryptionResult = 'Error: $e';
      });
    }
  }

  Future<void> _showStats() async {
    try {
      final secureStats = await SecureStorage.getStorageInfo();
      final dbStats = await LocalDatabase.getStats();
      final cacheStats = await CacheManager.getStats();
      final syncStats = await OfflineSync.getSyncStats();
      final encryptionInfo = EncryptionService.getEncryptionInfo();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Storage Statistics'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatItem('Secure Storage', secureStats),
                const Divider(),
                _buildStatItem('Database', dbStats),
                const Divider(),
                _buildStatItem('Cache', cacheStats),
                const Divider(),
                _buildStatItem('Sync', syncStats),
                const Divider(),
                _buildStatItem('Encryption', encryptionInfo),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildStatItem(String title, Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        ...stats.entries.map(
          (entry) => Text(
            '${entry.key}: ${entry.value}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
