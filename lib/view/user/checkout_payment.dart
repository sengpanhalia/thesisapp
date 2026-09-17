import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/cart_provider.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/service/inventory_api.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/component/payment_option_card.dart';
import 'package:thesisapp/view/user/order_summary_screen.dart';

class CheckoutPayment extends StatefulWidget {
  final List<Map<String, dynamic>>? directItems;
  final double? directTotal;

  const CheckoutPayment({
    super.key,
    this.directItems,
    this.directTotal,
  });

  @override
  State<CheckoutPayment> createState() => _CheckoutPaymentState();
}

class _CheckoutPaymentState extends State<CheckoutPayment> {
  /// Cash by default, which is the only one the system books as paid. The
  /// others are recorded as a stated intention and settled at the counter —
  /// nothing is charged in the app.
  PaymentMethod selectedMethod = PaymentMethod.cash;

  Future<void> _refreshCart() async {
    if (widget.directItems != null) return;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    await cartProvider.fetchCart();
  }

  void placeOrder() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final items = widget.directItems ?? cartProvider.selectedItems;
    final total = widget.directTotal ?? cartProvider.total;

    if (items.isEmpty) {
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context)!.translate('your cart is empty'),
      );
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
    if (widget.directItems == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        cartProvider.fetchCart();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final primary = Theme.of(context).colorScheme.primary;
    const background = Colors.white;
    final canPlaceOrder = widget.directItems != null
        ? widget.directItems!.isNotEmpty
        : cartProvider.selectedItems.isNotEmpty;
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ButtonColor),
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
                    lang.translate('payment method'),
                    style: TextStyle(
                      fontSize: fontTitle,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      fontFamily: getFontFamily(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lang.translate('payment will be made directly when you pick up the item.'),
                    style: TextStyle(
                      fontSize: fontText,
                      fontWeight: FontWeight.w500,
                      color: TextColor,
                      fontFamily: getFontFamily(context),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PaymentOptionCard(
                    title: lang.translate('payment_cash'),
                    subtitle: lang.translate('pay_at_the_counter'),
                    icon: Icons.payments_rounded,
                    selected: selectedMethod == PaymentMethod.cash,
                    primary: primary,
                    onTap: () =>
                        setState(() => selectedMethod = PaymentMethod.cash),
                  ),
                  const SizedBox(height: 12),
                  // PaymentOptionCard(
                  //   title: lang.translate('payment_khqr'),
                  //   subtitle: lang.translate('settled_at_the_counter'),
                  //   icon: Icons.qr_code_rounded,
                  //   selected: selectedMethod == PaymentMethod.khqr,
                  //   primary: primary,
                  //   onTap: () =>
                  //       setState(() => selectedMethod = PaymentMethod.khqr),
                  // ),
                  // const SizedBox(height: 12),
                  // Said plainly, because the system cannot take money: the
                  // reservation only holds the copies.
                  // Text(
                  //   lang.translate('reservation_payment_note'),
                  //   style: TextStyle(
                  //     fontSize: fontText,
                  //     color: TextColor,
                  //     fontFamily: getFontFamily(context),
                  //   ),
                  // ),
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
                        lang.translate('continue'),
                        style: TextStyle(
                          fontSize: fontSubtitle,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: getFontFamily(context),
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


