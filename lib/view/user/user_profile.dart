import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:thesisapp/component/alert_dialog.dart';
import 'package:thesisapp/component/button.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/component/component_profile.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/localization/language_provider.dart';
import 'package:thesisapp/model/user_detail.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/user_api.dart';
import 'package:thesisapp/view/signin_screen.dart';
import 'package:thesisapp/view/user/personal_information.dart';

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
      http.Response response;
      try {
        response = await http
            .post(
              Uri.parse(APILocalLoginUrl),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "student_id": authUser.student_id,
                "pwd": authUser.pwd,
              }),
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        response = await http.post(
          Uri.parse(APIStLoginKh),
          body: {'student_id': authUser.student_id, 'pwd': authUser.pwd},
        );
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final userData =
              (decoded['user_data'] as List?) ??
              (decoded['student_users'] as List?) ??
              (decoded['user'] != null ? [decoded['user']] : const []);
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
    super.initState();
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final profileImageUrl = (_userDetail?.profile_pic ?? '').trim();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
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
                            child: _isLoadingUser
                                ? const CircularProgressIndicator()
                                : null,
                          ),
                          SizedBox(height: 10),
                          Text(
                            _userDetail?.name_kh ?? "",
                            style: TextStyle(
                              fontFamily: 'SiemReap',
                              color: TextColor,
                              fontSize: fontTitle,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            _userDetail?.student_id ?? "",
                            style: TextStyle(
                              fontFamily: getFontFamily(context),
                              color: TextColor,
                              fontSize: fontTitle,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: Height20),
                  Text(
                    lang.translate('privacy'),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: fontAppBar,
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
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ComponentProfile(
                          image: 'assets/graduate.png',
                          title: lang.translate('account_information'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PersonalInformation(),
                              ),
                            );
                          },
                        ),
                        // ComponentProfile(
                        //   image: 'assets/graduate.png',
                        //   title: lang.translate('account_information'),
                        // ),
                      ],
                    ),
                  ),
                  SizedBox(height: Height20),
                  Text(
                    lang.translate('privacy'),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: fontAppBar,
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
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ComponentProfile(
                          image: 'assets/graduate.png',
                          title: lang.translate('account_information'),
                        ),
                        ComponentProfile(
                          image: 'assets/graduate.png',
                          title: lang.translate('change_language'),
                          onTap: () {
                            final languageProvider = context
                                .read<LanguageProvider>();

                            showDialog(
                              context: context,
                              builder: (dialogContext) => customizeAlertDialog(
                                context: dialogContext,
                                title: lang.translate('change_language'),
                                content: lang.translate(
                                  'change_language_message',
                                ),
                                cancelOnTap: () {
                                  languageProvider.changeLanguage('km');

                                  Navigator.pop(dialogContext);
                                },
                                onTap: () {
                                  languageProvider.changeLanguage('en');

                                  Navigator.pop(dialogContext);
                                },
                                choice_1: lang.translate('khmer_language'),
                                choice_2: lang.translate('english_language'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Height40),
                  Button(
                    title: 'logout',
                    icon: 'assets/logout.png',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => customizeAlertDialog(
                          context: context,
                          title: lang.translate('logout'),
                          content: lang.translate('logout_message'),
                          choice_1: lang.translate('cancel'),
                          choice_2: lang.translate('confirm'),
                          cancelOnTap: () {
                            Navigator.pop(context);
                          },
                          onTap: () {
                            _logout(context);
                          },
                        ),
                      );
                    },
                  ),
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
