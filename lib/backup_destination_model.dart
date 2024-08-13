import 'package:flutter/foundation.dart';

class BackupDestination {
  final int id;
  final int userId;
  final String label;
  final String type;
  final String typeHuman;
  final String? s3BucketName;
  final bool? pathStyleEndpoint;
  final String? s3Region;
  final String? s3Endpoint;
  final DateTime createdAt;
  final DateTime updatedAt;

  BackupDestination({
    required this.id,
    required this.userId,
    required this.label,
    required this.type,
    required this.typeHuman,
    this.s3BucketName,
    this.pathStyleEndpoint,
    this.s3Region,
    this.s3Endpoint,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BackupDestination.fromJson(Map<String, dynamic> json) {
    return BackupDestination(
      id: json['id'],
      userId: json['user_id'],
      label: json['label'],
      type: json['type'],
      typeHuman: json['type_human'],
      s3BucketName: json['s3_bucket_name'],
      pathStyleEndpoint: json['path_style_endpoint'],
      s3Region: json['s3_region'],
      s3Endpoint: json['s3_endpoint'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'label': label,
      'type': type,
      'type_human': typeHuman,
      's3_bucket_name': s3BucketName,
      'path_style_endpoint': pathStyleEndpoint,
      's3_region': s3Region,
      's3_endpoint': s3Endpoint,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
