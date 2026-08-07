import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/component/navigation_provider.dart';
import 'package:thesisapp/model/user.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/service/notification_service.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/user_api.dart';
import 'package:thesisapp/view/main_screen.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  static const String _localAdminId = 'admin';
  static const String _localAdminPassword = 'admin123';

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> login() async {
    final studentId = _usernameController.text.trim();
    final password = _passwordController.text;

    // Basic validation
    if (studentId.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill all fields");
      return;
    }

    try {
      if (_isLocalAdminId(studentId)) {
        if (!_isLocalAdminLogin(studentId, password)) {
          Fluttertoast.showToast(msg: "Invalid admin password");
          return;
        }

        final admin = User(
          name_kh: 'admin',
          name_en: 'admin',
          student_id: studentId,
          pwd: password,
          role: 'admin',
        );

        if (!mounted) return;
        await context.read<AuthProvider>().login(admin);

        if (!mounted) return;
        _openHome();
        return;
      }

      // Fetch FCM Token for push notifications
      final fcmToken = await NotificationService.getFcmToken();

      // Call the local PHP API which handles USEA login + DB sync
      var response = await http
          .post(
            Uri.parse(APILocalLoginUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "student_id": studentId,
              "pwd": password,
              "fcm_token": fcmToken ?? "",
            }),
          )
          .timeout(const Duration(seconds: 30));

      // Debug: print raw response (remove in production)
      debugPrint('Login response: ${response.body}');

      if (response.statusCode != 200) {
        Fluttertoast.showToast(msg: "Server error: ${response.statusCode}");
        return;
      }

      final data = jsonDecode(response.body);

      if (data == null || data['status'] != true) {
        final errorMsg = data?['message']?.toString() ?? 'Login failed';
        Fluttertoast.showToast(msg: errorMsg);
        return;
      }

      // Get user data from the API response
      final apiUser = data['user'];
      final localUser = data['local_user'];

      final user = User(
        name_kh: apiUser?['name_kh']?.toString() ?? localUser?['fullname']?.toString() ?? '',
        student_id: apiUser?['student_id']?.toString() ?? localUser?['username']?.toString() ?? studentId,
        pwd: password,
        role: (localUser?['role'] ?? 'user').toString(), 
        name_en: apiUser?['name_en']?.toString() ?? localUser?['fullname']?.toString() ?? '',
      );

      // Save to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await saveStudentUser(prefs, [user]);

      if (!mounted) return;
      await context.read<AuthProvider>().login(user);

      if (!mounted) return;
      _openHome();
    } on TimeoutException {
      debugPrint('Login failed: server timeout');
      Fluttertoast.showToast(msg: "Login server timeout. Please try again.");
    } catch (e) {
      debugPrint('Login failed: $e');
      Fluttertoast.showToast(
        msg: "Cannot connect to login server. Please try again later.",
      );
    }
  }

  bool _isLocalAdminId(String studentId) {
    return studentId.toLowerCase() == _localAdminId;
  }

  bool _isLocalAdminLogin(String studentId, String password) {
    return _isLocalAdminId(studentId) && password == _localAdminPassword;
  }

  void _openHome() {
    context.read<NavigationProvider>().setIndex(0);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  Future<void> saveStudentUser(
    SharedPreferences sharedPreferences,
    List<User> studentUserList,
  ) async {
    final jsonData = studentUserList
        .map((studentUser) => studentUser.toJson())
        .toList();
    await sharedPreferences.setString('student_user', json.encode(jsonData));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: gradientColor(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: Height30),
              child: Column(
                children: [
                  // SizedBox(height: 100),
                  Image.asset('assets/logo_app.png', height: 150),
                  SizedBox(height: 20),
                  Text(
                    'សាកលវិទ្យាល័យ សៅស៍អុីសថ៍អេយសៀ',
                    style: TextStyle(
                      fontSize: 22,
                      fontFamily: 'KhmerMool1',
                      color: TextColor,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'University of South-East Asia',
                    style: TextStyle(
                      fontSize: 22,
                      letterSpacing: 1.5,
                      color: TextColor,
                      fontFamily: UEFontFamily,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'សូមស្វាគមន៍',
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'KhmerMool1',
                      color: TextColor,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '3',
                    style: TextStyle(
                      fontSize: 26,
                      fontFamily: 'tacteng',
                      fontWeight: FontWeight.w500,
                      color: TextColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.80,
                    decoration: BoxDecoration(
                      color: CardColor,
                      borderRadius: BorderRadius.circular(Round20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(MgPd20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "អត្តលេខនិស្សិត",
                            style: TextStyle(
                              fontSize: 16,
                              color: TextColor,
                              fontFamily: getFontFamily(context),
                            ),
                          ),
                          SizedBox(height: Height5),
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              hintText: 'អត្តលេខនិស្សិត',
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Round15),
                                borderSide: BorderSide(
                                  color: StrokeColor,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Round15),
                                borderSide: BorderSide(
                                  color: StrokeColor,
                                  width: 1,
                                ),
                              ),
                              hintStyle: TextStyle(
                                color: TextSoftColor,
                                fontFamily: getFontFamily(context),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: MgPd10,
                                vertical: MgPd15,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                          SizedBox(height: Height10),
                          Text(
                            "លេខកូដសម្ងាត់",
                            style: TextStyle(
                              fontSize: 16,
                              color: TextColor,
                              fontFamily: getFontFamily(context),
                            ),
                          ),
                          SizedBox(height: Height5),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Round15),
                                borderSide: BorderSide(
                                  color: StrokeColor,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Round15),
                                borderSide: BorderSide(
                                  color: StrokeColor,
                                  width: 1,
                                ),
                              ),
                              hintText: 'លេខកូដសម្ងាត់',
                              hintStyle: TextStyle(
                                color: TextSoftColor,
                                fontFamily: getFontFamily(context),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: MgPd10,
                                vertical: MgPd15,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                          SizedBox(height: Height30),
                          AppButton(title: 'ចូលគណនី', onTap: login),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
