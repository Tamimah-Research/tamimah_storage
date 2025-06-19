import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/sync_item.dart';

/// Offline sync service for handling data synchronization
class OfflineSync {
  static const String _baseUrl =
      'https://api.example.com'; // Replace with your API base URL
  static late Box<SyncItem> _syncBox;
  static bool _initialized = false;
  static Timer? _syncTimer;
  static StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;
  static bool _isOnline = false;
  static final Uuid _uuid = Uuid();

  /// Initialize offline sync service
  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialize Hive
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncItemAdapter());
    }

    await Hive.initFlutter();

    // Open sync box
    _syncBox = await Hive.openBox<SyncItem>('tamimah_sync');

    // Monitor connectivity
    await _setupConnectivityMonitoring();

    // Start sync timer
    _startSyncTimer();

    _initialized = true;
  }

  /// Set up connectivity monitoring
  static Future<void> _setupConnectivityMonitoring() async {
    // Check initial connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult.any(
      (result) => result != ConnectivityResult.none,
    );

    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final wasOnline = _isOnline;
      // Check if any of the results indicate we're online
      _isOnline = results.any((result) => result != ConnectivityResult.none);

      // If we just came online, trigger sync
      if (!wasOnline && _isOnline) {
        _triggerSync();
      }
    });
  }

  /// Start sync timer
  static void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _triggerSync(),
    );
  }

  /// Trigger sync process
  static Future<void> _triggerSync() async {
    if (!_isOnline) return;

    try {
      await _processPendingSyncItems();
    } catch (e) {
      print('Error during sync: $e');
    }
  }

  /// Add a sync item to the queue
  static Future<String> addSyncItem({
    required String endpoint,
    required SyncOperation operation,
    required Map<String, dynamic> data,
    Map<String, dynamic>? headers,
  }) async {
    _ensureInitialized();

    final id = _uuid.v4();
    final syncItem = SyncItem(
      id: id,
      endpoint: endpoint,
      operation: operation,
      data: data,
      headers: headers,
    );

    await _syncBox.put(id, syncItem);

    // Trigger sync if online
    if (_isOnline) {
      _triggerSync();
    }

    return id;
  }

  /// Get a sync item by ID
  static Future<SyncItem?> getSyncItem(String id) async {
    _ensureInitialized();
    return _syncBox.get(id);
  }

  /// Get all pending sync items
  static Future<List<SyncItem>> getPendingSyncItems() async {
    _ensureInitialized();

    final items = <SyncItem>[];
    for (final item in _syncBox.values) {
      if (item.status == SyncStatus.pending ||
          (item.status == SyncStatus.failed && item.canRetry)) {
        items.add(item);
      }
    }

    return items;
  }

  /// Get sync items by status
  static Future<List<SyncItem>> getSyncItemsByStatus(SyncStatus status) async {
    _ensureInitialized();

    final items = <SyncItem>[];
    for (final item in _syncBox.values) {
      if (item.status == status) {
        items.add(item);
      }
    }

    return items;
  }

  /// Remove a sync item
  static Future<void> removeSyncItem(String id) async {
    _ensureInitialized();
    await _syncBox.delete(id);
  }

  /// Clear all sync items
  static Future<void> clearSyncItems() async {
    _ensureInitialized();
    await _syncBox.clear();
  }

  /// Process pending sync items
  static Future<void> _processPendingSyncItems() async {
    final pendingItems = await getPendingSyncItems();

    for (final item in pendingItems) {
      try {
        await _processSyncItem(item);
      } catch (e) {
        print('Error processing sync item ${item.id}: $e');

        // Mark as failed
        final failedItem = item.markFailed(errorMessage: e.toString());
        await _syncBox.put(item.id, failedItem);
      }
    }
  }

  /// Process a single sync item
  static Future<void> _processSyncItem(SyncItem item) async {
    // Mark as in progress
    final inProgressItem = item.markInProgress();
    await _syncBox.put(item.id, inProgressItem);

    try {
      final response = await _makeHttpRequest(item);

      // Mark as completed
      final completedItem = item.markCompleted(responseData: response);
      await _syncBox.put(item.id, completedItem);
    } catch (e) {
      // Mark as failed
      final failedItem = item.markFailed(errorMessage: e.toString());
      await _syncBox.put(item.id, failedItem);
      rethrow;
    }
  }

  /// Make HTTP request for sync item
  static Future<String> _makeHttpRequest(SyncItem item) async {
    final url = Uri.parse('$_baseUrl${item.endpoint}');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?item.headers,
    };

    http.Response response;

    switch (item.operation) {
      case SyncOperation.create:
        response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(item.data),
        );
        break;

      case SyncOperation.update:
        response = await http.put(
          url,
          headers: headers,
          body: jsonEncode(item.data),
        );
        break;

      case SyncOperation.delete:
        response = await http.delete(
          url,
          headers: headers,
          body: jsonEncode(item.data),
        );
        break;

      case SyncOperation.read:
        response = await http.get(url, headers: headers);
        break;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body;
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  /// Retry failed sync items
  static Future<void> retryFailedItems() async {
    final failedItems = await getSyncItemsByStatus(SyncStatus.failed);

    for (final item in failedItems) {
      if (item.canRetry) {
        // Reset to pending status
        final pendingItem = item.copyWith(status: SyncStatus.pending);
        await _syncBox.put(item.id, pendingItem);
      }
    }

    // Trigger sync
    _triggerSync();
  }

  /// Get sync statistics
  static Future<Map<String, dynamic>> getSyncStats() async {
    _ensureInitialized();

    final totalItems = _syncBox.length;
    int pendingItems = 0;
    int inProgressItems = 0;
    int completedItems = 0;
    int failedItems = 0;
    int retryableItems = 0;

    for (final item in _syncBox.values) {
      switch (item.status) {
        case SyncStatus.pending:
          pendingItems++;
          break;
        case SyncStatus.inProgress:
          inProgressItems++;
          break;
        case SyncStatus.completed:
          completedItems++;
          break;
        case SyncStatus.failed:
          failedItems++;
          if (item.canRetry) retryableItems++;
          break;
        case SyncStatus.cancelled:
          break;
      }
    }

    return {
      'totalItems': totalItems,
      'pendingItems': pendingItems,
      'inProgressItems': inProgressItems,
      'completedItems': completedItems,
      'failedItems': failedItems,
      'retryableItems': retryableItems,
      'isOnline': _isOnline,
      'initialized': _initialized,
    };
  }

  /// Set custom base URL for API
  static void setBaseUrl(String baseUrl) {
    // This would update the base URL
    // Implementation depends on your needs
  }

  /// Add authentication headers
  static void setAuthHeaders(Map<String, String> headers) {
    // This would set authentication headers for all requests
    // Implementation depends on your needs
  }

  /// Check if device is online
  static bool get isOnline => _isOnline;

  /// Force sync now
  static Future<void> forceSync() async {
    await _processPendingSyncItems();
  }

  /// Cancel a sync item
  static Future<void> cancelSyncItem(String id) async {
    _ensureInitialized();

    final item = await getSyncItem(id);
    if (item != null) {
      final cancelledItem = item.copyWith(status: SyncStatus.cancelled);
      await _syncBox.put(id, cancelledItem);
    }
  }

  /// Get sync items that can be retried
  static Future<List<SyncItem>> getRetryableItems() async {
    final failedItems = await getSyncItemsByStatus(SyncStatus.failed);
    return failedItems.where((item) => item.canRetry).toList();
  }

  /// Export sync data
  static Future<Map<String, dynamic>> exportSyncData() async {
    _ensureInitialized();

    final items = <Map<String, dynamic>>[];
    for (final item in _syncBox.values) {
      items.add(item.toJson());
    }

    return {'syncItems': items, 'exportedAt': DateTime.now().toIso8601String()};
  }

  /// Import sync data
  static Future<void> importSyncData(Map<String, dynamic> data) async {
    _ensureInitialized();

    if (data.containsKey('syncItems')) {
      final items = data['syncItems'] as List<dynamic>;

      for (final itemData in items) {
        final item = SyncItem.fromJson(itemData as Map<String, dynamic>);
        await _syncBox.put(item.id, item);
      }
    }
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'OfflineSync must be initialized before use. Call OfflineSync.initialize() first.',
      );
    }
  }

  /// Dispose offline sync service
  static Future<void> dispose() async {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();

    if (_initialized) {
      await _syncBox.close();
      _initialized = false;
    }
  }
}
