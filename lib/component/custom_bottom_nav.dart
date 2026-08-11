import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/cart_provider.dart';
import 'package:thesisapp/component/navigation_provider.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NavigationProvider, CartProvider>(
      builder: (context, navProvider, cartProvider, child) {
        final cartBadgeCount = cartProvider.cartBadgeCount;
        final items = [
          _buildNavIcon(Icons.home_rounded),
          _buildNavIcon(Icons.search_rounded),
          _buildNavIcon(
            Icons.shopping_cart_rounded,
            badgeCount: cartBadgeCount,
          ),
          _buildNavIcon(Icons.receipt_long_rounded),
          _buildNavIcon(Icons.person_rounded),
        ];
        final safeIndex = navProvider.currentIndex < items.length
            ? navProvider.currentIndex
            : items.length - 1;
        return CurvedNavigationBar(
          backgroundColor: Colors.white,
          index: safeIndex,
          animationDuration: const Duration(milliseconds: 300),
          onTap: (index) {
            navProvider.setIndex(index);
          },
          height: 70,
          color: Colors.red,
          items: items,
        );
      },
    );
  }

  Widget _buildNavIcon(IconData icon, {int badgeCount = 0}) {
    final badgeLabel = badgeCount > 99 ? '99+' : '$badgeCount';

    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: Icon(icon, color: Colors.redAccent, size: 30)),
          if (badgeCount > 0)
            Positioned(
              top: -4,
              right: -10,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: Text(
                  badgeLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
