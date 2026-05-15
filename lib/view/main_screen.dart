import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/navigation_provider.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/util/api_config.dart';
import 'package:thesisapp/view/cart_screen.dart';
import 'package:thesisapp/view/user/search_screen.dart';
import 'package:thesisapp/view/user/user_home_screen.dart';
import 'package:thesisapp/view/user/user_profile.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        // final isAdmin = context.watch<AuthProvider>().user?.isAdmin ?? false;

        // final screens = isAdmin
        //     ? const [AdminHomeScreen(), ProfileScreen()]
        //     : const [HomePage(), CartScreen(), OrderScreen(), ProfileScreen()];
        final screens = const [
          HomePage(),
          SearchScreen(baseUrl: ApiConfig.baseUrl),
          CartScreen(),
          UserProfile(),
        ];
        final currentIndex = navigationProvider.currentIndex;

        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              for (var index = 0; index < screens.length; index++)
                AnimatedOpacity(
                  opacity: currentIndex == index ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: IgnorePointer(
                    ignoring: currentIndex != index,
                    child: screens[index],
                  ),
                ),
            ],
          ),

          bottomNavigationBar: Container(
            margin: const EdgeInsets.only(top: Height5),
            padding: const EdgeInsets.only(top: Height10),
            decoration: BoxDecoration(
              color: ColorNavBar,
              borderRadius: BorderRadius.circular(30),
              // boxShadow: [
              //   BoxShadow(
              //     color: Colors.black.withValues(alpha: 0.08),
              //     blurRadius: 15,
              //     offset: const Offset(0, 5),
              //   ),
              // ],
            ),

            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: NavigationBar(
                labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
                  states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return const TextStyle(
                      color: IconOrangeColor, // selected label color
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: UKFontFamily,
                    );
                  }

                  return const TextStyle(
                    color: BlackColor, // unselected label color
                    fontSize: 12,
                    fontFamily: UKFontFamily,
                  );
                }),
                height: 80,
                backgroundColor: ColorNavBar,

                // remove ugly overlay
                surfaceTintColor: Colors.transparent,

                // Keep Flutter's default indicator hidden so the custom
                // selected icon stays a rounded square.
                indicatorColor: Colors.transparent,
                overlayColor: WidgetStateProperty.all(Colors.transparent),

                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                animationDuration: const Duration(milliseconds: 260),

                selectedIndex: currentIndex,

                onDestinationSelected: (index) {
                  navigationProvider.setIndex(index);
                },

                destinations: [
                  NavigationDestination(
                    icon: const _NavImageIcon(assetPath: 'assets/home.png'),

                    selectedIcon: const _SelectedNavIcon(
                      assetPath: 'assets/home.png',
                      borderRadius: 14,
                    ),

                    label: 'ទំព័រដើម',
                  ),

                  NavigationDestination(
                    icon: const _NavImageIcon(assetPath: 'assets/search.png'),

                    selectedIcon: const _SelectedNavIcon(
                      assetPath: 'assets/search.png',
                    ),

                    label: 'ស្វែងរក',
                  ),

                  NavigationDestination(
                    icon: const _NavImageIcon(assetPath: 'assets/cart.png'),

                    selectedIcon: const _SelectedNavIcon(
                      assetPath: 'assets/cart.png',
                    ),

                    label: 'កន្ត្រក',
                  ),

                  // NavigationDestination(
                  //   icon: Icon(
                  //     Icons.inventory_2_outlined,
                  //     color: Colors.grey.shade600,
                  //     size: 28,
                  //   ),

                  //   selectedIcon: Container(
                  //     padding: const EdgeInsets.all(10),
                  //     decoration: BoxDecoration(
                  //       color: IconOrangeColor,
                  //       borderRadius: BorderRadius.circular(10),
                  //     ),
                  //     child: const Icon(
                  //       Icons.inventory_2,
                  //       color: Colors.white,
                  //       size: 28,
                  //     ),
                  //   ),

                  //   label: 'កុម្ម៉ង់',
                  // ),
                  NavigationDestination(
                    icon: const _NavImageIcon(assetPath: 'assets/setting.png'),

                    selectedIcon: const _SelectedNavIcon(
                      assetPath: 'assets/setting.png',
                    ),

                    label: 'ការកំណត់',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavImageIcon extends StatelessWidget {
  const _NavImageIcon({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return ImageIcon(
      AssetImage(assetPath),
      color: Colors.grey.shade600,
      size: 28,
    );
  }
}

class _SelectedNavIcon extends StatelessWidget {
  const _SelectedNavIcon({required this.assetPath, this.borderRadius = 10});

  final String assetPath;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.88, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Opacity(
          opacity: scale.clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: IconOrangeColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ImageIcon(AssetImage(assetPath), color: Colors.white, size: 28),
      ),
    );
  }
}
