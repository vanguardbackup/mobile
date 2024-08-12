class BackupTaskLogEntry {
  final int id;
  final int backupTaskId;
  final String output;
  final DateTime finishedAt;
  final String status;
  final DateTime createdAt;

  BackupTaskLogEntry({
    required this.id,
    required this.backupTaskId,
    required this.output,
    required this.finishedAt,
    required this.status,
    required this.createdAt,
  });

  factory BackupTaskLogEntry.fromJson(Map<String, dynamic> json) {
    return BackupTaskLogEntry(
      id: json['id'],
      backupTaskId: json['backup_task_id'],
      output: json['output'],
      finishedAt: DateTime.parse(json['finished_at']),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'backup_task_id': backupTaskId,
      'output': output,
      'finished_at': finishedAt.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}