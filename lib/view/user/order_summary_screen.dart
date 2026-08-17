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

  /// Sends one reservation per basket line, because the API holds one title
  /// per order. Each is decided on its own: if the third book has just sold
  /// out, the first two stay reserved and the student is told which one
  /// failed and why, rather than losing the lot.
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

    final placed = <Reservation>[];
    final reservedCartIds = <int>[];
    final failures = <String>[];

    for (final line in lines) {
      try {
        final reservation = await _api.reserve(
          itemId: _parseInt(line['item_id']),
          quantity: _parseInt(line['quantity']),
          studentId: user.student_id,
          paymentMethod: widget.paymentMethod,
        );

        placed.add(reservation);
        reservedCartIds.add(_parseInt(line['cart_id']));
      } on ApiException catch (error) {
        final title = (line['name'] ?? '').toString();
        failures.add('$title: ${error.message(lang)}');
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (reservedCartIds.isNotEmpty) {
      cartProvider.removeCheckedOutItems(reservedCartIds);
    }

    for (final failure in failures) {
      Fluttertoast.showToast(msg: failure, toastLength: Toast.LENGTH_LONG);
    }

    if (placed.isEmpty) return;

    final total = placed.fold<double>(
      0.0,
      (sum, reservation) => sum + (reservation.totalPrice ?? 0),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(
          orderId: placed.first.id,
          items: [
            for (final reservation in placed)
              {
                'name': reservation.title,
                'quantity': reservation.quantity,
                'price': reservation.unitPrice,
                'image': null,
              },
          ],
          total: total,
          paymentMethod: widget.paymentMethod.wireName,
          trackingNumber: placed.map((r) => r.code).join(', '),
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
    const background = Color(0xFFF7F3EE);

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
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
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
                    valueColor: Colors.green[700],
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


