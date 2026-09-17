import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/component/navigation_provider.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/model/user.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/service/api_client.dart';
import 'package:thesisapp/service/inventory_api.dart';
import 'package:thesisapp/service/notification_service.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/view/main_screen.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final InventoryApi _api = InventoryApi();

  bool _isSigningIn = false;

  /// Signing in is one call now.
  ///
  /// `POST /api/v1/student_login.php` checks the number and password against
  /// the university's own `student_users` table — through this system's API,
  /// so the app never posts a password to `api.usea.edu.kh` any more — and
  /// hands back a signed session and the student's record in one answer. The
  /// session is saved inside [InventoryApi.studentLogin]; the app holds it, not
  /// the password, from here on.
  ///
  /// The old second step (confirming the number in the inventory system) is
  /// gone because the login endpoint already does it: it will not issue a
  /// session for a number that is not a currently enrolled student.
  Future<void> login() async {
    final lang = AppLocalizations.of(context)!;
    final studentId = _usernameController.text.trim();
    final password = _passwordController.text;

    if (studentId.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(msg: lang.translate('please_fill_all_fields'));
      return;
    }

    setState(() => _isSigningIn = true);

    try {
      final result = await _api.studentLogin(
        studentId: studentId,
        password: password,
      );

      if (!mounted) return;

      final detail = result.profile;

      final user = User(
        name_kh: detail.name_kh,
        name_en: detail.name_en,
        student_id: detail.student_id.isNotEmpty
            ? detail.student_id
            : studentId,
        // The session is what authenticates the app now; the password is kept
        // only so the profile screens have something non-empty to persist.
        pwd: password,
      );

      final prefs = await SharedPreferences.getInstance();
      await saveStudentUser(prefs, [user]);

      if (!mounted) return;
      await context.read<AuthProvider>().login(user);

      /*
       * Tell the server where to deliver this student's notifications.
       *
       * Here rather than in NotificationService.initialize(), which runs at
       * startup when there is usually no session yet: the endpoint reads the
       * student out of the signed session, so a handset can only be registered
       * once somebody is signed in on it.
       *
       * Not awaited — it is a background courtesy and never a reason to keep a
       * student waiting on the sign-in screen — and it cannot throw, so a
       * failure costs the push and nothing else.
       */
      unawaited(NotificationService.registerWithServer());
      unawaited(NotificationService.fetchUnreadCount());

      // The shared-default-password notice is intentionally not shown in
      // production: the shared credential is a known, accepted situation, so
      // warning every student about it on each sign-in is only noise.
      // (result.passwordIsSharedDefault still arrives from the server if ever
      // needed again.)

      if (!mounted) return;
      _openHome();
    } on ApiException catch (error) {
      if (!mounted) return;

      /*
       * No key branch here any more, deliberately.
       *
       * Signing in needs no bearer token at all: student_login.php takes a
       * student number and a password, exactly as the university's old store
       * API did. Offering a student a "paste the key the book office issued"
       * dialog was asking them for something they can never have — the key is
       * created by an administrator in the web application and shown once.
       *
       * ApiClient no longer raises noToken either; it sends whichever
       * credentials the phone actually holds and lets the server decide.
       */

      // 403 here is "the password was right but you are not currently
      // enrolled" — the server explains it, so show that. 401 is the generic
      // wrong-number-or-password. Everything else is the app's own wording.
      final message = switch (error.kind) {
        ApiErrorKind.unauthorized => lang.translate('login_failed'),
        ApiErrorKind.forbidden => error.message(lang),
        _ => error.message(lang),
      };

      Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_LONG);
    } catch (error) {
      /*
       * The last resort, and it exists because its absence was the bug.
       *
       * Only `ApiException` was caught here. Anything else — a storage error
       * reading the saved session, a platform channel refusing, a decode this
       * screen did not expect — left the handler as an unhandled async error.
       * `finally` still stopped the spinner, so the button un-pressed itself,
       * no message appeared anywhere, and the user was left on the sign-in
       * screen with no idea whether the app had even tried.
       *
       * Showing the raw error is not pretty. It is far better than showing
       * nothing: it can be read out over a telephone, and it is the
       * difference between a bug somebody can report and one they can only
       * describe as "it does not work".
       */
      if (!mounted) return;

      Fluttertoast.showToast(
        msg: '${lang.translate('login_failed')} — $error',
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
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
            padding: const EdgeInsets.symmetric(vertical: Height30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/logo_app.png', height: 150),
                const SizedBox(height: 20),
                Text(
                  'សាកលវិទ្យាល័យ សៅស៍អុីសថ៍អេយសៀ',
                  style: TextStyle(
                    fontSize: fontAppBar,
                    fontFamily: 'KhmerMool1',
                    color: TextColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'University of South-East Asia',
                  style: TextStyle(
                    fontSize: fontAppBar,
                    letterSpacing: 1.5,
                    color: TextColor,
                    fontFamily: UEFontFamily,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'សូមស្វាគមន៍',
                  style: TextStyle(
                    fontSize: fontAppBar,
                    fontFamily: 'KhmerMool1',
                    color: TextColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '3',
                  style: TextStyle(
                    fontSize: fontAppBar,
                    fontFamily: 'tacteng',
                    fontWeight: FontWeight.w500,
                    color: TextColor,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: MediaQuery.of(context).size.width * 0.80,
                  decoration: BoxDecoration(
                    color: CardColor,
                    borderRadius: BorderRadius.circular(Round20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
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
                            fontSize: fontTitle,
                            color: TextColor,
                            fontFamily: getFontFamily(context),
                          ),
                        ),
                        const SizedBox(height: Height5),
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: MgPd10,
                              vertical: MgPd15,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                        const SizedBox(height: Height10),
                        Text(
                          "លេខកូដសម្ងាត់",
                          style: TextStyle(
                            fontSize: fontTitle,
                            color: TextColor,
                            fontFamily: getFontFamily(context),
                          ),
                        ),
                        const SizedBox(height: Height5),
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: MgPd10,
                              vertical: MgPd15,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                        const SizedBox(height: Height30),
                        AppButton(
                          title: 'ចូលគណនី',
                          onTap: () {
                            // Guarded rather than disabled: two taps must
                            // not start two sign-ins.
                            if (_isSigningIn) return;
                            login();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
