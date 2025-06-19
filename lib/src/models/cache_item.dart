import 'package:hive/hive.dart';

part 'cache_item.g.dart';

@HiveType(typeId: 1)
class CacheItem extends HiveObject {
  @HiveField(0)
  final String key;

  @HiveField(1)
  final dynamic data;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final DateTime expiresAt;

  @HiveField(4)
  final String? tag;

  @HiveField(5)
  final Map<String, dynamic>? metadata;

  CacheItem({
    required this.key,
    required this.data,
    required this.expiresAt,
    DateTime? createdAt,
    this.tag,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Check if the cache item has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Get remaining time until expiration
  Duration get timeUntilExpiration => expiresAt.difference(DateTime.now());

  /// Create a cache item that expires after a specific duration
  factory CacheItem.withExpiration({
    required String key,
    required dynamic data,
    required Duration expiration,
    String? tag,
    Map<String, dynamic>? metadata,
  }) {
    return CacheItem(
      key: key,
      data: data,
      expiresAt: DateTime.now().add(expiration),
      tag: tag,
      metadata: metadata,
    );
  }

  CacheItem copyWith({
    String? key,
    dynamic data,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? tag,
    Map<String, dynamic>? metadata,
  }) {
    return CacheItem(
      key: key ?? this.key,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      tag: tag ?? this.tag,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'tag': tag,
      'metadata': metadata,
    };
  }

  factory CacheItem.fromJson(Map<String, dynamic> json) {
    return CacheItem(
      key: json['key'],
      data: json['data'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      tag: json['tag'],
      metadata: json['metadata'],
    );
  }
}
