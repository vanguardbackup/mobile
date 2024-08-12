import 'package:flutter/foundation.dart';

class RemoteServer {
  final int id;
  final int userId;
  final String label;
  final RemoteServerConnection connection;
  final RemoteServerStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  RemoteServer({
    required this.id,
    required this.userId,
    required this.label,
    required this.connection,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RemoteServer.fromJson(Map<String, dynamic> json) {
    return RemoteServer(
      id: json['id'],
      userId: json['user_id'],
      label: json['label'],
      connection: RemoteServerConnection.fromJson(json['connection']),
      status: RemoteServerStatus.fromJson(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'label': label,
      'connection': connection.toJson(),
      'status': status.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class RemoteServerConnection {
  final String ipAddress;
  final String username;
  final int port;
  final bool isDatabasePasswordSet;

  RemoteServerConnection({
    required this.ipAddress,
    required this.username,
    required this.port,
    required this.isDatabasePasswordSet,
  });

  factory RemoteServerConnection.fromJson(Map<String, dynamic> json) {
    return RemoteServerConnection(
      ipAddress: json['ip_address'],
      username: json['username'],
      port: json['port'],
      isDatabasePasswordSet: json['is_database_password_set'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ip_address': ipAddress,
      'username': username,
      'port': port,
      'is_database_password_set': isDatabasePasswordSet,
    };
  }
}

class RemoteServerStatus {
  final String connectivity;
  final DateTime? lastConnectedAt;

  RemoteServerStatus({
    required this.connectivity,
    this.lastConnectedAt,
  });

  factory RemoteServerStatus.fromJson(Map<String, dynamic> json) {
    return RemoteServerStatus(
      connectivity: json['connectivity'],
      lastConnectedAt: json['last_connected_at'] != null
          ? DateTime.parse(json['last_connected_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connectivity': connectivity,
      'last_connected_at': lastConnectedAt?.toIso8601String(),
    };
  }
}