import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/cart_provider.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/view/user/order_summary_screen.dart';

class CheckoutPayment extends StatefulWidget {
  // final int addressId;
  // final Address selectedAddress;

  const CheckoutPayment({
    super.key,
  });

  @override
  State<CheckoutPayment> createState() => _CheckoutPaymentState();
}

class _CheckoutPaymentState extends State<CheckoutPayment> {
  String selectedMethod = 'cash_on_delivery';
  bool _isRefreshing = false;

  Future<void> _refreshCart() async {
    setState(() => _isRefreshing = true);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    await cartProvider.fetchCart();
    setState(() => _isRefreshing = false);
  }

  void placeOrder() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final items = cartProvider.selectedItems;
    final total = cartProvider.total;

    debugPrint('Cart items count: ${items.length}');
    debugPrint('Total: $total');
    debugPrint('Cart items: $items');

    if (items.isEmpty) {
      Fluttertoast.showToast(msg: 'Your cart is empty');
      return;
    }

    // Navigate to order summary
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSummaryScreen(
          // address: widget.selectedAddress,
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
    // Auto-refresh cart when screen regains focus (after build completes)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final primary = Theme.of(context).colorScheme.primary;
    final muted = Colors.grey[600];
    final background = const Color(0xFFF7F3EE);
    // final address = widget.selectedAddress;
    final canPlaceOrder = cartProvider.selectedItems.isNotEmpty;
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshCart,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                  child: SizedBox(
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: RoundIconButton(
                            icon: Icons.arrow_back_rounded,
                            iconColor: primary,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Text(
                          'Payment',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  lang.translate('review and choose payment method'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: TextColor,
                    fontFamily: UKFontFamily,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lang.translate('note: The currency used for payment is the Cambodian Riel (KHR)'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: RedColor,
                    fontFamily: UEFontFamily,
                  ),
                ),
                const SizedBox(height: 14),
                _InfoCard(
                  title: 'Order Summary',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        label: 'Items',
                        value: cartProvider.selectedItems.length.toString(),
                      ),
                      const SizedBox(height: 6),
                      _InfoRow(
                        label: 'Total',
                        value: '\$${cartProvider.total.toStringAsFixed(2)}',
                        valueColor: Colors.green[700],
                        valueWeight: FontWeight.w700,
                      ),
                      if (_isRefreshing) ...[
                        const SizedBox(height: 10),
                        const LinearProgressIndicator(),
                      ],
                    ],
                  ),
                ),
                // const SizedBox(height: 14),
                // _InfoCard(
                //   title: 'Shipping Address',
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Text(
                //         address.fullName,
                //         style: GoogleFonts.poppins(
                //           fontWeight: FontWeight.w600,
                //           color: Colors.black87,
                //         ),
                //       ),
                //       const SizedBox(height: 4),
                //       Text(
                //         'Phone: ${formatPhone(address.phone)}',
                //         style: GoogleFonts.poppins(fontSize: 12, color: muted),
                //       ),
                //       const SizedBox(height: 8),
                //       Text(
                //         address.addressLine1,
                //         style: GoogleFonts.poppins(fontSize: 12, color: muted),
                //       ),
                //       if ((address.addressLine2 ?? '').trim().isNotEmpty)
                //         Text(
                //           address.addressLine2!.trim(),
                //           style: GoogleFonts.poppins(
                //             fontSize: 12,
                //             color: muted,
                //           ),
                //         ),
                //       Text(
                //         '${address.city}${(address.state ?? '').trim().isEmpty ? '' : ', ${address.state}'} '
                //                 '${address.postalCode ?? ''}'
                //             .trim(),
                //         style: GoogleFonts.poppins(fontSize: 12, color: muted),
                //       ),
                //       Text(
                //         address.country,
                //         style: GoogleFonts.poppins(fontSize: 12, color: muted),
                //       ),
                //     ],
                //   ),
                // ),
                const SizedBox(height: 18),
                Text(
                  'Select Payment Method',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                _PaymentOptionCard(
                  title: 'Cash on Delivery',
                  subtitle: 'Pay when you receive',
                  icon: Icons.payments_rounded,
                  selected: selectedMethod == 'cash_on_delivery',
                  primary: primary,
                  onTap: () =>
                      setState(() => selectedMethod = 'cash_on_delivery'),
                ),
                const SizedBox(height: 12),
                _PaymentOptionCard(
                  title: 'Card Payment',
                  subtitle: 'Credit or debit card',
                  icon: Icons.credit_card_rounded,
                  selected: selectedMethod == 'card',
                  primary: primary,
                  onTap: () => setState(() => selectedMethod = 'card'),
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
                        fontSize: 16,
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
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight? valueWeight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueWeight,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Colors.grey[600];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: muted)),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: valueWeight ?? FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const _PaymentOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? primary : Colors.transparent,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? primary : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color? backgroundColor;
  final double? elevation;
  final VoidCallback onPressed;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.iconColor,
    this.backgroundColor,
    this.elevation,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Colors.white,
      elevation: elevation ?? 2.0,
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onPressed,
      ),
    );
  }
}
