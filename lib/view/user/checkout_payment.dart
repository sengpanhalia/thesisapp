import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/cart_provider.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/component/payment_option_card.dart';
import 'package:thesisapp/view/user/order_summary_screen.dart';

class CheckoutPayment extends StatefulWidget {
  const CheckoutPayment({
    super.key,
  });

  @override
  State<CheckoutPayment> createState() => _CheckoutPaymentState();
}

class _CheckoutPaymentState extends State<CheckoutPayment> {
  String selectedMethod = 'cash_on_delivery';

  Future<void> _refreshCart() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    await cartProvider.fetchCart();
  }

  void placeOrder() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final items = cartProvider.selectedItems;
    final double total = items.fold(0.0, (sum, item) {
      final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
      final int quantity = item['quantity'] ?? 1;
      return sum + (price * quantity);
    });

    debugPrint('Cart items count: ${items.length}');
    debugPrint('Total: $total');
    debugPrint('Cart items: $items');

    if (items.isEmpty) {
      Fluttertoast.showToast(msg: 'Your cart is empty');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSummaryScreen(
          total: total,
          items: items,
          paymentMethod: selectedMethod,
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final primary = Theme.of(context).colorScheme.primary;
    const background = Color(0xFFF7F3EE);
    final canPlaceOrder = cartProvider.selectedItems.isNotEmpty;
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang.translate('payment'),
          style: TextStyle(
            fontSize: fontAppBar,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            fontFamily: getFontFamilyMool1(context),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: background,
      ),
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
          child: RefreshIndicator(
            onRefresh: _refreshCart,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.translate('select Payment Method'),
                    style: TextStyle(
                      fontSize: fontTitle,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      fontFamily: getFontFamily(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lang.translate('review and choose payment method'),
                    style: TextStyle(
                      fontSize: fontText,
                      fontWeight: FontWeight.w500,
                      color: TextColor,
                      fontFamily: getFontFamily(context),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PaymentOptionCard(
                    title: 'Pay at Store',
                    subtitle: 'Pay at the store',
                    icon: Icons.payments_rounded,
                    selected: selectedMethod == 'cash_on_delivery',
                    primary: primary,
                    onTap: () =>
                        setState(() => selectedMethod = 'cash_on_delivery'),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canPlaceOrder ? placeOrder : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Place Order',
                        style: GoogleFonts.poppins(
                          fontSize: fontTitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


