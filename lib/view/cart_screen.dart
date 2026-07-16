import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/cart_description.dart';
import 'package:thesisapp/component/cart_provider.dart';
import 'package:thesisapp/component/navigation_provider.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/util/api_config.dart';
import 'package:thesisapp/view/khqr_payment_screen.dart';

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

  Future<void> _openKhqrPaymentScreen() async {
    if (!KhqrPaymentWatcher.hasPayload || KhqrPaymentWatcher.address == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KhqrPaymentScreen(
          address: KhqrPaymentWatcher.address!,
          items: KhqrPaymentWatcher.items,
          total: KhqrPaymentWatcher.total!,
          cartIds: KhqrPaymentWatcher.cartIds,
          paymentId: KhqrPaymentWatcher.paymentId,
          orderId: KhqrPaymentWatcher.orderId,
          createdAt: KhqrPaymentWatcher.createdAt,
        ),
      ),
    );

    if (!mounted) return;
    await _refreshCartScreen();
  }

  // Future<void> _openCheckoutAddressScreen() async {
  //   await Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (_) => const CheckoutAddressScreen()),
  //   );

  //   if (!mounted) return;
  //   await _refreshCartScreen();
  // }

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

    return Scaffold(
      body: Stack(
        children: [
          // const BackgroundColor(),
          SafeArea(
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
                        const Text(
                          'Your cart is empty',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Looks like you haven\'t added anything yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                }

                final isPaymentLocked = KhqrPaymentWatcher.isActive;
                final canContinue =
                    isPaymentLocked || cartProvider.selectedItemIds.isNotEmpty;

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
                              const Text(
                                "Total",
                                style: TextStyle(
                                  color: TextColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "\$${cartProvider.total.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: TextColor,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: !canContinue
                                ? null
                                : () async {
                                    if (KhqrPaymentWatcher.isActive &&
                                        KhqrPaymentWatcher.hasPayload) {
                                      await _openKhqrPaymentScreen();
                                      return;
                                    }
                                    // await _openCheckoutAddressScreen();
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
                                KhqrPaymentWatcher.isActive
                                    ? "Continue"
                                    : "Checkout",
                                style: TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isPaymentLocked)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: StrokeCardColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lock_clock_rounded,
                                color: IconColor,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'KHQR payment is in progress. Cart changes are locked until you complete or cancel payment.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: TextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                            color: const Color.fromARGB(255, 241, 221, 201),
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
                                      onTap: isPaymentLocked
                                          ? null
                                          : () {
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
                                              ? Color(
                                                  0xFFE39A4F,
                                                ).withOpacity(0.7)
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
                                    final price =
                                        double.tryParse(
                                          item['price']?.toString() ?? '0',
                                        ) ??
                                        0.0;
                                    final originalPrice = price;
                                    final discount =
                                        int.tryParse(
                                          item['discount']?.toString() ?? '0',
                                        ) ??
                                        0;
                                    final hasDiscount =
                                        discount > 0 && discount < 100;
                                    final displayPrice = hasDiscount
                                        ? price * (1 - discount / 100)
                                        : price;
                                    final quantity = item['quantity'] ?? 1;
                                    final stockQuantity = cartProvider
                                        .itemStockQuantity(item);
                                    final stockIssue = cartProvider
                                        .stockIssueForItem(item);
                                    final isPurchasable = cartProvider
                                        .isItemPurchasable(item);

                                    return Dismissible(
                                      key: Key(cartId.toString()),
                                      direction: isPaymentLocked
                                          ? DismissDirection.none
                                          : DismissDirection.endToStart,
                                      onDismissed: isPaymentLocked
                                          ? null
                                          : (_) =>
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
                                              onTap:
                                                  isPaymentLocked ||
                                                      !isPurchasable
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
                                                      ? Color(
                                                          0xFFE39A4F,
                                                        ).withOpacity(0.7)
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
                                                          child: Image.network(
                                                            "${ApiConfig.productsUploadsUrl}/${item['image']}",
                                                            width: 50,
                                                            height: 50,
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (
                                                                  _,
                                                                  __,
                                                                  ___,
                                                                ) => Container(
                                                                  width: 50,
                                                                  height: 50,
                                                                  color: Colors
                                                                      .grey[200],
                                                                  child: const Icon(
                                                                    Icons
                                                                        .image_rounded,
                                                                    size: 30,
                                                                  ),
                                                                ),
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
                                                                  color: Color(
                                                                    0xFF9A9288,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 4,
                                                              ),
                                                              if (stockIssue !=
                                                                  null) ...[
                                                                Text(
                                                                  stockIssue,
                                                                  style: const TextStyle(
                                                                    color: Colors
                                                                        .redAccent,
                                                                    fontSize:
                                                                        11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 4,
                                                                ),
                                                              ],
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
                                                                    "\$${displayPrice.toStringAsFixed(2)}",
                                                                    style: TextStyle(
                                                                      color:
                                                                          Color.fromARGB(255, 241, 221, 201),

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
                                                                  if (hasDiscount)
                                                                    Text(
                                                                      "\$${originalPrice.toStringAsFixed(2)}",
                                                                      style: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            11,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        color: Colors
                                                                            .black45,
                                                                        decoration:
                                                                            TextDecoration.lineThrough,
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),

                                                        // Quantity controls
                                                        Row(
                                                          children: [
                                                            GestureDetector(
                                                              onTap:
                                                                  isPaymentLocked
                                                                  ? null
                                                                  : stockQuantity <=
                                                                        0
                                                                  ? null
                                                                  : quantity > 1
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
                                                                      Color.fromARGB(255, 241, 221, 201),
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
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Text(
                                                              "$quantity",
                                                              style: const TextStyle(
                                                                color: Color(
                                                                  0xFF9A9288,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            GestureDetector(
                                                              onTap:
                                                                  isPaymentLocked
                                                                  ? null
                                                                  : stockQuantity <=
                                                                        0
                                                                  ? null
                                                                  : quantity >=
                                                                        stockQuantity
                                                                  ? null
                                                                  : () => cartProvider
                                                                        .updateQuantity(
                                                                          cartId,
                                                                          1,
                                                                        ),
                                                              child: Container(
                                                                width: 28,
                                                                height: 28,
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      Color.fromARGB(255, 241, 221, 201),
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
        ],
      ),
    );
  }
}
