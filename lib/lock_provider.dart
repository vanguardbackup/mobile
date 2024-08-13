import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LockProvider with ChangeNotifier {
  bool _isLockEnabled = false;
  bool _isAppLocked = false;
  bool _useBiometrics = false;
  String? _pin;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  DateTime? _lastActiveTime;
  int _lockDurationMinutes = 1;

  bool get isLockEnabled => _isLockEnabled;
  bool get isAppLocked => _isAppLocked;
  bool get useBiometrics => _useBiometrics;
  bool get hasPIN => _pin != null;
  int get lockDurationMinutes => _lockDurationMinutes;

  LockProvider() {
    _loadLockSettings();
  }

  Future<void> _loadLockSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isLockEnabled = prefs.getBool('isLockEnabled') ?? false;
    _useBiometrics = prefs.getBool('useBiometrics') ?? false;
    _lockDurationMinutes = prefs.getInt('lockDurationMinutes') ?? 1;
    _pin = await _secureStorage.read(key: 'pin');
    if (_isLockEnabled) {
      lockApp();
    }
    notifyListeners();
  }

  Future<void> toggleLock(bool value) async {
    _isLockEnabled = value;
    if (value) {
      lockApp();
    } else {
      unlockApp();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLockEnabled', value);
    notifyListeners();
  }

  Future<void> toggleBiometrics(bool value) async {
    _useBiometrics = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useBiometrics', value);
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    _pin = pin;
    await _secureStorage.write(key: 'pin', value: pin);
    notifyListeners();
  }

  Future<Map<String, dynamic>> authenticateUser() async {
    if (_useBiometrics) {
      try {
        final canCheckBiometrics = await _localAuth.canCheckBiometrics;
        final isDeviceSupported = await _localAuth.isDeviceSupported();

        if (canCheckBiometrics && isDeviceSupported) {
          final didAuthenticate = await _localAuth.authenticate(
            localizedReason: 'Please authenticate to use the app',
            options: const AuthenticationOptions(biometricOnly: true),
          );
          if (didAuthenticate) {
            unlockApp();
            return {'success': true, 'message': 'Authentication successful'};
          } else {
            return {'success': false, 'message': 'Authentication failed'};
          }
        } else {
          return {
            'success': false,
            'message':
                'Biometric authentication is not available on this device'
          };
        }
      } on PlatformException catch (e) {
        return {'success': false, 'message': 'Error: ${e.message}'};
      }
    }
    // If biometrics are not used, return false and let the UI handle PIN entry
    return {'success': false, 'message': 'PIN authentication required'};
  }

  Future<bool> checkPin(String enteredPin) async {
    final storedPin = await _secureStorage.read(key: 'pin');
    return storedPin == enteredPin;
  }

  void lockApp() {
    _isAppLocked = true;
    notifyListeners();
  }

  void unlockApp() {
    _isAppLocked = false;
    _lastActiveTime = DateTime.now();
    notifyListeners();
  }

  void updateLastActiveTime() {
    _lastActiveTime = DateTime.now();
  }

  Future<bool> shouldLockApp() async {
    if (!_isLockEnabled) return false;
    if (_lastActiveTime == null) return true;

    final difference = DateTime.now().difference(_lastActiveTime!);
    return difference.inMinutes >= _lockDurationMinutes;
  }

  Future<void> setLockDuration(int minutes) async {
    _lockDurationMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lockDurationMinutes', minutes);
    notifyListeners();
  }
}
