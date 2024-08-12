import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'backup_destination_model.dart';
import 'auth_manager.dart';

class BackupDestinationProvider with ChangeNotifier {
  final List<BackupDestination> _destinations = [];
  List<BackupDestination> get destinations => _destinations;
  final AuthManager authManager;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreDestinations = true;
  bool get hasMoreDestinations => _hasMoreDestinations;

  // Rate limiting variables
  final int _maxRequestsPerMinute = 60;
  final Duration _rateLimitWindow = const Duration(minutes: 1);
  final List<DateTime> _requestTimestamps = [];

  BackupDestinationProvider({required this.authManager});

  Future<bool> fetchDestinations({int page = 1, int perPage = 15}) async {
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

      final uri = Uri.parse('${authManager.baseUrl}/api/backup-destinations')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: authManager.headers,
      );

      _recordRequest();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['data'] is List) {
          final newDestinations = (jsonResponse['data'] as List)
              .map<BackupDestination>((destJson) => BackupDestination.fromJson(destJson))
              .toList();

          if (page == 1) {
            _destinations.clear();
          }
          _destinations.addAll(newDestinations);

          _currentPage = jsonResponse['meta']['current_page'];
          _totalPages = jsonResponse['meta']['last_page'];
          _hasMoreDestinations = _currentPage < _totalPages;

          notifyListeners();
          return true;
        } else {
          throw Exception('Invalid destinations data format');
        }
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return fetchDestinations(page: page, perPage: perPage);
      } else {
        throw Exception('Failed to load destinations: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fetch destinations error: $e');
      }
      return false;
    }
  }

  Future<bool> loadMoreDestinations({int perPage = 15}) async {
    if (_hasMoreDestinations) {
      return await fetchDestinations(page: _currentPage + 1, perPage: perPage);
    }
    return false;
  }

  Future<BackupDestination?> getDestination(int id) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.get(
        Uri.parse('${authManager.baseUrl}/api/backup-destinations/$id'),
        headers: authManager.headers,
      );

      _recordRequest();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return BackupDestination.fromJson(jsonResponse['data']);
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return getDestination(id);
      } else {
        throw Exception('Failed to get destination: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Get destination error: $e');
      }
      return null;
    }
  }

  Future<BackupDestination?> createDestination(Map<String, dynamic> destinationData) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.post(
        Uri.parse('${authManager.baseUrl}/api/backup-destinations'),
        headers: {...authManager.headers, 'Content-Type': 'application/json'},
        body: json.encode(destinationData),
      );

      _recordRequest();

      if (response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        final newDestination = BackupDestination.fromJson(jsonResponse['data']);
        _destinations.add(newDestination);
        notifyListeners();
        return newDestination;
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return createDestination(destinationData);
      } else {
        throw Exception('Failed to create destination: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Create destination error: $e');
      }
      return null;
    }
  }

  Future<BackupDestination?> updateDestination(int id, Map<String, dynamic> destinationData) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.put(
        Uri.parse('${authManager.baseUrl}/api/backup-destinations/$id'),
        headers: {...authManager.headers, 'Content-Type': 'application/json'},
        body: json.encode(destinationData),
      );

      _recordRequest();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final updatedDestination = BackupDestination.fromJson(jsonResponse['data']);
        final index = _destinations.indexWhere((dest) => dest.id == id);
        if (index != -1) {
          _destinations[index] = updatedDestination;
          notifyListeners();
        }
        return updatedDestination;
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return updateDestination(id, destinationData);
      } else {
        throw Exception('Failed to update destination: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Update destination error: $e');
      }
      return null;
    }
  }

  Future<bool> deleteDestination(int id) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.delete(
        Uri.parse('${authManager.baseUrl}/api/backup-destinations/$id'),
        headers: authManager.headers,
      );

      _recordRequest();

      if (response.statusCode == 204) {
        _destinations.removeWhere((dest) => dest.id == id);
        notifyListeners();
        return true;
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return deleteDestination(id);
      } else {
        throw Exception('Failed to delete destination: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Delete destination error: $e');
      }
      return false;
    }
  }

  void clearDestinations() {
    _destinations.clear();
    _currentPage = 1;
    _totalPages = 1;
    _hasMoreDestinations = true;
    notifyListeners();
  }

  void refreshDestinations() {
    clearDestinations();
    fetchDestinations();
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