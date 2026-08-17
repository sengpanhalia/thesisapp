import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/cart_description.dart';
import 'package:thesisapp/component/cart_provider.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/component/navigation_provider.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/model/book.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/view/user/checkout_payment.dart';

/// A basket line's picture, or the placeholder when the catalogue has none.
Widget _cartImage(String? rawImageUrl) {
  final url = buildProductImageUrl(rawImageUrl);

  if (url == null) {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey[200],
      child: const Icon(Icons.menu_book_rounded, size: 26, color: Colors.grey),
    );
  }

  return Image.network(
    url,
    width: 50,
    height: 50,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => Container(
      width: 50,
      height: 50,
      color: Colors.grey[200],
      child: const Icon(Icons.menu_book_rounded, size: 26, color: Colors.grey),
    ),
  );
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _didRefreshActiveTab = false;

  Future<void> _refreshCartScreen() async {
    final cartProvider = context.read<CartProvider>();
    await cartProvider.fetchCart();
    if (!mounted) return;
    setState(() {});
  }



  Future<void> _openCheckoutPaymentScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutPayment()),
    );

    if (!mounted) return;
    await _refreshCartScreen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-refresh cart when screen regains focus (after build completes)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    // const ColorE39A4F = AppColors.accentSoft;
    final isCartTabVisible =
        context.watch<NavigationProvider>().currentIndex == 2;

    if (isCartTabVisible && !_didRefreshActiveTab) {
      _didRefreshActiveTab = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _refreshCartScreen();
      });
    } else if (!isCartTabVisible) {
      _didRefreshActiveTab = false;
    }
    final lang = AppLocalizations.of(context)!;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: gradientColor(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
            child: SafeArea(
              child: Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  if (cartProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
            
                  // Empty cart state
                  if (cartProvider.cartItems.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_rounded,
                            size: 100,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            lang.translate('your cart is empty'),
                            style: TextStyle(
                              fontSize: fontTitle,
                              fontWeight: FontWeight.bold,
                              color: TextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lang.translate('looks like you haven\'t added anything yet'),
                            style: TextStyle(
                              fontSize: fontSubtitle,
                              color: TextColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  }
            
                  final canContinue = cartProvider.selectedItemIds.isNotEmpty;
            
                  // Cart with items
                  return Column(
                    children: [
                      // Top row: Total and Checkout
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                 Text(
                                  lang.translate("total"),
                                  style: TextStyle(
                                    color: TextColor,
                                    fontSize: fontTitle,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "\$${cartProvider.total.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: TextColor,
                                    fontSize: fontAppBar,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: !canContinue
                                  ? null
                                  : () async {
                                      await _openCheckoutPaymentScreen();
                                    },
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                ),
                                decoration: BoxDecoration(
                                  color: canContinue
                                      ? ButtonColor
                                      : Colors.grey[400],
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  lang.translate("checkout"),
                                  style: const TextStyle(
                                    color: Color(0xFFFFFFFF),
                                    fontSize: fontTitle,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
            
                      // Cart Summary Card
                      Builder(
                        builder: (context) {
                          final selectedItems = cartProvider.selectedItems;
                          if (selectedItems.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: CartSummaryCard(cartItems: selectedItems),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
            
                      // Blue main container 
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: CardColor,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Color(0xFFFFFFFF)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
            
                                // Select all row
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          final allSelected =
                                              cartProvider.allSelected;
                                          cartProvider.toggleSelectAll(
                                            !allSelected,
                                          );
                                        },
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: cartProvider.allSelected
                                                ? checkboxColor
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            // border: Border.all(
                                            //   color:
                                            //       (cartProvider
                                            //                   .selectedItemIds
                                            //                   .length ==
                                            //               cartProvider
                                            //                   .cartItems
                                            //                   .length &&
                                            //           cartProvider
                                            //               .cartItems
                                            //               .isNotEmpty)
                                            //       ? yellow
                                            //       : Colors.white70,
                                            // ),
                                          ),
                                          child: cartProvider.allSelected
                                              ? const Icon(
                                                  Icons.check_rounded,
                                                  size: 16,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        "Select all available",
                                        style: TextStyle(
                                          color: Color(0xFF9A9288),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 15),
            
                                // List of cart items
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: cartProvider.cartItems.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final item = cartProvider.cartItems[index];
                                      final cartId = item['cart_id'];
                                      // Null when the catalogue holds no price
                                      // for the book; shown as a dash, never
                                      // as $0.00.
                                      final price = cartProvider.itemPrice(item);
                                      final quantity = item['quantity'] ?? 1;
                                      final isPurchasable = cartProvider
                                          .isItemPurchasable(item);
            
                                      return Dismissible(
                                        key: Key(cartId.toString()),
                                        direction: DismissDirection.endToStart,
                                        onDismissed: (_) =>
                                            cartProvider.removeItem(cartId),
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(
                                            right: 20,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color.fromARGB(255, 241, 221, 201),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.delete_rounded,
                                            color: IconColor,
                                            size: 30,
                                          ),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Yellow checkbox
                                              GestureDetector(
                                                onTap: !isPurchasable
                                                    ? null
                                                    : () =>
                                                          cartProvider.toggleItem(
                                                            cartId,
                                                            !cartProvider
                                                                .selectedItemIds
                                                                .contains(cartId),
                                                          ),
                                                child: Container(
                                                  width: 22,
                                                  height: 22,
                                                  margin: const EdgeInsets.only(
                                                    top: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        cartProvider
                                                                .selectedItemIds
                                                                .contains(
                                                                  cartId,
                                                                ) &&
                                                            isPurchasable
                                                        ? checkboxColor
                                                        : isPurchasable
                                                        ? Colors.white
                                                        : Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                    // border: Border.all(
                                                    //   color:
                                                    //       cartProvider
                                                    //           .selectedItemIds
                                                    //           .contains(cartId)
                                                    //       ? Color(
                                                    //           0xFFE39A4F,
                                                    //         ).withOpacity(0.7)
                                                    //       : Colors.white,
                                                    // ),
                                                  ),
                                                  child:
                                                      cartProvider.selectedItemIds
                                                          .contains(cartId)
                                                      ? const Icon(
                                                          Icons.check_rounded,
                                                          size: 16,
                                                          color: Colors.white,
                                                        )
                                                      : null,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
            
                                              // Product info
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(20),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          // Product image
                                                          ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            child: _cartImage(
                                                              item['image']
                                                                  ?.toString(),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
            
                                                          // Name and price
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  item['name'] ??
                                                                      'Product',
                                                                  style: const TextStyle(
                                                                    color: TextColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize: fontText,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 4,
                                                                ),
                                                                // if (stockIssue !=
                                                                //     null) ...[
                                                                //   Text(
                                                                //     stockIssue,
                                                                //     style: const TextStyle(
                                                                //       color: Colors
                                                                //           .redAccent,
                                                                //       fontSize:
                                                                //           11,
                                                                //       fontWeight:
                                                                //           FontWeight
                                                                //               .w600,
                                                                //     ),
                                                                //   ),
                                                                //   const SizedBox(
                                                                //     height: 4,
                                                                //   ),
                                                                // ],
                                                                // else
                                                                //   Text(
                                                                //     'Stock: $stockQuantity',
                                                                //     style: const TextStyle(
                                                                //       color: Color(
                                                                //         0xFF9A9288,
                                                                //       ),
                                                                //       fontSize:
                                                                //           11,
                                                                //       fontWeight:
                                                                //           FontWeight
                                                                //               .w500,
                                                                //     ),
                                                                //   ),
                                                                Row(
                                                                  children: [
                                                                    Text(
                                                                      formatMoney(
                                                                        price,
                                                                      ),
                                                                      style: TextStyle(
                                                                        color:
                                                                            TextColor,
            
                                                                        fontSize:
                                                                            14,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w600,
                                                                      ),
                                                                    ),
                                                                    // -======
                                                                    const SizedBox(
                                                                      width: 5,
                                                                    ),
                                                                    // if (hasDiscount)
                                                                    //   Text(
                                                                    //     "\$${originalPrice.toStringAsFixed(2)}",
                                                                    //     style: GoogleFonts.poppins(
                                                                    //       fontSize:
                                                                    //           11,
                                                                    //       fontWeight:
                                                                    //           FontWeight.w500,
                                                                    //       color: Colors
                                                                    //           .black45,
                                                                    //       decoration:
                                                                    //           TextDecoration.lineThrough,
                                                                    //     ),
                                                                    //   ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
            
                                                          // Quantity controls
                                                          Row(
                                                            children: [
                                                              GestureDetector(
                                                                onTap: quantity > 1
                                                                    ? () => cartProvider
                                                                          .updateQuantity(
                                                                            cartId,
                                                                            -1,
                                                                          )
                                                                    : null,
                                                                child: Container(
                                                                  width: 28,
                                                                  height: 28,
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        checkboxColor,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                  ),
                                                                  child: const Icon(
                                                                    Icons
                                                                        .remove_rounded,
                                                                    size: 16,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                ),
                                                              ),
                                                              // const SizedBox(
                                                              //   width: 20,
                                                              // ),
                                                              Container(
                                                                width: 35,
                                                                alignment: Alignment.center,
                                                                child: Text(
                                                                  "$quantity",
                                                                  style: const TextStyle(
                                                                    color: TextColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize: fontTitle,
                                                                  ),
                                                                ),
                                                              ),
                                                              // const SizedBox(
                                                              //   width: 20,
                                                              // ),
                                                              GestureDetector(
                                                                onTap: () => cartProvider
                                                                      .updateQuantity(
                                                                        cartId,
                                                                        1,
                                                                      ),
                                                                child: Container(
                                                                  width: 28,
                                                                  height: 28,
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        checkboxColor,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                  ),
                                                                  child: const Icon(
                                                                    Icons
                                                                        .add_rounded,
                                                                    size: 16,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      const Divider(),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
