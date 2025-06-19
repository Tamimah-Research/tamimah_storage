import 'package:hive/hive.dart';

part 'storage_item.g.dart';

@HiveType(typeId: 0)
class StorageItem extends HiveObject {
  @HiveField(0)
  final String key;

  @HiveField(1)
  final dynamic value;

  @HiveField(2)
  final String? type;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime? updatedAt;

  @HiveField(5)
  final bool isEncrypted;

  @HiveField(6)
  final Map<String, dynamic>? metadata;

  StorageItem({
    required this.key,
    required this.value,
    this.type,
    DateTime? createdAt,
    this.updatedAt,
    this.isEncrypted = false,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now();

  StorageItem copyWith({
    String? key,
    dynamic value,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEncrypted,
    Map<String, dynamic>? metadata,
  }) {
    return StorageItem(
      key: key ?? this.key,
      value: value ?? this.value,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isEncrypted': isEncrypted,
      'metadata': metadata,
    };
  }

  factory StorageItem.fromJson(Map<String, dynamic> json) {
    return StorageItem(
      key: json['key'],
      value: json['value'],
      type: json['type'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      isEncrypted: json['isEncrypted'] ?? false,
      metadata: json['metadata'],
    );
  }
}
