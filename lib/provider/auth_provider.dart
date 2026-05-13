import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesisapp/model/user.dart';

class AuthProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  late final Future<void> _initFuture;

  bool _isFirstTime = true;
  bool _isLoggedIn = false;
  bool _isLoading = true;
  User? _user;

  bool get isFirstTime => _isFirstTime;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  User? get user => _user;

  AuthProvider() {
    _initFuture = _init();
  }

  Future<void> get initialized => _initFuture;

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
          await _prefs.setBool('isLoggedIn', false);
        }
      } else {
        _isLoggedIn = false;
        await _prefs.setBool('isLoggedIn', false);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setFirstTimeDone() async {
    await initialized;
    _isFirstTime = false;
    await _prefs.setBool('isFirstTime', false);
    notifyListeners();
  }

  Future<void> login(User user) async {
    await initialized;
    _isLoggedIn = true;
    _user = user;
    await _prefs.setBool('isLoggedIn', true);
    await _prefs.setString('user', jsonEncode(user.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    await initialized;
    _isLoggedIn = false;
    _user = null;
    await _prefs.setBool('isLoggedIn', false);
    await _prefs.remove('user');
    notifyListeners();
  }

  Future<void> updateUserInfo({
    String? student_id,
    String? name_kh,
    String? pwd,
  }) async {
    await initialized;

    // if (_user != null) {
    //   _user = User(
    //     student_id: _user!.student_id,
    //     fullname: fullname ?? _user!.fullname,
    //     username: username ?? _user!.username,
    //     // email: email ?? _user!.email,
    //     role: _user!.role,
    //     image: image ?? _user!.image,
    //   );
    //   await _prefs.setString('user', jsonEncode(_user!.toJson()));
    //   notifyListeners();
    // }
    if(_user != null){
      _user = User(name_kh: _user!.name_kh, student_id: _user!.student_id, pwd: _user!.pwd);
    }
  }
}
