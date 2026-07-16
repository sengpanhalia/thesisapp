import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/util/api_config.dart';
import 'package:thesisapp/view/user/order_success.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  List<dynamic> _orderItems = [];
  bool _isLoadingItems = true;
  bool _isCancelling = false;

  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  String _money(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  void initState() {
    super.initState();
    _fetchOrderItems();
  }

  Future<void> _fetchOrderItems() async {
    final orderId = widget.order['id'] ?? widget.order['order_id'] ?? 0;
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/get_order_items.php?order_id=$orderId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _orderItems = data['items'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching order items: $e');
    } finally {
      setState(() => _isLoadingItems = false);
    }
  }

  Future<void> _cancelOrder(String reason) async {
    final orderId = widget.order['id'] ?? widget.order['order_id'] ?? 0;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      Fluttertoast.showToast(msg: 'Please login first');
      return;
    }

    setState(() => _isCancelling = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/cancel_order.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'user_id': user.student_id,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          Fluttertoast.showToast(msg: 'Order cancelled successfully');
          // Update local order status
          setState(() {
            widget.order['status'] = 'cancelled';
          });
          Navigator.pop(
            context,
            true,
          ); // Return true to indicate refresh needed
        } else {
          Fluttertoast.showToast(
            msg: data['message'] ?? 'Failed to cancel order',
          );
        }
      } else {
        Fluttertoast.showToast(msg: 'Server error');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Network error: $e');
    } finally {
      setState(() => _isCancelling = false);
    }
  }

  void _showCancelDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter cancellation reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                Fluttertoast.showToast(msg: 'Please enter a reason');
                return;
              }
              Navigator.pop(context);
              _cancelOrder(reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: _isCancelling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return GreenColor;
      case 'pending':
        return processColor;
      case 'cancelled':
        return RedColor;
      default:
        return TextColor;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}  '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  DateTime? _tryParseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  String? _trackingNumber() {
    final raw =
        (widget.order['tracking_number'] ??
                widget.order['trackingNumber'] ??
                '')
            .toString()
            .trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null') {
      return null;
    }
    return raw;
  }

  // Future<void> _copyTrackingNumber(String trackingNumber) async {
  //   await Clipboard.setData(ClipboardData(text: trackingNumber));
  //   Fluttertoast.showToast(msg: 'Code number of order copied');
  // }

  void _openReceipt({
    required int orderId,
    required String shippingAddress,
    required String paymentMethod,
    required double total,
    required String? orderDate,
  }) {
    if (_isLoadingItems) {
      Fluttertoast.showToast(msg: 'Loading items, please wait');
      return;
    }

    final items = _orderItems
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(
          orderId: orderId,
          displayOrderNumber: widget.order['display_order_number'] is int
              ? widget.order['display_order_number'] as int
              : int.tryParse(
                  widget.order['display_order_number']?.toString() ?? '',
                ),
          addressText: shippingAddress,
          items: items,
          total: total,
          paymentMethod: paymentMethod,
          createdAt: _tryParseDate(orderDate) ?? DateTime.now(),
          trackingNumber: _trackingNumber(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.order['id'] ?? widget.order['order_id'] ?? 0;
    final displayOrderNumber = widget.order['display_order_number'];
    final status = widget.order['status'] ?? 'pending';
    final normalizedStatus = status.toString().toLowerCase();
    final total =
        double.tryParse(widget.order['total_amount']?.toString() ?? '0') ?? 0.0;
    final shippingAddress = widget.order['shipping_address'] ?? 'N/A';
    final paymentMethod = widget.order['payment_method'] ?? 'cash_on_delivery';
    final orderDate =
        widget.order['order_date'] ?? widget.order['created_at'] ?? 'N/A';
    final trackingNumber = _trackingNumber();
    // final showTrackingCard =
    //     trackingNumber != null ||
    //     normalizedStatus == 'shipped' ||
    //     normalizedStatus == 'delivered';
    final statusColor = _getStatusColor(status.toString());
    final canCancel = normalizedStatus == 'pending';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // Matching the warm gradient from your design
          gradient: gradientColor(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // BackgroundColor(),
            Column(
              children: [
                /// ===== Gradient Header =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor.withOpacity(0.85), statusColor],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // RoundIconButton(
                      //   icon: Icons.arrow_back_rounded,
                      //   iconColor: Colors.white,
                      //   backgroundColor: Colors.white.withOpacity(0.2),
                      //   elevation: 0,
                      //   onPressed: () => Navigator.pop(context),
                      // ),
                      const SizedBox(height: 20),
                      Text(
                        displayOrderNumber != null
                            ? "Order #$trackingNumber"
                            : "Order #$orderId",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          status.toString().toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _formatDate(orderDate.toString()),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
        
                /// ===== Body Content =====
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        /// Order Items Card
                        if (_isLoadingItems)
                          const Center(child: CircularProgressIndicator())
                        else if (_orderItems.isNotEmpty)
                          _modernCard(
                            title: "Order Items (${_orderItems.length})",
                            children: [
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _orderItems.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 24),
                                itemBuilder: (context, index) {
                                  final item = _orderItems[index];
                                  final productName =
                                      item['product_name'] ?? 'Product';
                                  final productImage =
                                      item['product_image'] ?? '';
                                  final quantity = item['quantity'] ?? 1;
                                  final unitPrice = _parseDouble(item['price']);
                                  final originalUnitPrice = _parseDouble(
                                    item['original_price'],
                                  );
                                  final totalPrice = unitPrice * quantity;
                                  final originalTotalPrice =
                                      originalUnitPrice * quantity;
                                  final hasDiscount =
                                      originalUnitPrice > unitPrice;
        
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Product Image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          '${ApiConfig.productsUploadsUrl}/$productImage',
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.image_rounded,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Product Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              productName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'Qty: $quantity',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  "Price(1): ",
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  _money(unitPrice),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color.fromARGB(
                                                      172,
                                                      202,
                                                      169,
                                                      5,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                if (hasDiscount)
                                                  Row(
                                                    children: [
                                                      Text(
                                                        _money(originalUnitPrice),
                                                        style: TextStyle(
                                                          color: Colors.grey[500],
                                                          fontSize: 12,
                                                          decoration:
                                                              TextDecoration
                                                                  .lineThrough,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Price
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            _money(totalPrice),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          if (hasDiscount)
                                            Text(
                                              _money(originalTotalPrice),
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
        
                        const SizedBox(height: 16),
        
                        /// Shipping Address Card
                        _modernCard(
                          title: "Shipping Address",
                          children: [
                            Text(
                              shippingAddress,
                              style: TextStyle(
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
        
                        const SizedBox(height: 16),
        
                        // if (showTrackingCard) ...[
                        //   _modernCard(
                        //     title: "Code Number of Order",
                        //     children: [
                        //       Row(
                        //         children: [
                        //           const Icon(
                        //             Icons.local_shipping_rounded,
                        //             color: AppColors.accentDeep,
                        //           ),
                        //           const SizedBox(width: 10),
                        //           Expanded(
                        //             child: SelectableText(
                        //               trackingNumber ?? 'Not assigned yet',
                        //               style: TextStyle(
                        //                 color: Colors.grey[700],
                        //                 fontWeight: FontWeight.w600,
                        //               ),
                        //             ),
                        //           ),
                        //           if (trackingNumber != null)
                        //             IconButton(
                        //               onPressed: () =>
                        //                   _copyTrackingNumber(trackingNumber),
                        //               icon: const Icon(Icons.copy_rounded),
                        //               tooltip: 'Copy code number of order',
                        //             ),
                        //         ],
                        //       ),
                        //     ],
                        //   ),
                        //   const SizedBox(height: 16),
                        // ],
        
                        /// Payment Method Card
                        _modernCard(
                          title: "Payment Method",
                          children: [
                            Row(
                              children: [
                                Icon(
                                  paymentMethod == 'card'
                                      ? Icons.credit_card_rounded
                                      : Icons.money_rounded,
                                  color: ButtonColor,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  paymentMethod == 'card'
                                      ? 'Card Payment'
                                      : 'Cash on Delivery',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ],
                        ),
        
                        const SizedBox(height: 16),
        
                        /// Total Amount Card
                        _modernCard(
                          title: "Total Amount",
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Grand Total:',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '\$${total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
        
                        const SizedBox(height: 16),
        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openReceipt(
                              orderId: orderId,
                              shippingAddress: shippingAddress.toString(),
                              paymentMethod: paymentMethod.toString(),
                              total: total,
                              orderDate: orderDate.toString(),
                            ),
                            icon: const Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'View Receipt',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ButtonColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
        
                        const SizedBox(height: 24),
        
                        /// Cancel Button
                        if (canCancel)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showCancelDialog,
                              icon: const Icon(
                                Icons.cancel_rounded,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Cancel Order',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[400],
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _modernCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          // const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
