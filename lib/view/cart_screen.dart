import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/cart_provider.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/util/api_config.dart';
import 'package:thesisapp/view/khqr_payment_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartProvider>().fetchCart();
    });
  }

  Future<void> _checkout(CartProvider cartProvider) async {
    final selectedItems = cartProvider.selectedItems;
    if (selectedItems.isEmpty) {
      Fluttertoast.showToast(msg: 'Please select at least one item');
      return;
    }

    final invalidItem = selectedItems
        .where((item) => !cartProvider.isItemPurchasable(item))
        .firstOrNull;
    if (invalidItem != null) {
      Fluttertoast.showToast(
        msg: cartProvider.stockIssueForItem(invalidItem) ?? 'Invalid item',
      );
      return;
    }

    final cartIds = selectedItems
        .map((item) => int.tryParse(item['cart_id']?.toString() ?? '') ?? 0)
        .where((id) => id > 0)
        .toList();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KhqrPaymentScreen(
          address: const Address(id: 0, label: 'Default address'),
          items: selectedItems,
          total: cartProvider.total,
          cartIds: cartIds,
        ),
      ),
    );

    if (!mounted) return;
    await cartProvider.fetchCart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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

              if (cartProvider.cartItems.isEmpty) {
                return const _EmptyCart();
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      MgPd20,
                      MgPd15,
                      MgPd20,
                      MgPd10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cart',
                                style: TextStyle(
                                  fontFamily: UEFontFamily,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: TitleColor,
                                ),
                              ),
                              Text(
                                '\$${cartProvider.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontFamily: UEFontFamily,
                                  fontSize: 18,
                                  color: GText1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: cartProvider.selectedItemIds.isEmpty
                              ? null
                              : () => _checkout(cartProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ButtonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Round15),
                            ),
                          ),
                          child: const Text('Checkout'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: MgPd20),
                    child: Row(
                      children: [
                        Checkbox(
                          value: cartProvider.allSelected,
                          activeColor: ButtonColor,
                          onChanged: (value) {
                            cartProvider.toggleSelectAll(value ?? false);
                          },
                        ),
                        const Text(
                          'Select all available',
                          style: TextStyle(
                            fontFamily: UEFontFamily,
                            color: TextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: cartProvider.fetchCart,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          MgPd20,
                          MgPd10,
                          MgPd20,
                          110,
                        ),
                        itemCount: cartProvider.cartItems.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: Height10),
                        itemBuilder: (context, index) {
                          final item = cartProvider.cartItems[index];
                          return _CartItemTile(
                            item: item,
                            cartProvider: cartProvider,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item, required this.cartProvider});

  final Map<String, dynamic> item;
  final CartProvider cartProvider;

  int _intValue(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    final cartId = _intValue(item['cart_id']);
    final quantity = cartProvider.itemQuantity(item);
    final stockQuantity = cartProvider.itemStockQuantity(item);
    final stockIssue = cartProvider.stockIssueForItem(item);
    final isPurchasable = cartProvider.isItemPurchasable(item);
    final isSelected = cartProvider.selectedItemIds.contains(cartId);
    final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    final image = (item['image'] ?? '').toString().trim();
    final imageUrl = image.startsWith('http')
        ? image
        : '${ApiConfig.productsUploadsUrl}/$image';

    return Dismissible(
      key: ValueKey(cartId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await cartProvider.removeItem(cartId);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: MgPd20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(Round15),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.all(MgPd10),
        decoration: BoxDecoration(
          color: CardColor,
          borderRadius: BorderRadius.circular(Round15),
          border: Border.all(color: StrokeSearchBar),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              activeColor: ButtonColor,
              onChanged: isPurchasable
                  ? (value) => cartProvider.toggleItem(cartId, value ?? false)
                  : null,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(Round10),
              child: Image.network(
                imageUrl,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 58,
                  height: 58,
                  color: GBackground3,
                  child: const Icon(Icons.image_rounded, color: TextSoftColor),
                ),
              ),
            ),
            const SizedBox(width: Width10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (item['name'] ?? 'Product').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: UEFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: TitleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: UEFontFamily,
                      color: GText1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (stockIssue != null)
                    Text(
                      stockIssue,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                _QtyButton(
                  icon: Icons.remove_rounded,
                  onTap: quantity > 1
                      ? () => cartProvider.updateQuantity(cartId, -1)
                      : null,
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: UEFontFamily,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _QtyButton(
                  icon: Icons.add_rounded,
                  onTap: stockQuantity > 0 && quantity < stockQuantity
                      ? () => cartProvider.updateQuantity(cartId, 1)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Round10),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap == null ? GreyColor : ButtonColor,
          borderRadius: BorderRadius.circular(Round10),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 82, color: TextSoftColor),
          SizedBox(height: Height15),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontFamily: UEFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: TextColor,
            ),
          ),
        ],
      ),
    );
  }
}
