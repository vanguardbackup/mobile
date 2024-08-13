import 'package:flutter/foundation.dart';

class NotificationStream {
  final int id;
  final int userId;
  final String label;
  final String type;
  final String typeHuman;
  final NotificationSettings notifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationStream({
    required this.id,
    required this.userId,
    required this.label,
    required this.type,
    required this.typeHuman,
    required this.notifications,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationStream.fromJson(Map<String, dynamic> json) {
    return NotificationStream(
      id: json['id'],
      userId: json['user_id'],
      label: json['label'],
      type: json['type'],
      typeHuman: json['type_human'],
      notifications: NotificationSettings.fromJson(json['notifications']),
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
      'notifications': notifications.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class NotificationSettings {
  final bool onSuccess;
  final bool onFailure;

  NotificationSettings({
    required this.onSuccess,
    required this.onFailure,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      onSuccess: json['on_success'],
      onFailure: json['on_failure'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'on_success': onSuccess,
      'on_failure': onFailure,
    };
  }
}
