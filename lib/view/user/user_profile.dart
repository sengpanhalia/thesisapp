import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:thesisapp/component/button.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/component/component_profile.dart';
import 'package:thesisapp/model/user_detail.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/user_api.dart';
import 'package:thesisapp/view/signin_screen.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  UserDetail? _userDetail;
  bool _isLoadingUser = true;
  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SigninScreen()),
      (route) => false,
    );
  }

  Future<void> _fetchUserData() async {
    final authUser = context.read<AuthProvider>().user;
    if (authUser == null) {
      if (!mounted) return;
      setState(() => _isLoadingUser = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(APIStLoginKh),
        body: {'student_id': authUser.student_id, 'pwd': authUser.pwd},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final userData =
              (decoded['user_data'] as List?) ??
              (decoded['student_users'] as List?) ??
              const [];
          final details = userData
              .whereType<Map<String, dynamic>>()
              .map(UserDetail.fromJson)
              .toList();

          if (!mounted) return;
          setState(() {
            _userDetail = details.isNotEmpty ? details.first : null;
            _isLoadingUser = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to load user detail: $e');
    }

    if (!mounted) return;
    setState(() => _isLoadingUser = false);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final profileImageUrl = (_userDetail?.profile_pic ?? '').trim();
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // Matching the warm gradient from your design
          gradient: gradientColor(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: MgPd20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: Height20),
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Height70,
                        vertical: Height15,
                      ),
                      decoration: BoxDecoration(
                        color: CardColor,
                        border: Border.all(color: WhiteColor, width: 1.5),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: BlackColor.withOpacity(0.2),
                            blurRadius: 4.0,
                            // spreadRadius: 1.0,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: profileImageUrl.isNotEmpty
                                ? CachedNetworkImageProvider(profileImageUrl)
                                : null,
                          ),
                          SizedBox(height: 10),
                          Text(
                            _userDetail?.name_kh ?? "",
                            style: TextStyle(
                              fontFamily: UKFontFamily,
                              color: TextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            _userDetail?.student_id ?? "",
                            style: TextStyle(
                              fontFamily: UKFontFamily,
                              color: TextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: Height20),
                  Text(
                    "ឯកជនភាព",
                    style: TextStyle(
                      fontFamily: UKFontFamily,
                      fontSize: 20,
                      color: TextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Height15),
                  Container(
                    decoration: BoxDecoration(
                      color: CardColor,
                      border: Border.all(color: WhiteColor, width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: BlackColor.withOpacity(0.2),
                          blurRadius: 4.0,
                          // spreadRadius: 1.0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ComponentProfile(
                          image: 'assets/graduate.png',
                          title: "ព័ត៌មានគណនី",
                        ),
                        ComponentProfile(
                          image: 'assets/graduate.png',
                          title: "ព័ត៌មានគណនី",
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Height20),
                  Text(
                    "ឯកជនភាព",
                    style: TextStyle(
                      fontFamily: UKFontFamily,
                      fontSize: 20,
                      color: TextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Height15),

                  Container(
                    decoration: BoxDecoration(
                      color: CardColor,
                      border: Border.all(color: WhiteColor, width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: BlackColor.withOpacity(0.2),
                          blurRadius: 4.0,
                          // spreadRadius: 1.0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ComponentProfile(
                          image: 'assets/graduate.png',
                          title: "ព័ត៌មានគណនី",
                        ),
                        ComponentProfile(
                          image: 'assets/graduate.png',
                          title: "ព័ត៌មានគណនី",
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Height40),
                  Button(title: "ចាកចេញ", icon: 'assets/logout.png'),
                  SizedBox(height: Height50),
                  Center(
                    child: Text(
                      "Version 1.0.0 by USEA",
                      style: TextStyle(color: TextColor),
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
