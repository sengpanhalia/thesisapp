import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/custom_bottom_nav.dart';
import 'package:thesisapp/component/navigation_provider.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/view/admin/home_screen.dart';
import 'package:thesisapp/view/admin/profile_screen.dart';
import 'package:thesisapp/view/cart_screen.dart';
import 'package:thesisapp/view/order_screen.dart';
import 'package:thesisapp/view/user/user_home_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        final isAdmin = context.watch<AuthProvider>().user?.isAdmin ?? false;
        final screens = isAdmin
            ? const [
                AdminHomeScreen(),
                ProfileScreen(),
              ]
            : const [
                HomePage(),
                // SearchScreen(baseUrl: ApiConfig.baseUrl),
                CartScreen(),
                OrderScreen(),
                ProfileScreen(),
              ];
        final maxIndex = screens.length - 1;
        if (navigationProvider.currentIndex > maxIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (navigationProvider.currentIndex > maxIndex) {
              navigationProvider.setIndex(maxIndex);
            }
          });
        }
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: IndexedStack(
              key: ValueKey(navigationProvider.currentIndex),
              index: navigationProvider.currentIndex,
              children: screens,
            ),
          ),
          bottomNavigationBar: CustomBottomNav(isAdmin: isAdmin),
        );
      },
    );
  }
}
