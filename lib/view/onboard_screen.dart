import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/view/signin_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'សូមស្វាគមន៍មកកាន់',
      subtitle: 'សាកលវិទ្យាល័យ សៅស៍អុីសថ៍អេយសៀ',
      description: 'ស្វែងរកសៀវភៅនៅលើដៃរបស់អ្នក',
      image: 'assets/intro1.png',
    ),
    OnboardingPage(
      title: 'ការស្វែងរកកាន់តែងាយស្រួល',
      description: 'ការបញ្ជាទិញកាន់តែរហ័ស ងាយស្រួល និងទំនើប',
      image: 'assets/intro2.png',
    ),
    OnboardingPage(
      title: 'ចំណេញពេលវេលា ភាពជឿនលឿន',
      description:
          'សេវាកម្មរហ័ស និងមានភាពជឿនលឿន សម្រាប់ការស្វែងរកសៀវភៅរបស់អ្នក',
      image: 'assets/intro3.png',
    ),
  ];

  // handle get started button press
  Future<void> handleGetStarted() async {
    await context.read<AuthProvider>().setFirstTimeDone();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SigninScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            // Matching the warm gradient from your design
            gradient: gradientColor(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          page.image,
                          height: MediaQuery.of(context).size.height * 0.4,
                        ),
                        const SizedBox(height: 40),
                        Column(
                          children: [
                            textGradient(
                              page.title,
                              TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontFamily: UKFontFamily,
                              ),
                            ),
                            SizedBox(height: 10),
                            textGradient(
                              page.subtitle,
                              TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontFamily: UKFontFamily,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            page.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: TextColor,
                              fontFamily: UKFontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentPage == index
                            ? Theme.of(context).primaryColor
                            : (isDark ? Colors.grey[700] : Colors.grey[300]),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: handleGetStarted,
                      child: Text(
                        "រំលង",
                        style: TextStyle(
                          fontSize: 14,
                          color: BlackColor,
                          fontFamily: UKFontFamily,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          // Navigate to home or login screen
                          handleGetStarted();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),

                      child: Text(
                        _currentPage < _pages.length - 1
                            ? "បន្ទាប់"
                            : "ចាប់ផ្តើម",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontFamily: UKFontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final String image;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    this.subtitle = "",
  });
}
