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

  // Caching variables
  final Map<String, CachedData<List<BackupTaskLogEntry>>> _cachedLogs = {};
  final Map<int, CachedData<BackupTaskLogEntry>> _cachedSingleLogs = {};
  final Duration _cacheDuration = const Duration(minutes: 5);

  BackupTaskLogProvider({required this.authManager});

  Future<bool> fetchLogs({
    int page = 1,
    int perPage = 10,
    String? search,
    bool forceRefresh = false,
  }) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    final cacheKey = _getCacheKey(page, perPage, search);
    final cachedData = _cachedLogs[cacheKey];

    if (!forceRefresh && cachedData != null && !cachedData.isExpired()) {
      _updateStateFromCache(cachedData.data, page, search);
      return true;
    }

    if (!_canMakeRequest()) {
      throw RateLimitException('Rate limit exceeded. Please try again later.');
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
              .map<BackupTaskLogEntry>(
                  (logJson) => BackupTaskLogEntry.fromJson(logJson))
              .toList();

          _cachedLogs[cacheKey] = CachedData(newLogs);

          _updateStateFromCache(newLogs, page, search);

          _currentPage = jsonResponse['meta']['current_page'];
          _totalPages = jsonResponse['meta']['last_page'];
          _hasMoreLogs = _currentPage < _totalPages;

          notifyListeners();
          return true;
        } else {
          throw Exception('Invalid logs data format');
        }
      } else if (response.statusCode == 429) {
        throw RateLimitException('Rate limit exceeded. Please try again later.');
      } else {
        throw Exception('Failed to load logs: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fetch logs error: $e');
      }
      rethrow;
    }
  }

  Future<bool> loadMoreLogs({int perPage = 10}) async {
    if (_hasMoreLogs) {
      return await fetchLogs(
          page: _currentPage + 1, perPage: perPage, search: _searchQuery);
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

    final cachedLog = _cachedSingleLogs[id];
    if (cachedLog != null && !cachedLog.isExpired()) {
      return cachedLog.data;
    }

    if (!_canMakeRequest()) {
      throw RateLimitException('Rate limit exceeded. Please try again later.');
    }

    try {
      final response = await http.get(
        Uri.parse('${authManager.baseUrl}/api/backup-task-logs/$id'),
        headers: authManager.headers,
      );

      _recordRequest();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final log = BackupTaskLogEntry.fromJson(jsonResponse['data']);
        _cachedSingleLogs[id] = CachedData(log);
        return log;
      } else if (response.statusCode == 429) {
        throw RateLimitException('Rate limit exceeded. Please try again later.');
      } else {
        throw Exception('Failed to get log: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Get log error: $e');
      }
      rethrow;
    }
  }

  Future<bool> deleteLog(int id) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      throw RateLimitException('Rate limit exceeded. Please try again later.');
    }

    try {
      final response = await http.delete(
        Uri.parse('${authManager.baseUrl}/api/backup-task-logs/$id'),
        headers: authManager.headers,
      );

      _recordRequest();

      if (response.statusCode == 204) {
        _logs.removeWhere((log) => log.id == id);
        _cachedSingleLogs.remove(id);
        _invalidateListCache();
        notifyListeners();
        return true;
      } else if (response.statusCode == 429) {
        throw RateLimitException('Rate limit exceeded. Please try again later.');
      } else {
        throw Exception('Failed to delete log: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Delete log error: $e');
      }
      rethrow;
    }
  }

  void clearLogs() {
    _logs.clear();
    _currentPage = 1;
    _totalPages = 1;
    _hasMoreLogs = true;
    _searchQuery = '';
    _invalidateListCache();
    notifyListeners();
  }

  void refreshLogs() {
    clearLogs();
    fetchLogs();
  }

  Future<bool> forceRefresh({int perPage = 10}) async {
    _invalidateListCache();
    return await fetchLogs(page: 1, perPage: perPage, search: _searchQuery, forceRefresh: true);
  }

  bool _canMakeRequest() {
    final now = DateTime.now();
    _requestTimestamps.removeWhere(
            (timestamp) => now.difference(timestamp) > _rateLimitWindow);
    return _requestTimestamps.length < _maxRequestsPerMinute;
  }

  void _recordRequest() {
    _requestTimestamps.add(DateTime.now());
    if (_requestTimestamps.length > _maxRequestsPerMinute) {
      _requestTimestamps.removeAt(0);
    }
  }

  String _getCacheKey(int page, int perPage, String? search) {
    return 'page_${page}_perPage_${perPage}_search_${search ?? ""}';
  }

  void _updateStateFromCache(List<BackupTaskLogEntry> cachedLogs, int page, String? search) {
    if (page == 1) {
      _logs.clear();
    }
    _logs.addAll(cachedLogs);
    _searchQuery = search ?? '';
  }

  void _invalidateListCache() {
    _cachedLogs.clear();
  }
}

class CachedData<T> {
  final T data;
  final DateTime timestamp;

  CachedData(this.data) : timestamp = DateTime.now();

  bool isExpired() {
    return DateTime.now().difference(timestamp) > const Duration(minutes: 5);
  }
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);

  @override
  String toString() => message;
}