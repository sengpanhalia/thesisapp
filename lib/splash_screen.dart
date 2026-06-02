import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/view/main_screen.dart';
import 'package:thesisapp/view/onboard_screen.dart';
import 'package:thesisapp/view/signin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _logoOpacity = 0.0;
  double _textOpacity = 0.0;
  double _logoScale = 0.5;

  @override
  void initState() {
    super.initState();
    _startAnimation();
    _navigateAfterDelay();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      _logoOpacity = 1.0;
      _logoScale = 1.0;
    });

    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    setState(() {
      _textOpacity = 1.0;
    });
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.initialized;

    if (!mounted) return;

    if (authProvider.isFirstTime) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else if (authProvider.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SigninScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: gradientColor(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 800),
                    opacity: _logoOpacity,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.5, end: _logoScale),
                      duration: const Duration(milliseconds: 1600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Hero(
                        tag: "app_logo",
                        child: Image.asset('assets/logo_app.png', width: 220),
                      ),
                    ),
                  ),

                  const SizedBox(height: Height15),

                  AnimatedOpacity(
                    opacity: _textOpacity,
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeIn,
                    child: Column(
                      children: [
                        Text(
                          "សាកលវិទ្យាល័យ សៅស៍អ៊ីសថ៍អេសៀ",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontFamily: 'KhmerMool1',
                            color: TextColor,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "University of South-East Asia",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            letterSpacing: 1.2,
                            fontFamily: UEFontFamily,
                            fontWeight: FontWeight.w600,
                            color: TextColor,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "សូមស្វាគមន៍",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            // letterSpacing: 1,
                            fontFamily: 'KhmerMool1',
                            // fontWeight: FontWeight.w600,
                            color: TextColor,
                          ),
                        ),

                        Text(
                          "3",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            // letterSpacing: 1.2,
                            fontFamily: 'tacteng',
                            // fontWeight: FontWeight.w600,
                            color: TextColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
