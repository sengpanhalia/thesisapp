import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  final _key = 'isDarkMode';
  bool _isDarkMode = false;
  bool _initialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get initialized => _initialized;

  ThemeMode get theme => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool(_key) ?? false;
    _initialized = true;
    notifyListeners();
  }

  Future<void> saveTheme(bool isDarkMode) async {
    await _prefs.setBool(_key, isDarkMode);
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    saveTheme(_isDarkMode);
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    saveTheme(_isDarkMode);
    notifyListeners();
  }
}