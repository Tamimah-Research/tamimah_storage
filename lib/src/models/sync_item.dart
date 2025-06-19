import 'package:hive/hive.dart';

part 'sync_item.g.dart';

enum SyncStatus { pending, inProgress, completed, failed, cancelled }

enum SyncOperation { create, update, delete, read }

@HiveType(typeId: 2)
class SyncItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String endpoint;

  @HiveField(2)
  final SyncOperation operation;

  @HiveField(3)
  final Map<String, dynamic> data;

  @HiveField(4)
  final SyncStatus status;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime? lastAttempt;

  @HiveField(7)
  final int attemptCount;

  @HiveField(8)
  final String? errorMessage;

  @HiveField(9)
  final Map<String, dynamic>? headers;

  @HiveField(10)
  final String? responseData;

  SyncItem({
    required this.id,
    required this.endpoint,
    required this.operation,
    required this.data,
    this.status = SyncStatus.pending,
    DateTime? createdAt,
    this.lastAttempt,
    this.attemptCount = 0,
    this.errorMessage,
    this.headers,
    this.responseData,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Mark the sync item as in progress
  SyncItem markInProgress() {
    return copyWith(
      status: SyncStatus.inProgress,
      lastAttempt: DateTime.now(),
      attemptCount: attemptCount + 1,
    );
  }

  /// Mark the sync item as completed
  SyncItem markCompleted({String? responseData}) {
    return copyWith(status: SyncStatus.completed, responseData: responseData);
  }

  /// Mark the sync item as failed
  SyncItem markFailed({String? errorMessage}) {
    return copyWith(status: SyncStatus.failed, errorMessage: errorMessage);
  }

  /// Check if the sync item can be retried
  bool get canRetry => status == SyncStatus.failed && attemptCount < 3;

  /// Get retry delay based on attempt count
  Duration get retryDelay {
    switch (attemptCount) {
      case 0:
        return const Duration(seconds: 1);
      case 1:
        return const Duration(seconds: 5);
      case 2:
        return const Duration(seconds: 15);
      default:
        return const Duration(minutes: 1);
    }
  }

  SyncItem copyWith({
    String? id,
    String? endpoint,
    SyncOperation? operation,
    Map<String, dynamic>? data,
    SyncStatus? status,
    DateTime? createdAt,
    DateTime? lastAttempt,
    int? attemptCount,
    String? errorMessage,
    Map<String, dynamic>? headers,
    String? responseData,
  }) {
    return SyncItem(
      id: id ?? this.id,
      endpoint: endpoint ?? this.endpoint,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      attemptCount: attemptCount ?? this.attemptCount,
      errorMessage: errorMessage ?? this.errorMessage,
      headers: headers ?? this.headers,
      responseData: responseData ?? this.responseData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'endpoint': endpoint,
      'operation': operation.name,
      'data': data,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'lastAttempt': lastAttempt?.toIso8601String(),
      'attemptCount': attemptCount,
      'errorMessage': errorMessage,
      'headers': headers,
      'responseData': responseData,
    };
  }

  factory SyncItem.fromJson(Map<String, dynamic> json) {
    return SyncItem(
      id: json['id'],
      endpoint: json['endpoint'],
      operation: SyncOperation.values.firstWhere(
        (e) => e.name == json['operation'],
      ),
      data: json['data'],
      status: SyncStatus.values.firstWhere((e) => e.name == json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      lastAttempt: json['lastAttempt'] != null
          ? DateTime.parse(json['lastAttempt'])
          : null,
      attemptCount: json['attemptCount'] ?? 0,
      errorMessage: json['errorMessage'],
      headers: json['headers'],
      responseData: json['responseData'],
    );
  }
}
