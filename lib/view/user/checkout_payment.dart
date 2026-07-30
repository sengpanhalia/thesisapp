import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/cart_provider.dart';
import 'package:thesisapp/component/component_app.dart';
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
    final background = const Color(0xFFF7F3EE);
    final canPlaceOrder = cartProvider.selectedItems.isNotEmpty;
    final lang = AppLocalizations.of(context)!;

    // final double totalSum = cartProvider.selectedItems.fold(0.0, (sum, item) {
    //   final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    //   final int quantity = item['quantity'] ?? 1;
    //   return sum + (price * quantity);
    // });

    return Scaffold(
      // backgroundColor: background,
      appBar: AppBar(
        title: Text(
                      lang.translate('payment'),
                      style: TextStyle(
                        fontSize: 20,
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
                  // Padding(
                  //   padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                  //   child: SizedBox(
                  //     height: 44,
                  //     child: Text(
                  //       lang.translate('payment'),
                  //       style: TextStyle(
                  //         fontSize: 20,
                  //         fontWeight: FontWeight.w700,
                  //         color: Colors.black87,
                  //         fontFamily: getFontFamilyMool1(context),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  Text(
                    lang.translate('select Payment Method'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      fontFamily: getFontFamily(context),
                    ),
                  ),
                  const SizedBox(height: 16),
        
                  Text(
                    lang.translate('review and choose payment method'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: TextColor,
                      fontFamily: getFontFamily(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lang.translate('note: The currency used for payment is the Cambodian Riel (KHR)'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: RedColor,
                      fontFamily: getFontFamily(context),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // _InfoCard(
                  //   title: lang.translate('order_summary'),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Table(
                  //         columnWidths: const {
                  //           0: FlexColumnWidth(3.5),
                  //           1: FlexColumnWidth(1.2),
                  //           2: FlexColumnWidth(2.5),
                  //           3: FlexColumnWidth(2.5),
                  //         },
                  //         defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  //         children: [
                  //           // Table Header
                  //           TableRow(
                  //             children: [
                  //               TableCell(
                  //                 child: Padding(
                  //                   padding: const EdgeInsets.only(bottom: 8.0),
                  //                   child: Text(
                  //                     lang.translate('item_name'),
                  //                     style: TextStyle(
                  //                       fontSize: 12,
                  //                       fontWeight: FontWeight.bold,
                  //                       color: TextSoftColor,
                  //                       fontFamily: getFontFamily(context),
                  //                     ),
                  //                   ),
                  //                 ),
                  //               ),
                  //               TableCell(
                  //                 child: Padding(
                  //                   padding: const EdgeInsets.only(bottom: 8.0),
                  //                   child: Text(
                  //                     lang.translate('quantity'),
                  //                     textAlign: TextAlign.center,
                  //                     style: TextStyle(
                  //                       fontSize: 12,
                  //                       fontWeight: FontWeight.bold,
                  //                       color: TextSoftColor,
                  //                       fontFamily: getFontFamily(context),
                  //                     ),
                  //                   ),
                  //                 ),
                  //               ),
                  //               TableCell(
                  //                 child: Padding(
                  //                   padding: const EdgeInsets.only(bottom: 8.0),
                  //                   child: Text(
                  //                     lang.translate('price_unit'),
                  //                     textAlign: TextAlign.right,
                  //                     style: TextStyle(
                  //                       fontSize: 12,
                  //                       fontWeight: FontWeight.bold,
                  //                       color: TextSoftColor,
                  //                       fontFamily: getFontFamily(context),
                  //                     ),
                  //                   ),
                  //                 ),
                  //               ),
                  //               TableCell(
                  //                 child: Padding(
                  //                   padding: const EdgeInsets.only(bottom: 8.0),
                  //                   child: Text(
                  //                     lang.translate('price'),
                  //                     textAlign: TextAlign.right,
                  //                     style: TextStyle(
                  //                       fontSize: 12,
                  //                       fontWeight: FontWeight.bold,
                  //                       color: TextSoftColor,
                  //                       fontFamily: getFontFamily(context),
                  //                     ),
                  //                   ),
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //           // Item Rows
                  //           ...cartProvider.selectedItems.map((item) {
                  //             final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                  //             final int quantity = item['quantity'] ?? 1;
                  //             final double totalPricePerItem = price * quantity;
        
                  //             return TableRow(
                  //               children: [
                  //                 TableCell(
                  //                   child: Padding(
                  //                     padding: const EdgeInsets.symmetric(vertical: 6.0),
                  //                     child: Text(
                  //                       item['name'] ?? '',
                  //                       maxLines: 2,
                  //                       overflow: TextOverflow.ellipsis,
                  //                       style: TextStyle(
                  //                         fontSize: 13,
                  //                         color: TextColor,
                  //                         fontFamily: getFontFamily(context),
                  //                       ),
                  //                     ),
                  //                   ),
                  //                 ),
                  //                 TableCell(
                  //                   child: Padding(
                  //                     padding: const EdgeInsets.symmetric(vertical: 6.0),
                  //                     child: Text(
                  //                       _formatQuantity(quantity, context),
                  //                       textAlign: TextAlign.center,
                  //                       style: TextStyle(
                  //                         fontSize: 13,
                  //                         color: TextColor,
                  //                         fontFamily: getFontFamily(context),
                  //                       ),
                  //                     ),
                  //                   ),
                  //                 ),
                  //                 TableCell(
                  //                   child: Padding(
                  //                     padding: const EdgeInsets.symmetric(vertical: 6.0),
                  //                     child: Text(
                  //                       '\$${price.toStringAsFixed(2)}',
                  //                       textAlign: TextAlign.right,
                  //                       style: TextStyle(
                  //                         fontSize: 13,
                  //                         color: TextColor,
                  //                         fontFamily: getFontFamily(context),
                  //                       ),
                  //                     ),
                  //                   ),
                  //                 ),
                  //                 TableCell(
                  //                   child: Padding(
                  //                     padding: const EdgeInsets.symmetric(vertical: 6.0),
                  //                     child: Text(
                  //                       '\$${totalPricePerItem.toStringAsFixed(2)}',
                  //                       textAlign: TextAlign.right,
                  //                       style: TextStyle(
                  //                         fontSize: 13,
                  //                         color: TextColor,
                  //                         fontFamily: getFontFamily(context),
                  //                       ),
                  //                     ),
                  //                   ),
                  //                 ),
                  //               ],
                  //             );
                  //           }),
                  //           // Divider Row
                  //           TableRow(
                  //             children: [
                  //               TableCell(
                  //                 child: Container(
                  //                   margin: const EdgeInsets.only(top: 6.0, bottom: 6.0),
                  //                   height: 1,
                  //                   color: StrokeColor,
                  //                 ),
                  //               ),
                  //               TableCell(
                  //                 child: Container(
                  //                   margin: const EdgeInsets.only(top: 6.0, bottom: 6.0),
                  //                   height: 1,
                  //                   color: StrokeColor,
                  //                 ),
                  //               ),
                  //               TableCell(
                  //                 child: Container(
                  //                   margin: const EdgeInsets.only(top: 6.0, bottom: 6.0),
                  //                   height: 1,
                  //                   color: StrokeColor,
                  //                 ),
                  //               ),
                  //               TableCell(
                  //                 child: Container(
                  //                   margin: const EdgeInsets.only(top: 6.0, bottom: 6.0),
                  //                   height: 1,
                  //                   color: StrokeColor,
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //           // Total Row
                  //           TableRow(
                  //             children: [
                  //               const TableCell(child: SizedBox()),
                  //               const TableCell(child: SizedBox()),
                  //               TableCell(
                  //                 child: Padding(
                  //                   padding: const EdgeInsets.only(top: 4.0),
                  //                   child: Text(
                  //                     lang.translate('total'),
                  //                     textAlign: TextAlign.right,
                  //                     style: TextStyle(
                  //                       fontSize: 14,
                  //                       fontWeight: FontWeight.bold,
                  //                       color: TextColor,
                  //                       fontFamily: getFontFamily(context),
                  //                     ),
                  //                   ),
                  //                 ),
                  //               ),
                  //               TableCell(
                  //                 child: Padding(
                  //                   padding: const EdgeInsets.only(top: 4.0),
                  //                   child: Text(
                  //                     '\$${totalSum.toStringAsFixed(2)}',
                  //                     textAlign: TextAlign.right,
                  //                     style: TextStyle(
                  //                       fontSize: 14,
                  //                       fontWeight: FontWeight.bold,
                  //                       color: TextColor,
                  //                       fontFamily: getFontFamily(context),
                  //                     ),
                  //                   ),
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         ],
                  //       ),
                  //       if (_isRefreshing) ...[
                  //         const SizedBox(height: 10),
                  //         const LinearProgressIndicator(),
                  //       ],
                  //     ],
                  //   ),
                  // ),
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
      ),
    );
  }
}

String _toKhmerDigits(String input) {
  const englishToKhmer = {
    '0': '០',
    '1': '១',
    '2': '២',
    '3': '៣',
    '4': '៤',
    '5': '៥',
    '6': '៦',
    '7': '៧',
    '8': '៨',
    '9': '៩',
  };
  return input.split('').map((char) => englishToKhmer[char] ?? char).join();
}

// String _formatCurrency(double amountInUsd, BuildContext context) {
//   final isKhmer = Localizations.localeOf(context).languageCode == 'km';
//   final rielAmount = (amountInUsd * 4000).round();
  
//   // Format with space as thousands separator
//   final regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
//   String formatted = rielAmount.toString().replaceAllMapped(regExp, (Match m) => '${m[1]} ');
  
//   if (isKhmer) {
//     return _toKhmerDigits(formatted);
//   }
//   return formatted;
// }

String _formatQuantity(int quantity, BuildContext context) {
  final isKhmer = Localizations.localeOf(context).languageCode == 'km';
  if (isKhmer) {
    return _toKhmerDigits(quantity.toString());
  }
  return quantity.toString();
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: StrokeCardColor,
          width: 1,
        ),
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: TextColor,
              fontFamily: getFontFamily(context),
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
