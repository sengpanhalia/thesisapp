import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesisapp/model/user.dart';

class AuthProvider extends ChangeNotifier {
  late SharedPreferences _prefs;

  bool _isFirstTime = true;
  bool _isLoggedIn = false;
  bool _isLoading = true;
  User? _user;

  bool get isFirstTime => _isFirstTime;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  User? get user => _user;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      _isFirstTime = _prefs.getBool('isFirstTime') ?? true;
      _isLoggedIn = _prefs.getBool('isLoggedIn') ?? false;

      final userJson = _prefs.getString('user');
      if (userJson != null && userJson != 'null') {
        try {
          final Map<String, dynamic> map = jsonDecode(userJson);
          _user = User.fromJson(map);
        } catch (e) {
          // Corrupted data – clear it
          await _prefs.remove('user');
          _isLoggedIn = false;
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setFirstTimeDone() async {
    _isFirstTime = false;
    await _prefs.setBool('isFirstTime', false);
    notifyListeners();
  }

  Future<void> login(User user) async {
    _isLoggedIn = true;
    _user = user;
    await _prefs.setBool('isLoggedIn', true);
    await _prefs.setString('user', jsonEncode(user.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _user = null;
    await _prefs.setBool('isLoggedIn', false);
    await _prefs.remove('user');
    notifyListeners();
  }

  Future<void> updateUserInfo({
    String? fullname,
    String? username,
    String? email,
    String? image,
  }) async {
    if (_user != null) {
      _user = User(
        id: _user!.id,
        fullname: fullname ?? _user!.fullname,
        username: username ?? _user!.username,
        email: email ?? _user!.email,
        role: _user!.role,
        image: image ?? _user!.image,
      );
      await _prefs.setString('user', jsonEncode(_user!.toJson()));
      notifyListeners();
    }
  }
}
