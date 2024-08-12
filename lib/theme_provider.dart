import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themePreferenceKey = 'theme_preference';
  static const String _themeAutoKey = 'theme_auto';

  late bool _isDarkMode;
  late bool _isAuto;
  late SharedPreferences _prefs;

  ThemeProvider() {
    _loadPreferences();
  }

  bool get isDarkMode => _isDarkMode;
  bool get isAuto => _isAuto;

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _isAuto = _prefs.getBool(_themeAutoKey) ?? true;

    if (_isAuto) {
      var brightness = SchedulerBinding.instance.window.platformBrightness;
      _isDarkMode = brightness == Brightness.dark;
    } else {
      _isDarkMode = _prefs.getBool(_themePreferenceKey) ?? true;
    }

    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _isAuto = false;
    _savePreferences();
    notifyListeners();
  }

  void setAutoTheme(bool value) {
    _isAuto = value;
    if (_isAuto) {
      var brightness = SchedulerBinding.instance.window.platformBrightness;
      _isDarkMode = brightness == Brightness.dark;
    }
    _savePreferences();
    notifyListeners();
  }

  void _savePreferences() {
    _prefs.setBool(_themePreferenceKey, _isDarkMode);
    _prefs.setBool(_themeAutoKey, _isAuto);
  }

  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.black,
    cardColor: Colors.grey[900],
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Poppins', color: Colors.white70),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: Colors.white70,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.white10,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white30),
    ),
  );

  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.white,
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.grey[100],
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black),
      titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500, color: Colors.black),
      bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Poppins', color: Colors.black87),
    ),
    colorScheme: const ColorScheme.light(
      primary: Colors.black,
      secondary: Colors.black87,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.black.withOpacity(0.1),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.black87),
      hintStyle: const TextStyle(color: Colors.black54),
    ),
  );
}