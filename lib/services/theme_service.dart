import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();

  factory ThemeService() {
    return _instance;
  }

  ThemeService._internal();

  late SharedPreferences _prefs;
  bool _isDarkMode = true;

  // ValueNotifier لإعادة بناء الواجهة عند تغيير الموضوع
  late ValueNotifier<bool> _themeNotifier;

  /// Initialize theme service (must be called before usage)
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool('isDarkMode') ?? true;
    _themeNotifier = ValueNotifier(_isDarkMode);
  }

  bool get isDarkMode => _isDarkMode;

  ValueNotifier<bool> get themeNotifier => _themeNotifier;

  Future<void> setDarkMode(bool isDark) async {
    // Update UI immediately without waiting for async operations
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      _themeNotifier.value = isDark;
    }

    // Save to preferences in the background (non-blocking)
    try {
      await _prefs.setBool('isDarkMode', isDark);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  ThemeData getTheme() {
    if (_isDarkMode) {
      return ThemeData.dark().copyWith(
        primaryColor: const Color.fromARGB(255, 156, 121, 5),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
        cardColor: const Color(0xFF1E1E1E),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
      );
    } else {
      return ThemeData.light().copyWith(
        primaryColor: const Color.fromARGB(255, 156, 121, 5),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F5F5),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        cardColor: const Color(0xFFF5F5F5),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: Colors.black,
              displayColor: Colors.black,
            ),
      );
    }
  }
}
