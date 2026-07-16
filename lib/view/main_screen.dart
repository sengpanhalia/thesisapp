import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/navigation_provider.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/view/admin/home_screen.dart';
import 'package:thesisapp/view/admin/profile_screen.dart';
import 'package:thesisapp/view/cart_screen.dart';
import 'package:thesisapp/view/order_screen.dart';
import 'package:thesisapp/view/user/category_screen.dart';
import 'package:thesisapp/view/user/user_home_screen.dart';
import 'package:thesisapp/view/user/user_profile.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Set<int> _builtIndexes = <int>{0};
  bool? _lastIsAdmin;

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        final isAdmin = context.watch<AuthProvider>().user?.isAdmin ?? false;

        final screens = isAdmin
            ? const [AdminHomeScreen(), ProfileScreen()]
            : const [
                HomePage(),
                CategoryScreen(),
                CartScreen(),
                OrderScreen(),
                UserProfile(),
              ];
        final destinations = isAdmin
            ? const [
                NavigationDestination(
                  icon: _NavImageIcon(assetPath: 'assets/home.png'),
                  selectedIcon: _SelectedNavIcon(
                    assetPath: 'assets/home.png',
                    borderRadius: 14,
                  ),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_circle_outlined),
                  selectedIcon: _SelectedMaterialNavIcon(
                    icon: Icons.account_circle,
                  ),
                  label: 'Profile',
                ),
              ]
            : [
                NavigationDestination(
                  icon: const _NavImageIcon(assetPath: 'assets/home.png'),
                  selectedIcon: const _SelectedNavIcon(
                    assetPath: 'assets/home.png',
                    borderRadius: 14,
                  ),
                  label: lang.translate('home'),
                ),
                NavigationDestination(
                  icon: const _NavImageIcon(assetPath: 'assets/category.png'),
                  selectedIcon: const _SelectedNavIcon(
                    assetPath: 'assets/category.png',
                  ),
                  label: lang.translate('category'),
                ),
                NavigationDestination(
                  icon: const _NavImageIcon(assetPath: 'assets/cart.png'),
                  selectedIcon: const _SelectedNavIcon(
                    assetPath: 'assets/cart.png',
                  ),
                  label: lang.translate('cart'),
                ),
                NavigationDestination(
                  icon: const _NavImageIcon(assetPath: 'assets/order.png'),
                  selectedIcon: const _SelectedNavIcon(
                    assetPath: 'assets/order.png',
                  ),
                  label: lang.translate('order'),
                ),
                NavigationDestination(
                  icon: const _NavImageIcon(assetPath: 'assets/setting.png'),
                  selectedIcon: const _SelectedNavIcon(
                    assetPath: 'assets/setting.png',
                  ),
                  label: lang.translate('setting'),
                ),
              ];
        final currentIndex = navigationProvider.currentIndex;
        final safeIndex = currentIndex >= 0 && currentIndex < screens.length
            ? currentIndex
            : 0;

        if (_lastIsAdmin != isAdmin) {
          _lastIsAdmin = isAdmin;
          _builtIndexes
            ..clear()
            ..add(safeIndex);
        } else {
          _builtIndexes.add(safeIndex);
        }

        return Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: safeIndex,
            children: List.generate(screens.length, (index) {
              if (!_builtIndexes.contains(index)) {
                return const SizedBox.shrink();
              }

              return screens[index];
            }),
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
                    return TextStyle(
                      color: IconOrangeColor, // selected label color
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: getFontFamily(context),
                    );
                  }

                  return TextStyle(
                    color: BlackColor, // unselected label color
                    fontSize: 12,
                    fontFamily: getFontFamily(context),
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

                selectedIndex: safeIndex,

                onDestinationSelected: (index) {
                  navigationProvider.setIndex(index);
                },

                destinations: destinations,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SelectedMaterialNavIcon extends StatelessWidget {
  const _SelectedMaterialNavIcon({required this.icon});

  final IconData icon;

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
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
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
