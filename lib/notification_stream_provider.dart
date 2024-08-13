import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'notification_stream_model.dart';
import 'auth_manager.dart';

class NotificationStreamProvider with ChangeNotifier {
  final List<NotificationStream> _streams = [];
  List<NotificationStream> get streams => _streams;
  final AuthManager authManager;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreStreams = true;
  bool get hasMoreStreams => _hasMoreStreams;

  // Rate limiting variables
  final int _maxRequestsPerMinute = 60;
  final Duration _rateLimitWindow = const Duration(minutes: 1);
  final List<DateTime> _requestTimestamps = [];

  NotificationStreamProvider({required this.authManager});

  Future<bool> fetchStreams({int page = 1, int perPage = 15}) async {
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

      final uri = Uri.parse('${authManager.baseUrl}/api/notification-streams')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: authManager.headers,
      );

      _recordRequest();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['data'] is List) {
          final newStreams = (jsonResponse['data'] as List)
              .map<NotificationStream>(
                  (streamJson) => NotificationStream.fromJson(streamJson))
              .toList();

          if (page == 1) {
            _streams.clear();
          }
          _streams.addAll(newStreams);

          _currentPage = jsonResponse['meta']['current_page'];
          _totalPages = jsonResponse['meta']['last_page'];
          _hasMoreStreams = _currentPage < _totalPages;

          notifyListeners();
          return true;
        } else {
          throw Exception('Invalid streams data format');
        }
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter =
            int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return fetchStreams(page: page, perPage: perPage);
      } else {
        throw Exception('Failed to load streams: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fetch streams error: $e');
      }
      return false;
    }
  }

  Future<bool> loadMoreStreams({int perPage = 15}) async {
    if (_hasMoreStreams) {
      return await fetchStreams(page: _currentPage + 1, perPage: perPage);
    }
    return false;
  }

  Future<NotificationStream?> getStream(int id) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.get(
        Uri.parse('${authManager.baseUrl}/api/notification-streams/$id'),
        headers: authManager.headers,
      );

      _recordRequest();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return NotificationStream.fromJson(jsonResponse['data']);
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter =
            int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return getStream(id);
      } else {
        throw Exception('Failed to get stream: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Get stream error: $e');
      }
      return null;
    }
  }

  Future<NotificationStream?> createStream(
      Map<String, dynamic> streamData) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.post(
        Uri.parse('${authManager.baseUrl}/api/notification-streams'),
        headers: {...authManager.headers, 'Content-Type': 'application/json'},
        body: json.encode(streamData),
      );

      _recordRequest();

      if (response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        final newStream = NotificationStream.fromJson(jsonResponse['data']);
        _streams.add(newStream);
        notifyListeners();
        return newStream;
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter =
            int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return createStream(streamData);
      } else {
        throw Exception('Failed to create stream: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Create stream error: $e');
      }
      return null;
    }
  }

  Future<NotificationStream?> updateStream(
      int id, Map<String, dynamic> streamData) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.put(
        Uri.parse('${authManager.baseUrl}/api/notification-streams/$id'),
        headers: {...authManager.headers, 'Content-Type': 'application/json'},
        body: json.encode(streamData),
      );

      _recordRequest();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final updatedStream = NotificationStream.fromJson(jsonResponse['data']);
        final index = _streams.indexWhere((stream) => stream.id == id);
        if (index != -1) {
          _streams[index] = updatedStream;
          notifyListeners();
        }
        return updatedStream;
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter =
            int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return updateStream(id, streamData);
      } else {
        throw Exception('Failed to update stream: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Update stream error: $e');
      }
      return null;
    }
  }

  Future<bool> deleteStream(int id) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.delete(
        Uri.parse('${authManager.baseUrl}/api/notification-streams/$id'),
        headers: authManager.headers,
      );

      _recordRequest();

      if (response.statusCode == 204) {
        _streams.removeWhere((stream) => stream.id == id);
        notifyListeners();
        return true;
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter =
            int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return deleteStream(id);
      } else {
        throw Exception('Failed to delete stream: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Delete stream error: $e');
      }
      return false;
    }
  }

  void clearStreams() {
    _streams.clear();
    _currentPage = 1;
    _totalPages = 1;
    _hasMoreStreams = true;
    notifyListeners();
  }

  void refreshStreams() {
    clearStreams();
    fetchStreams();
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
