import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_model.dart';
import 'auth_manager.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  User? get user => _user;
  final AuthManager authManager;

  UserProvider({required this.authManager});

  Future<bool> login(String email, String password) async {
    if (authManager.baseUrl == null) {
      throw Exception('API base URL not set');
    }

    try {
      final response = await http.post(
        Uri.parse('${authManager.baseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('token')) {
          await authManager.login(jsonResponse['token']);
          return true;
        } else {
          throw Exception('Invalid login response format');
        }
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> fetchUser() async {
    if (!authManager.isLoggedIn) {
      throw Exception('Not logged in');
    }

    try {
      final response = await http.get(
        Uri.parse('${authManager.baseUrl}/api/user'),
        headers: authManager.headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('data')) {
          _user = User.fromJson(jsonResponse);
          notifyListeners();
          return true;
        } else {
          throw Exception('Invalid user data format');
        }
      } else {
        throw Exception('Failed to load user data: ${response.statusCode}');
      }
    } catch (e) {
      print('Fetch user error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await authManager.logout();
    _user = null;
    notifyListeners();
  }
}