import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'backup_task_log_model.dart';
import 'auth_manager.dart';

class BackupTaskLogProvider with ChangeNotifier {
  final List<BackupTaskLogEntry> _logs = [];
  List<BackupTaskLogEntry> get logs => _logs;
  final AuthManager authManager;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreLogs = true;
  bool get hasMoreLogs => _hasMoreLogs;
  String _searchQuery = '';

  // Rate limiting variables
  final int _maxRequestsPerMinute = 60;
  final Duration _rateLimitWindow = const Duration(minutes: 1);
  final List<DateTime> _requestTimestamps = [];

  BackupTaskLogProvider({required this.authManager});

  Future<bool> fetchLogs({int page = 1, int perPage = 10, String? search}) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final queryParameters = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse('${authManager.baseUrl}/api/backup-task-logs')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: authManager.headers,
      );

      _recordRequest();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['data'] is List) {
          final newLogs = (jsonResponse['data'] as List)
              .map<BackupTaskLogEntry>((logJson) => BackupTaskLogEntry.fromJson(logJson))
              .toList();

          if (page == 1) {
            _logs.clear();
          }
          _logs.addAll(newLogs);

          _currentPage = jsonResponse['meta']['current_page'];
          _totalPages = jsonResponse['meta']['last_page'];
          _hasMoreLogs = _currentPage < _totalPages;
          _searchQuery = search ?? '';

          notifyListeners();
          return true;
        } else {
          throw Exception('Invalid logs data format');
        }
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return fetchLogs(page: page, perPage: perPage, search: search);
      } else {
        throw Exception('Failed to load logs: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fetch logs error: $e');
      }
      return false;
    }
  }

  Future<bool> loadMoreLogs({int perPage = 10}) async {
    if (_hasMoreLogs) {
      return await fetchLogs(page: _currentPage + 1, perPage: perPage, search: _searchQuery);
    }
    return false;
  }

  Future<bool> searchLogs(String query, {int perPage = 10}) async {
    clearLogs();
    return await fetchLogs(page: 1, perPage: perPage, search: query);
  }

  Future<BackupTaskLogEntry?> getLog(int id) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.get(
        Uri.parse('${authManager.baseUrl}/api/backup-task-logs/$id'),
        headers: authManager.headers,
      );

      _recordRequest();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return BackupTaskLogEntry.fromJson(jsonResponse['data']);
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return getLog(id);
      } else {
        throw Exception('Failed to get log: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Get log error: $e');
      }
      return null;
    }
  }

  Future<bool> deleteLog(int id) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.delete(
        Uri.parse('${authManager.baseUrl}/api/backup-task-logs/$id'),
        headers: authManager.headers,
      );

      _recordRequest();

      if (response.statusCode == 204) {
        _logs.removeWhere((log) => log.id == id);
        notifyListeners();
        return true;
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return deleteLog(id);
      } else {
        throw Exception('Failed to delete log: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Delete log error: $e');
      }
      return false;
    }
  }

  void clearLogs() {
    _logs.clear();
    _currentPage = 1;
    _totalPages = 1;
    _hasMoreLogs = true;
    _searchQuery = '';
    notifyListeners();
  }

  void refreshLogs() {
    clearLogs();
    fetchLogs();
  }

  bool _canMakeRequest() {
    final now = DateTime.now();
    _requestTimestamps.removeWhere((timestamp) => now.difference(timestamp) > _rateLimitWindow);
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