import 'dart:async';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/cache_item.dart';

/// Cache manager service for managing cached data
class CacheManager {
  static const String _boxName = 'tamimah_cache';
  static late Box<CacheItem> _box;
  static bool _initialized = false;
  static Duration _defaultExpiration = const Duration(hours: 1);
  static Timer? _cleanupTimer;

  /// Initialize cache manager
  static Future<void> initialize({Duration? expiration}) async {
    if (_initialized) return;

    // Initialize Hive
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CacheItemAdapter());
    }

    await Hive.initFlutter();

    // Open cache box
    _box = await Hive.openBox<CacheItem>(_boxName);

    // Set default expiration
    if (expiration != null) {
      _defaultExpiration = expiration;
    }

    // Start cleanup timer
    _startCleanupTimer();

    _initialized = true;
  }

  /// Set a cache item
  static Future<void> set(
    String key,
    dynamic data, {
    Duration? expiration,
    String? tag,
    Map<String, dynamic>? metadata,
  }) async {
    _ensureInitialized();

    final expiresAt = DateTime.now().add(expiration ?? _defaultExpiration);

    final item = CacheItem(
      key: key,
      data: data,
      expiresAt: expiresAt,
      tag: tag,
      metadata: metadata,
    );

    await _box.put(key, item);
  }

  /// Get a cache item
  static Future<dynamic> get(String key) async {
    _ensureInitialized();

    final item = _box.get(key);
    if (item == null) return null;

    // Check if expired
    if (item.isExpired) {
      await _box.delete(key);
      return null;
    }

    return item.data;
  }

  /// Get a cache item with metadata
  static Future<CacheItem?> getItem(String key) async {
    _ensureInitialized();

    final item = _box.get(key);
    if (item == null) return null;

    // Check if expired
    if (item.isExpired) {
      await _box.delete(key);
      return null;
    }

    return item;
  }

  /// Check if a key exists and is not expired
  static Future<bool> containsKey(String key) async {
    _ensureInitialized();

    final item = _box.get(key);
    if (item == null) return false;

    if (item.isExpired) {
      await _box.delete(key);
      return false;
    }

    return true;
  }

  /// Remove a cache item
  static Future<void> remove(String key) async {
    _ensureInitialized();
    await _box.delete(key);
  }

  /// Clear all cache
  static Future<void> clear() async {
    _ensureInitialized();
    await _box.clear();
  }

  /// Clear cache by tag
  static Future<void> clearByTag(String tag) async {
    _ensureInitialized();

    final keysToRemove = <String>[];

    for (final item in _box.values) {
      if (item.tag == tag) {
        keysToRemove.add(item.key);
      }
    }

    for (final key in keysToRemove) {
      await _box.delete(key);
    }
  }

  /// Get all cache keys
  static Future<List<String>> getKeys() async {
    _ensureInitialized();
    return _box.keys.cast<String>().toList();
  }

  /// Get all cache items
  static Future<List<CacheItem>> getAllItems() async {
    _ensureInitialized();
    return _box.values.toList();
  }

  /// Get cache items by tag
  static Future<List<CacheItem>> getItemsByTag(String tag) async {
    _ensureInitialized();

    final items = <CacheItem>[];
    for (final item in _box.values) {
      if (item.tag == tag && !item.isExpired) {
        items.add(item);
      }
    }

    return items;
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getStats() async {
    _ensureInitialized();

    final totalItems = _box.length;
    int expiredItems = 0;
    int validItems = 0;
    int totalSize = 0;

    for (final item in _box.values) {
      if (item.isExpired) {
        expiredItems++;
      } else {
        validItems++;
      }
      totalSize += item.data.toString().length;
    }

    return {
      'totalItems': totalItems,
      'validItems': validItems,
      'expiredItems': expiredItems,
      'totalSize': totalSize,
      'defaultExpiration': _defaultExpiration.inSeconds,
      'initialized': _initialized,
    };
  }

  /// Clean up expired items
  static Future<void> cleanup() async {
    _ensureInitialized();

    final keysToRemove = <String>[];

    for (final item in _box.values) {
      if (item.isExpired) {
        keysToRemove.add(item.key);
      }
    }

    for (final key in keysToRemove) {
      await _box.delete(key);
    }
  }

  /// Set cache expiration for a specific item
  static Future<void> setExpiration(String key, Duration expiration) async {
    _ensureInitialized();

    final item = _box.get(key);
    if (item == null) return;

    final updatedItem = item.copyWith(
      expiresAt: DateTime.now().add(expiration),
    );

    await _box.put(key, updatedItem);
  }

  /// Get remaining time for a cache item
  static Future<Duration?> getTimeUntilExpiration(String key) async {
    _ensureInitialized();

    final item = _box.get(key);
    if (item == null || item.isExpired) return null;

    return item.timeUntilExpiration;
  }

  /// Refresh a cache item (extend expiration)
  static Future<void> refresh(String key, {Duration? newExpiration}) async {
    _ensureInitialized();

    final item = _box.get(key);
    if (item == null) return;

    final expiration = newExpiration ?? _defaultExpiration;
    final updatedItem = item.copyWith(
      expiresAt: DateTime.now().add(expiration),
    );

    await _box.put(key, updatedItem);
  }

  /// Touch a cache item (update access time)
  static Future<void> touch(String key) async {
    _ensureInitialized();

    final item = _box.get(key);
    if (item == null) return;

    // For now, just refresh the item
    await refresh(key);
  }

  /// Get cache items that will expire soon
  static Future<List<CacheItem>> getExpiringSoon(Duration threshold) async {
    _ensureInitialized();

    final items = <CacheItem>[];
    final now = DateTime.now();

    for (final item in _box.values) {
      if (!item.isExpired && item.expiresAt.difference(now) <= threshold) {
        items.add(item);
      }
    }

    return items;
  }

  /// Set default expiration for new cache items
  static void setDefaultExpiration(Duration expiration) {
    _defaultExpiration = expiration;
  }

  /// Get default expiration
  static Duration get defaultExpiration => _defaultExpiration;

  static void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => cleanup(),
    );
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'CacheManager must be initialized before use. Call CacheManager.initialize() first.',
      );
    }
  }

  /// Dispose cache manager
  static Future<void> dispose() async {
    _cleanupTimer?.cancel();

    if (_initialized) {
      await _box.close();
      _initialized = false;
    }
  }
}
