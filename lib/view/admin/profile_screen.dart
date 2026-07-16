import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/view/signin_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SigninScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(MgPd20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              user?.name_kh.isNotEmpty == true ? user!.name_kh : 'User',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: TextColor,
                fontFamily: getFontFamily(context),
              ),
            ),
            const SizedBox(height: Height5),
            Text(
              user?.student_id ?? '',
              style: TextStyle(
                fontSize: 14,
                color: TextSoftColor,
                fontFamily: getFontFamily(context),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: IconOrangeColor,
                foregroundColor: WhiteColor,
                padding: const EdgeInsets.symmetric(vertical: MgPd15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Round15),
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: getFontFamily(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
