import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthManager {
  late SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _token;
  String? _baseUrl;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _baseUrl = _prefs.getString('api_base_url');
    _token = await _secureStorage.read(key: 'auth_token');
  }

  bool get isLoggedIn => _token != null;

  String? get token => _token;

  String? get baseUrl => _baseUrl;

  Map<String, String> get headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    await _prefs.setString('api_base_url', url);
  }

  Future<void> login(String token) async {
    _token = token;
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  Future<void> logout() async {
    _token = null;
    await _secureStorage.delete(key: 'auth_token');
  }
}