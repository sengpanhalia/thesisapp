import 'package:flutter/material.dart';
import 'package:thesisapp/component/component_app.dart';
import 'dart:async';

import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/view/onboard_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _logoOpacity = 0.8;
  double _textOpacity = 0.0;
  double _logoScale = 0.0;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  _startAnimation() async {
    // Wait a moment before starting
    await Future.delayed(Duration(milliseconds: 800));

    setState(() {
      _logoOpacity = 1.0;
      _logoScale = 1.0; // This triggers the TweenAnimationBuilder to animate
    });

    // Wait for logo to finish popping, then show text
    await Future.delayed(Duration(milliseconds: 800));
    setState(() => _textOpacity = 1.0);

    // Final transition to onboarding
    await Future.delayed(Duration(seconds: 2));
    setState(() => _showOnboarding = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Matching the warm gradient from your design
          gradient: gradientColor(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        ),
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 800),
          child: _showOnboarding ? OnboardingScreen() : _buildSplash(),
        ),
      ),
    );
  }

  Widget _buildSplash() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 0.7,
            end: _logoScale,
          ), // Scale from 70% to 100%
          duration: Duration(milliseconds: 2000),
          curve: Curves.elasticOut, // This creates the "Pop/Bounce" feel
          builder: (context, value, child) {
            return Opacity(
              opacity: _logoOpacity,
              child: Transform.scale(scale: value, child: child),
            );
          },
          child: Image.asset('assets/logo_app.png', width: 300),
        ),
        SizedBox(height: 30),
        // University Name Text
        AnimatedOpacity(
          opacity: _textOpacity,
          duration: Duration(milliseconds: 800),
          child: Column(
            children: [
              Text(
                "សាកលវិទ្យាល័យ សៅស៍អ៊ីសថ៍អេសៀ",
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'KhmerMool1',
                  // fontWeight: FontWeight.bold,
                  color: TextColor, // USEA Deep Blue
                ),
              ),
              Text(
                "University of South-East Asia",
                style: TextStyle(
                  fontSize: 24,
                  letterSpacing: 0.7,
                  color: TextColor,
                  fontFamily: UEFontFamily,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
