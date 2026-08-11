import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:thesisapp/component/cart_provider.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/util/api_config.dart';
import 'package:thesisapp/component/order_summary_components.dart';
import 'package:thesisapp/view/user/order_success.dart';

class OrderSummaryScreen extends StatefulWidget {
  final double total;
  final List<Map<String, dynamic>> items;
  final String paymentMethod;

  const OrderSummaryScreen({
    super.key,
    required this.total,
    required this.items,
    this.paymentMethod = 'cash_on_delivery',
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  bool _isLoading = false;

  int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  Future<void> _placeOrder() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) {
      Fluttertoast.showToast(msg: 'Please login first');
      return;
    }

    for (final item in widget.items) {
      final stockQuantity = _parseInt(item['stock_quantity']);
      final quantity = _parseInt(item['quantity']);
      if (stockQuantity <= 0) {
        Fluttertoast.showToast(
          msg: '${item['name'] ?? 'A product'} is out of stock',
        );
        return;
      }
      if (quantity > stockQuantity) {
        Fluttertoast.showToast(
          msg:
              'Only $stockQuantity item(s) left for ${item['name'] ?? 'this product'}',
        );
        return;
      }
    }

    try {
      final cartIds = widget.items
          .map((item) => _parseInt(item['cart_id']))
          .where((id) => id > 0)
          .toList();

      if (cartIds.isEmpty) {
        Fluttertoast.showToast(msg: 'No valid cart items selected');
        return;
      }

      setState(() => _isLoading = true);

      debugPrint(
        'Sending order - user_id: ${user.student_id}',
      );

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/place_order.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.student_id,
          'payment_method': widget.paymentMethod,
          'cart_ids': cartIds,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Order response: $data');
        if (data['status'] == 'success') {
          final orderId = data['order_id'];
          final rawTrackingNumber =
              (data['tracking_number'] ?? data['trackingNumber'] ?? '')
                  .toString()
                  .trim();
          cartProvider.removeCheckedOutItems(cartIds);
          Fluttertoast.showToast(msg: 'Order placed successfully!');
          if (!mounted) return;
          final parsedOrderId = int.tryParse(orderId.toString()) ?? 0;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => OrderSuccessScreen(
                orderId: parsedOrderId,
                items: widget.items,
                total: widget.total,
                paymentMethod: widget.paymentMethod,
                trackingNumber: rawTrackingNumber.isEmpty
                    ? null
                    : rawTrackingNumber,
              ),
            ),
            (route) => false,
          );
        } else {
          Fluttertoast.showToast(
            msg: data['message'] ?? 'Failed to place order',
          );
        }
      } else {
        Fluttertoast.showToast(msg: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Network error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
            fontSize: 20,
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
                    fontSize: 14,
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
                            fontSize: 12,
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
                            final qty =
                                int.tryParse(
                                  item['quantity']?.toString() ?? '0',
                                ) ??
                                0;
                            final unitPrice = _parseDouble(item['price']);
                            final originalLineTotal = unitPrice * qty;
                            return OrderItemRow(
                              name: item['name'] ?? '',
                              qty: qty,
                              originalPrice: originalLineTotal,
                              imageUrl:
                                  '${ApiConfig.productsUploadsUrl}/${item['image']}',
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


