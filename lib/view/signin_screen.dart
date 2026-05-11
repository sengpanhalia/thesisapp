import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/component/navigation_provider.dart';
import 'package:thesisapp/model/user.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/util/api_config.dart';
import 'package:thesisapp/view/admin/home_screen.dart';
import 'package:thesisapp/view/main_screen.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> login() async {
    // Basic validation
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill all fields");
      return;
    }

    final Uri url = Uri.parse('${ApiConfig.baseUrl}/login.php');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _usernameController.text.trim(),
          "password": _passwordController.text,
        }),
      );

      // Debug: print raw response (remove in production)
      debugPrint('Login response: ${response.body}');

      if (response.statusCode != 200) {
        Fluttertoast.showToast(msg: "Server error: ${response.statusCode}");
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        Fluttertoast.showToast(msg: "Invalid server response");
        return;
      }

      final data = decoded;
      if (data["status"] != "success") {
        Fluttertoast.showToast(
          msg: data["message"]?.toString() ?? "Login failed",
        );
        return;
      }

      final userPayload = data['user'];
      final Map<String, dynamic> userMap = userPayload is Map
          ? Map<String, dynamic>.from(userPayload)
          : data;

      final dynamic rawId =
          userMap['user_id'] ?? userMap['id'] ?? data['user_id'] ?? data['id'];
      final int userId = int.tryParse(rawId?.toString() ?? '') ?? 0;
      if (userId <= 0) {
        Fluttertoast.showToast(msg: "Login succeeded but user id is missing");
        return;
      }

      final user = User(
        id: userId,
        username: (userMap['username'] ?? data['username'] ?? '').toString(),
        email: (userMap['email'] ?? data['email'])?.toString(),
        fullname: (userMap['fullname'] ?? data['fullname'] ?? '').toString(),
        role: (userMap['role'] ?? data['role'] ?? 'user').toString(),
        image: (userMap['image'] ?? data['image'])?.toString(),
      );

      // Save to AuthProvider
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      await authProvider.login(user);

      if (!mounted) return;

      context.read<NavigationProvider>().setIndex(0);

      // Navigate based on role
      if (user.isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      debugPrint('Login failed: $e');
      Fluttertoast.showToast(msg: "Login failed: $e");
    }
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
              padding: const EdgeInsets.only(top: Height20),
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
                              fontFamily: UKFontFamily,
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
                                fontFamily: UKFontFamily,
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
                              fontFamily: UKFontFamily,
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
                                fontFamily: UKFontFamily,
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
