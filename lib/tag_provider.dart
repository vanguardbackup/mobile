import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'tag_model.dart';
import 'auth_manager.dart';

class TagProvider with ChangeNotifier {
  final List<Tag> _tags = [];
  List<Tag> get tags => _tags;
  final AuthManager authManager;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreTags = true;
  bool get hasMoreTags => _hasMoreTags;

  // Rate limiting variables
  final int _maxRequestsPerMinute = 60;
  final Duration _rateLimitWindow = const Duration(minutes: 1);
  final List<DateTime> _requestTimestamps = [];

  TagProvider({required this.authManager});

  Future<bool> fetchTags({int page = 1, int perPage = 15}) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final uri = Uri.parse('${authManager.baseUrl}/api/tags')
          .replace(queryParameters: {'page': page.toString(), 'per_page': perPage.toString()});

      final response = await http.get(
        uri,
        headers: authManager.headers,
      );

      _recordRequest();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['data'] is List) {
          final newTags = (jsonResponse['data'] as List)
              .map<Tag>((tagJson) => Tag.fromJson(tagJson))
              .toList();

          if (page == 1) {
            _tags.clear();
          }
          _tags.addAll(newTags);

          _currentPage = jsonResponse['meta']['current_page'];
          _totalPages = jsonResponse['meta']['last_page'];
          _hasMoreTags = _currentPage < _totalPages;

          notifyListeners();
          return true;
        } else {
          throw Exception('Invalid tags data format');
        }
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return fetchTags(page: page, perPage: perPage);
      } else {
        throw Exception('Failed to load tags: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fetch tags error: $e');
      }
      return false;
    }
  }

  Future<bool> loadMoreTags({int perPage = 15}) async {
    if (_hasMoreTags) {
      return await fetchTags(page: _currentPage + 1, perPage: perPage);
    }
    return false;
  }

  Future<Tag?> createTag(String label, {String? description}) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.post(
        Uri.parse('${authManager.baseUrl}/api/tags'),
        headers: {...authManager.headers, 'Content-Type': 'application/json'},
        body: json.encode({
          'label': label,
          if (description != null) 'description': description,
        }),
      );

      _recordRequest();

      if (response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        final newTag = Tag.fromJson(jsonResponse['data']);
        _tags.add(newTag);
        notifyListeners();
        return newTag;
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return createTag(label, description: description);
      } else {
        throw Exception('Failed to create tag: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Create tag error: $e');
      }
      return null;
    }
  }

  Future<Tag?> getTag(int id) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.get(
        Uri.parse('${authManager.baseUrl}/api/tags/$id'),
        headers: authManager.headers,
      );

      _recordRequest();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return Tag.fromJson(jsonResponse['data']);
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return getTag(id);
      } else {
        throw Exception('Failed to get tag: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Get tag error: $e');
      }
      return null;
    }
  }

  Future<Tag?> updateTag(int id, {String? label, String? description}) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.put(
        Uri.parse('${authManager.baseUrl}/api/tags/$id'),
        headers: {...authManager.headers, 'Content-Type': 'application/json'},
        body: json.encode({
          if (label != null) 'label': label,
          if (description != null) 'description': description,
        }),
      );

      _recordRequest();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final updatedTag = Tag.fromJson(jsonResponse['data']);
        final index = _tags.indexWhere((tag) => tag.id == id);
        if (index != -1) {
          _tags[index] = updatedTag;
          notifyListeners();
        }
        return updatedTag;
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return updateTag(id, label: label, description: description);
      } else {
        throw Exception('Failed to update tag: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Update tag error: $e');
      }
      return null;
    }
  }

  Future<bool> deleteTag(int id) async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    if (!_canMakeRequest()) {
      await _waitForNextAvailableSlot();
    }

    try {
      final response = await http.delete(
        Uri.parse('${authManager.baseUrl}/api/tags/$id'),
        headers: authManager.headers,
      );

      _recordRequest();

      if (response.statusCode == 200) {
        _tags.removeWhere((tag) => tag.id == id);
        notifyListeners();
        return true;
      } else if (response.statusCode == 429) {
        // Handle rate limit exceeded
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        await Future.delayed(Duration(seconds: retryAfter));
        return deleteTag(id);
      } else {
        throw Exception('Failed to delete tag: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Delete tag error: $e');
      }
      return false;
    }
  }

  void clearTags() {
    _tags.clear();
    _currentPage = 1;
    _totalPages = 1;
    _hasMoreTags = true;
    notifyListeners();
  }

  void refreshTags() {
    clearTags();
    fetchTags();
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