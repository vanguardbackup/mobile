// backup_task_model.dart
class BackupTask {
  final int id;
  final int userId;
  final int remoteServerId;
  final int backupDestinationId;
  final String label;
  final String description;
  final SourceInfo source;
  final ScheduleInfo schedule;
  final StorageInfo storage;
  final int notificationStreamsCount;
  final String status;
  final bool hasIsolatedCredentials;
  final Timestamps timestamps;

  BackupTask({
    required this.id,
    required this.userId,
    required this.remoteServerId,
    required this.backupDestinationId,
    required this.label,
    required this.description,
    required this.source,
    required this.schedule,
    required this.storage,
    required this.notificationStreamsCount,
    required this.status,
    required this.hasIsolatedCredentials,
    required this.timestamps,
  });

  factory BackupTask.fromJson(Map<String, dynamic> json) {
    return BackupTask(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      remoteServerId: json['remote_server_id'] ?? 0,
      backupDestinationId: json['backup_destination_id'] ?? 0,
      label: json['label'] ?? '',
      description: json['description'] ?? '',
      source: SourceInfo.fromJson(json['source'] ?? {}),
      schedule: ScheduleInfo.fromJson(json['schedule'] ?? {}),
      storage: StorageInfo.fromJson(json['storage'] ?? {}),
      notificationStreamsCount: json['notification_streams_count'] ?? 0,
      status: json['status'] ?? '',
      hasIsolatedCredentials: json['has_isolated_credentials'] ?? false,
      timestamps: Timestamps.fromJson(json),
    );
  }
}

class SourceInfo {
  final String path;
  final String type;
  final String? databaseName;
  final String? excludedTables;

  SourceInfo({
    required this.path,
    required this.type,
    this.databaseName,
    this.excludedTables,
  });

  factory SourceInfo.fromJson(Map<String, dynamic> json) {
    return SourceInfo(
      path: json['path'] ?? '',
      type: json['type'] ?? '',
      databaseName: json['database_name'],
      excludedTables: json['excluded_tables'],
    );
  }
}

class ScheduleInfo {
  final String frequency;
  final String scheduledUtcTime;
  final String scheduledLocalTime;
  final String? customCron;

  ScheduleInfo({
    required this.frequency,
    required this.scheduledUtcTime,
    required this.scheduledLocalTime,
    this.customCron,
  });

  factory ScheduleInfo.fromJson(Map<String, dynamic> json) {
    return ScheduleInfo(
      frequency: json['frequency'] ?? '',
      scheduledUtcTime: json['scheduled_utc_time'] ?? '',
      scheduledLocalTime: json['scheduled_local_time'] ?? '',
      customCron: json['custom_cron'],
    );
  }
}

class StorageInfo {
  final int maxBackups;
  final String? appendedFilename;
  final String path;

  StorageInfo({
    required this.maxBackups,
    this.appendedFilename,
    required this.path,
  });

  factory StorageInfo.fromJson(Map<String, dynamic> json) {
    return StorageInfo(
      maxBackups: json['max_backups'] ?? 0,
      appendedFilename: json['appended_filename'],
      path: json['path'] ?? '',
    );
  }
}

class Timestamps {
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastRunLocalTime;
  final DateTime? pausedAt;

  Timestamps({
    required this.createdAt,
    required this.updatedAt,
    this.lastRunLocalTime,
    this.pausedAt,
  });

  factory Timestamps.fromJson(Map<String, dynamic> json) {
    return Timestamps(
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      lastRunLocalTime: json['last_run_local_time'],
      pausedAt:
          json['paused_at'] != null ? DateTime.parse(json['paused_at']) : null,
    );
  }
}
