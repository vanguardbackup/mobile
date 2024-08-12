import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'remote_server_model.dart';
import 'auth_manager.dart';

class RemoteServerProvider with ChangeNotifier {
  final List<RemoteServer> _servers = [];
  List<RemoteServer> get servers => _servers;
  final AuthManager authManager;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreServers = true;
  bool get hasMoreServers => _hasMoreServers;

  // Rate limiting variables
  final int _maxRequestsPerMinute = 60;
  final Duration _rateLimitWindow = const Duration(minutes: 1);
  final List<DateTime> _requestTimestamps = [];

  RemoteServerProvider({required this.authManager});

  Future<bool> fetchServers({int page = 1, int perPage = 15}) async {
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
      };

      final uri = Uri.parse('${authManager.baseUrl}/api/remote-servers')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: authManager.headers,
      );

      _recordRequest();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['data'] is List) {
          final newServers = (jsonResponse['data'] as List)
              .map<RemoteServer>((serverJson) => RemoteServer.fromJson(serverJson))
              .toList();

          if (page == 1) {
            _servers.clear();
          }
          _servers.addAll(newServers);

          _currentPage = jsonResponse['meta']['current_page'];
          _totalPages = jsonResponse['meta']['last_page'];
          _hasMoreServers = _currentPage < _totalPages;

          notifyListeners();
          return true;
        } else {
          throw Exception('Invalid servers data format');
        }
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return fetchServers(page: page, perPage: perPage);
      } else {
        throw Exception('Failed to load servers: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fetch servers error: $e');
      }
      return false;
    }
  }

  Future<bool> loadMoreServers({int perPage = 15}) async {
    if (_hasMoreServers) {
      return await fetchServers(page: _currentPage + 1, perPage: perPage);
    }
    return false;
  }

  Future<RemoteServer?> getServer(int id) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.get(
        Uri.parse('${authManager.baseUrl}/api/remote-servers/$id'),
        headers: authManager.headers,
      );

      _recordRequest();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return RemoteServer.fromJson(jsonResponse['data']);
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return getServer(id);
      } else {
        throw Exception('Failed to get server: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Get server error: $e');
      }
      return null;
    }
  }

  Future<RemoteServer?> createServer(Map<String, dynamic> serverData) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.post(
        Uri.parse('${authManager.baseUrl}/api/remote-servers'),
        headers: {...authManager.headers, 'Content-Type': 'application/json'},
        body: json.encode(serverData),
      );

      _recordRequest();

      if (response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        final newServer = RemoteServer.fromJson(jsonResponse['data']);
        _servers.add(newServer);
        notifyListeners();
        return newServer;
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return createServer(serverData);
      } else {
        throw Exception('Failed to create server: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Create server error: $e');
      }
      return null;
    }
  }

  Future<RemoteServer?> updateServer(int id, Map<String, dynamic> serverData) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.put(
        Uri.parse('${authManager.baseUrl}/api/remote-servers/$id'),
        headers: {...authManager.headers, 'Content-Type': 'application/json'},
        body: json.encode(serverData),
      );

      _recordRequest();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final updatedServer = RemoteServer.fromJson(jsonResponse['data']);
        final index = _servers.indexWhere((server) => server.id == id);
        if (index != -1) {
          _servers[index] = updatedServer;
          notifyListeners();
        }
        return updatedServer;
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return updateServer(id, serverData);
      } else {
        throw Exception('Failed to update server: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Update server error: $e');
      }
      return null;
    }
  }

  Future<bool> deleteServer(int id) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.delete(
        Uri.parse('${authManager.baseUrl}/api/remote-servers/$id'),
        headers: authManager.headers,
      );

      _recordRequest();

      if (response.statusCode == 204) {
        _servers.removeWhere((server) => server.id == id);
        notifyListeners();
        return true;
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return deleteServer(id);
      } else {
        throw Exception('Failed to delete server: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Delete server error: $e');
      }
      return false;
    }
  }

  void clearServers() {
    _servers.clear();
    _currentPage = 1;
    _totalPages = 1;
    _hasMoreServers = true;
    notifyListeners();
  }

  void refreshServers() {
    clearServers();
    fetchServers();
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