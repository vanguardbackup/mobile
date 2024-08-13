import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'backup_task_model.dart';
import 'auth_manager.dart';

class BackupTaskProvider with ChangeNotifier {
  List<BackupTask>? _backupTasks;
  List<BackupTask>? get backupTasks => _backupTasks;
  final AuthManager authManager;
  String? _error;
  String? get error => _error;

  // Rate limiting variables
  final int _maxRequestsPerMinute = 60;
  final Duration _rateLimitWindow = const Duration(minutes: 1);
  final List<DateTime> _requestTimestamps = [];

  BackupTaskProvider({required this.authManager});

  Future<bool> fetchBackupTasks() async {
    if (!authManager.isLoggedIn) {
      _error = 'Not logged in';
      notifyListeners();
      return false;
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.get(
        Uri.parse('${authManager.baseUrl}/api/backup-tasks'),
        headers: authManager.headers,
      );

      _recordRequest();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('data')) {
          _backupTasks = (jsonResponse['data'] as List)
              .map((item) => BackupTask.fromJson(item))
              .toList();
          _error = null;
          notifyListeners();
          return true;
        } else {
          throw Exception('Invalid backup tasks data format');
        }
      } else if (response.statusCode == 429) {
        final retryAfter =
            int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return fetchBackupTasks();
      } else {
        throw Exception('Failed to load backup tasks: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Fetch backup tasks error: $e';
      print(_error);
      notifyListeners();
      return false;
    }
  }

  Future<ApiResponse> runBackupTask(int taskId) async {
    if (!authManager.isLoggedIn) {
      return ApiResponse(message: 'Not logged in', statusCode: 401);
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.post(
        Uri.parse('${authManager.baseUrl}/api/backup-tasks/$taskId/run'),
        headers: authManager.headers,
      );

      _recordRequest();

      final jsonResponse = json.decode(response.body);
      final apiResponse = ApiResponse(
        message: jsonResponse['message'] ?? 'Unknown response',
        statusCode: response.statusCode,
      );

      if (response.statusCode == 202) {
        // Refetch the backup tasks to update the status
        await fetchBackupTasks();
      } else if (response.statusCode == 429) {
        final retryAfter =
            int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return runBackupTask(taskId);
      }

      return apiResponse;
    } catch (e) {
      print('Run backup task error: $e');
      return ApiResponse(
          message: 'An unexpected error occurred', statusCode: 500);
    }
  }

  Future<BackupTask?> getBackupTask(int taskId) async {
    if (!authManager.isLoggedIn) {
      _error = 'Not logged in';
      notifyListeners();
      return null;
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.get(
        Uri.parse('${authManager.baseUrl}/api/backup-tasks/$taskId'),
        headers: authManager.headers,
      );

      _recordRequest();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('data')) {
          return BackupTask.fromJson(jsonResponse['data']);
        } else {
          throw Exception('Invalid backup task data format');
        }
      } else if (response.statusCode == 429) {
        final retryAfter =
            int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return getBackupTask(taskId);
      } else {
        throw Exception('Failed to load backup task: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Get backup task error: $e';
      print(_error);
      notifyListeners();
      return null;
    }
  }

  Future<BackupTaskLog?> getLatestBackupTaskLog(int taskId) async {
    if (!authManager.isLoggedIn) {
      print('Not logged in');
      return null;
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.get(
        Uri.parse('${authManager.baseUrl}/api/backup-tasks/$taskId/latest-log'),
        headers: {
          ...authManager.headers,
          'Accept': 'application/json',
        },
      );

      _recordRequest();

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          if (jsonData is Map<String, dynamic> &&
              jsonData.containsKey('data')) {
            return BackupTaskLog.fromJson(jsonData['data']);
          } else {
            print('Invalid JSON structure: ${response.body}');
            return null;
          }
        } on FormatException catch (e) {
          print('Error parsing JSON: $e');
          print('Response body: ${response.body}');
          return null;
        }
      } else if (response.statusCode == 429) {
        final retryAfter =
            int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return getLatestBackupTaskLog(taskId);
      } else {
        print('Failed to load latest log: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching latest log: $e');
      return null;
    }
  }

  bool _canMakeRequest() {
    final now = DateTime.now();
    _requestTimestamps.removeWhere(
        (timestamp) => now.difference(timestamp) > _rateLimitWindow);
    return _requestTimestamps.length < _maxRequestsPerMinute;
  }

  Future<void> _waitForNextAvailableSlot() async {
    final now = DateTime.now();
    final oldestTimestamp = _requestTimestamps.first;
    final waitDuration = _rateLimitWindow - now.difference(oldestTimestamp);
    await Future.delayed(waitDuration);
  }

  void _recordRequest() {
    _requestTimestamps.add(DateTime.now());
    if (_requestTimestamps.length > _maxRequestsPerMinute) {
      _requestTimestamps.removeAt(0);
    }
  }
}

class BackupTaskLog {
  final int id;
  final int backupTaskId;
  final String output;
  final DateTime finishedAt;
  final String status;
  final DateTime createdAt;

  BackupTaskLog({
    required this.id,
    required this.backupTaskId,
    required this.output,
    required this.finishedAt,
    required this.status,
    required this.createdAt,
  });

  factory BackupTaskLog.fromJson(Map<String, dynamic> json) {
    return BackupTaskLog(
      id: json['id'],
      backupTaskId: json['backup_task_id'],
      output: json['output'],
      finishedAt: DateTime.parse(json['finished_at']),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ApiResponse {
  final String message;
  final int statusCode;

  ApiResponse({required this.message, required this.statusCode});
}
