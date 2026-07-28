import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:thesisapp/component/cart_provider.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/util/api_config.dart';
import 'package:thesisapp/view/khqr_payment_screen.dart';
import 'package:thesisapp/view/user/khqr_payment_screen.dart';
import 'package:thesisapp/view/user/order_success.dart';

class OrderSummaryScreen extends StatefulWidget {
  // final Address address;
  final double total;
  final List<Map<String, dynamic>> items;
  final String paymentMethod;

  const OrderSummaryScreen({
    super.key,
    // required this.address,
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

    // Validate address ID
    // if (widget.address.id == 0) {
    //   Fluttertoast.showToast(
    //     msg: 'Invalid address. Please select a valid address.',
    //   );
    //   return;
    // }

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
      // Extract cart IDs from items
      final cartIds = widget.items
          .map((item) => _parseInt(item['cart_id']))
          .where((id) => id > 0)
          .toList();

      if (cartIds.isEmpty) {
        Fluttertoast.showToast(msg: 'No valid cart items selected');
        return;
      }

      if (widget.paymentMethod == 'card') {
        // ✅ Create the order FIRST, then go to KHQR payment screen
        setState(() => _isLoading = true);
        try {
          final response = await http.post(
            Uri.parse('${ApiConfig.baseUrl}/place_order.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': user.student_id,
              'payment_method': 'card',
              'cart_ids': cartIds,
            }),
          );
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['status'] == 'success') {
              final orderId = int.tryParse(data['order_id']?.toString() ?? '');
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => KhqrPaymentScreen(
                    orderId: orderId,
                    items: widget.items,
                    total: widget.total,
                    cartIds: cartIds,
                  ),
                ),
                (route) => false,
              );
            } else {
              Fluttertoast.showToast(
                msg: data['message'] ?? 'Failed to create order',
              );
            }
          } else {
            Fluttertoast.showToast(msg: 'Server error: ${response.statusCode}');
          }
        } catch (e) {
          Fluttertoast.showToast(msg: 'Network error: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
        return;
      }

      setState(() => _isLoading = true);

      debugPrint(
        'Sending order - user_id: ${user.student_id}',
      );
      // debugPrint('Address data: ${widget.address.toJson()}');

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
                // address: widget.address,
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
    final background = const Color(0xFFF7F3EE);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
                      lang.translate('order_summary'),
                      style: TextStyle(
                        fontSize: 20,
                        // fontWeight: FontWeight.w700,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // _buildHeader(context),
              Text(
                lang.translate('review your order details'),
                style: TextStyle(
                  fontSize: 14,
                  color: TextColor,
                  fontFamily: getFontFamily(context),
                ),
              ),
              const SizedBox(height: 14),
              // _InfoCard(
              //   title: 'Shipping Address',
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Text(
              //         widget.address.fullName,
              //         style: GoogleFonts.poppins(
              //           fontWeight: FontWeight.w600,
              //           color: Colors.black87,
              //         ),
              //       ),
              //       const SizedBox(height: 4),
              //       Text(
              //         'Phone: ${formatPhone(widget.address.phone)}',
              //         style: GoogleFonts.poppins(
              //           fontSize: 12,
              //           color: Colors.grey[600],
              //         ),
              //       ),
              //       const SizedBox(height: 8),
              //       Text(
              //         widget.address.addressLine1,
              //         style: GoogleFonts.poppins(
              //           fontSize: 12,
              //           color: Colors.grey[600],
              //         ),
              //       ),
              //       if ((widget.address.addressLine2 ?? '').trim().isNotEmpty)
              //         Text(
              //           widget.address.addressLine2!.trim(),
              //           style: GoogleFonts.poppins(
              //             fontSize: 12,
              //             color: Colors.grey[600],
              //           ),
              //         ),
              //       Text(
              //         '${widget.address.city}${(widget.address.state ?? '').trim().isEmpty ? '' : ', ${widget.address.state}'} '
              //                 '${widget.address.postalCode ?? ''}'
              //             .trim(),
              //         style: GoogleFonts.poppins(
              //           fontSize: 12,
              //           color: Colors.grey[600],
              //         ),
              //       ),
              //       Text(
              //         widget.address.country,
              //         style: GoogleFonts.poppins(
              //           fontSize: 12,
              //           color: Colors.grey[600],
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              _InfoCard(
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
                          // final unitPrice = _parseDouble(item['price']);
                          // final discount = _parseDouble(item['discount']);
                          // final discountedUnitPrice = discount > 0
                          //     ? unitPrice * (1 - (discount / 100))
                          //     : unitPrice;
                          // final lineTotal = discountedUnitPrice * qty;
                          // final originalLineTotal = unitPrice * qty;
                          // final hasDiscount =
                          //     discount > 0 &&
                          //     discountedUnitPrice < unitPrice;
                          final unitPrice = _parseDouble(item['price']);
                          final originalLineTotal = unitPrice * qty;
                          return _OrderItemRow(
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
              _InfoCard(
                title: 'Total',
                child: _InfoRow(
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
    );
  }

  // Widget _buildHeader(BuildContext context) {
  //   final primary = Theme.of(context).colorScheme.primary;
  //   final lang = AppLocalizations.of(context)!;
  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
  //     child: SizedBox(
  //       height: 44,
  //       child: Stack(
  //         alignment: Alignment.center,
  //         children: [
  //           // Align(
  //           //   alignment: Alignment.centerLeft,
  //           //   child: RoundIconButton(
  //           //     icon: Icons.arrow_back_rounded,
  //           //     iconColor: primary,
  //           //     onPressed: () => Navigator.pop(context),
  //           //   ),
  //           // ),
  //           Text(
  //             lang.translate('order_summary'),
  //             style: TextStyle(
  //                   fontSize: 16,
  //                   color: Colors.black87,
  //                   fontFamily: getFontFamilyMool1(context),
  //                 ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
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
            color: Colors.black.withValues(alpha: 0.06),
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
            fontSize: 16,
            fontWeight: valueWeight ?? FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final String name;
  final int qty;
  // final double price;
  final double? originalPrice;
  final String imageUrl;

  const _OrderItemRow({
    required this.name,
    required this.qty,
    // required this.price,
    this.originalPrice,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl,
            width: 54,
            height: 54,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 54,
              height: 54,
              color: Colors.grey[200],
              child: const Icon(Icons.image_rounded, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty: $qty',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (originalPrice != null)
                Text(
                  '\$${originalPrice!.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
