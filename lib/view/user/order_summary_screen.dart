import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/cart_provider.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/model/reservation.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/service/api_client.dart';
import 'package:thesisapp/service/inventory_api.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/component/order_summary_components.dart';
import 'package:thesisapp/view/user/order_success.dart';

class OrderSummaryScreen extends StatefulWidget {
  final double total;
  final List<Map<String, dynamic>> items;
  final PaymentMethod paymentMethod;

  const OrderSummaryScreen({
    super.key,
    required this.total,
    required this.items,
    this.paymentMethod = PaymentMethod.cash,
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  final InventoryApi _api = InventoryApi();
  bool _isLoading = false;

  int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double? _parsePrice(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// Reserves the whole cart under one code, or reserves none of it.
  ///
  /// This used to send one request per line, because the API held one title
  /// per order — so a student checking out four books was handed four codes
  /// and the success screen joined them with commas. Four codes is four things
  /// for finance to check for one trip to the counter, and four slips for a
  /// receptionist to match against one identity card.
  ///
  /// It was also decided a line at a time. If the third book had just sold
  /// out, the first two stayed reserved and the student was told which one
  /// failed — leaving them holding a partial order they did not ask for, with
  /// copies held against their name that they may not want without the third.
  /// The server now locks every title and refuses the lot if one is short, so
  /// there is one answer to show and one cart to empty.
  Future<void> _placeOrder() async {
    final lang = AppLocalizations.of(context)!;
    final cartProvider = context.read<CartProvider>();
    final user = context.read<AuthProvider>().user;

    if (user == null) {
      Fluttertoast.showToast(msg: lang.translate('please_log_in_first'));
      return;
    }

    final lines = widget.items
        .where((item) => _parseInt(item['item_id']) > 0)
        .toList();

    if (lines.isEmpty) {
      Fluttertoast.showToast(msg: lang.translate('your cart is empty'));
      return;
    }

    setState(() => _isLoading = true);

    final Reservation order;

    try {
      order = await _api.reserveAll(
        items: [
          for (final line in lines)
            (
              itemId: _parseInt(line['item_id']),
              quantity: _parseInt(line['quantity']),
            ),
        ],
        studentId: user.student_id,
        paymentMethod: widget.paymentMethod,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // The server's refusal names the title that was short and by how much,
      // which is the actionable part — nothing is held, so the cart is left
      // exactly as it was for the student to adjust and try again.
      Fluttertoast.showToast(
        msg: error.message(lang),
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Emptied only now, and only of what was actually reserved.
    cartProvider.removeCheckedOutItems([
      for (final line in lines) _parseInt(line['cart_id']),
    ]);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(
          orderId: order.id,
          items: [
            for (final line in order.asLines)
              {
                'name': line.titleEn,
                'quantity': line.quantity,
                'price': line.unitPrice,
                'image': null,
              },
          ],
          total: order.totalPrice ?? 0,
          paymentMethod: widget.paymentMethod.wireName,
          // One code for the whole basket — this joined several with commas.
          trackingNumber: order.code,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('OrderSummary - items count: ${widget.items.length}');
    debugPrint('OrderSummary - items: ${widget.items}');
    debugPrint('OrderSummary - total: ${widget.total}');
    final lang = AppLocalizations.of(context)!;
    const background = Colors.white;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          lang.translate('order_summary'),
          style: TextStyle(
            fontSize: fontAppBar,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.translate('review your order details'),
                  style: TextStyle(
                    fontSize: fontSubtitle,
                    color: TextColor,
                    fontFamily: getFontFamily(context),
                  ),
                ),
                const SizedBox(height: 14),
                InfoCard(
                  title: 'Order Items',
                  child: widget.items.isEmpty
                      ? Text(
                          'No items found',
                          style: GoogleFonts.poppins(
                            fontSize: fontText,
                            color: Colors.grey[600],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.items.length,
                          separatorBuilder: (_, __) => const Divider(height: 20),
                          itemBuilder: (ctx, i) {
                            final item = widget.items[i];
                            final qty = _parseInt(item['quantity']);
                            final unitPrice = _parsePrice(item['price']);

                            return OrderItemRow(
                              name: item['name'] ?? '',
                              qty: qty,
                              // Null price stays null all the way to the row,
                              // which shows a dash rather than $0.00.
                              originalPrice: unitPrice == null
                                  ? null
                                  : unitPrice * qty,
                              imageUrl: buildProductImageUrl(
                                item['image']?.toString(),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 14),
                InfoCard(
                  title: 'Total',
                  child: InfoRow(
                    label: 'Grand Total',
                    value: '\$${widget.total.toStringAsFixed(2)}',
                    valueColor: ButtonColor,
                    valueWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Confirm Order',
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
    );
  }
}


