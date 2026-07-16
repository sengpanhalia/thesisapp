import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/util/api_config.dart';
import 'package:thesisapp/view/user/order_details_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

enum OrderHistoryFilter { all, week, month, year }

class _OrderScreenState extends State<OrderScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  OrderHistoryFilter _selectedFilter = OrderHistoryFilter.all;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh orders when screen regains focus (after build completes)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchOrders();
    });
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/get_orders.php?user_id=${user.student_id}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              _orders = data['orders'] ?? [];
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching orders: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(dynamic value) {
    final dateStr = value?.toString() ?? '';
    try {
      final date = _parseDateString(dateStr);
      if (date == null) return dateStr.isEmpty ? 'N/A' : dateStr;
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
    } catch (e) {
      return dateStr.isEmpty ? 'N/A' : dateStr;
    }
  }

  DateTime? _parseDateString(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final numeric = int.tryParse(trimmed);
    if (numeric != null) {
      if (trimmed.length >= 13) {
        return DateTime.fromMillisecondsSinceEpoch(numeric);
      }
      return DateTime.fromMillisecondsSinceEpoch(numeric * 1000);
    }
    final normalized = trimmed.contains(' ') && !trimmed.contains('T')
        ? trimmed.replaceFirst(' ', 'T')
        : trimmed;
    return DateTime.tryParse(normalized);
  }

  DateTime? _getOrderDate(dynamic order) {
    final raw =
        order['created_at'] ?? order['order_date'] ?? order['date'] ?? '';
    return _parseDateString(raw.toString());
  }

  int? _getOrderId(dynamic order) {
    final raw = order['id'] ?? order['order_id'];
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  String? _trackingNumber(dynamic order) {
    final raw = (order['tracking_number'] ?? order['trackingNumber'] ?? '')
        .toString()
        .trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null') {
      return null;
    }
    return raw;
  }

  bool _isWithinSelectedRange(DateTime? date) {
    if (_selectedFilter == OrderHistoryFilter.all) return true;
    if (date == null) return false;

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    DateTime cutoff;
    switch (_selectedFilter) {
      case OrderHistoryFilter.week:
        cutoff = startOfToday.subtract(const Duration(days: 6));
        break;
      case OrderHistoryFilter.month:
        cutoff = startOfToday.subtract(const Duration(days: 29));
        break;
      case OrderHistoryFilter.year:
        cutoff = startOfToday.subtract(const Duration(days: 364));
        break;
      case OrderHistoryFilter.all:
        return true;
        break;
    }

    return !date.isBefore(cutoff);
  }

  List<dynamic> _getSortedOrders() {
    final sorted = List<dynamic>.from(_orders);
    sorted.sort((a, b) {
      final aDate = _getOrderDate(a);
      final bDate = _getOrderDate(b);
      if (aDate != null && bDate != null) {
        final dateCompare = bDate.compareTo(aDate);
        if (dateCompare != 0) return dateCompare;
      } else if (aDate == null && bDate != null) {
        return 1;
      } else if (aDate != null && bDate == null) {
        return -1;
      }

      final aId = _getOrderId(a);
      final bId = _getOrderId(b);
      if (aId == null && bId == null) return 0;
      if (aId == null) return 1;
      if (bId == null) return -1;
      return bId.compareTo(aId);
    });
    return sorted;
  }

  List<dynamic> _getDisplayOrders(List<dynamic> sortedAll) {
    return sortedAll
        .where((order) => _isWithinSelectedRange(_getOrderDate(order)))
        .toList();
  }

  int? _getDisplayOrderNumber(List<dynamic> sortedAll, dynamic order) {
    final orderId = _getOrderId(order);
    if (orderId == null) return null;

    final index = sortedAll.indexWhere((o) => _getOrderId(o) == orderId);
    if (index == -1) return null;
    return index + 1;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Orders",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
        ),
      ),
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
            SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : context.watch<AuthProvider>().user == null
                  ? const Center(child: Text("Please log in to view orders"))
                  : _orders.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _fetchOrders,
                      child: Builder(
                        builder: (context) {
                          final sortedAll = _getSortedOrders();
                          final displayOrders = _getDisplayOrders(sortedAll);
                          final showEmptyFilter = displayOrders.isEmpty;
                          final itemCount = showEmptyFilter
                              ? 2
                              : displayOrders.length + 1;
        
                          return ListView.builder(
                            padding: const EdgeInsets.all(20),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: itemCount,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFilterBar(),
                                    // const SizedBox(height: 10),
                                    // Text(
                                    //   _selectedFilter == OrderHistoryFilter.all
                                    //       ? "Showing all orders"
                                    //       : "Showing all orders in this period",
                                    //   style: const TextStyle(
                                    //     fontSize: 12,
                                    //     color: AppColors.textMuted,
                                    //   ),
                                    // ),
                                    const SizedBox(height: 12),
                                  ],
                                );
                              }
        
                              if (showEmptyFilter) {
                                return _buildFilteredEmptyState();
                              }
        
                              final displayIndex = index - 1;
                              final order = displayOrders[displayIndex];
                              final orderId = order['id'] ?? order['order_id'];
                              final orderNumber =
                                  _getDisplayOrderNumber(sortedAll, order) ??
                                  (displayIndex + 1);
                              final status = order['status'] ?? 'pending';
                              final total =
                                  double.tryParse(
                                    order['total_amount']?.toString() ??
                                        order['total']?.toString() ??
                                        '0',
                                  ) ??
                                  0.0;
                              final date =
                                  order['created_at'] ??
                                  order['order_date'] ??
                                  'N/A';
                              final orderItemCount = order['item_count'] ?? 0;
                              final trackingNumber = _trackingNumber(order);
                              final normalizedStatus = status
                                  .toString()
                                  .toLowerCase();
                              final showTracking =
                                  trackingNumber != null ||
                                  normalizedStatus == 'shipped' ||
                                  normalizedStatus == 'delivered';
        
                              final statusColor = _getStatusColor(
                                status.toString(),
                              );
        
                              final orderWithNumber = Map<String, dynamic>.from(
                                order,
                              );
                              orderWithNumber['display_order_number'] =
                                  orderNumber;
        
                              return GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrderDetailsScreen(
                                        order: orderWithNumber,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _fetchOrders(); // Refresh if order was cancelled
                                  }
                                },
                                child: Column(
                                  children: [
                                    const SizedBox(height: 6),
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 18),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(22),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 14,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: showTracking ? 206 : 180,
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(22),
                                                    bottomLeft: Radius.circular(
                                                      22,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(22),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        orderNumber > 0
                                                            ? "Order #$trackingNumber"
                                                            : "Order #${orderId ?? '-'}",
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 14,
                                                              vertical: 6,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: statusColor
                                                              .withOpacity(0.12),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                30,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          status
                                                              .toString()
                                                              .toUpperCase(),
                                                          style: TextStyle(
                                                            color: statusColor,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 18),
                                                  _buildInfoRow(
                                                    Icons.schedule_rounded,
                                                    _formatDate(date),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  _buildInfoRow(
                                                    Icons.shopping_cart_rounded,
                                                    "$orderItemCount Items",
                                                  ),
                                                  // if (showTracking) ...[
                                                  //   const SizedBox(height: 10),
                                                  //   _buildInfoRow(
                                                  //     Icons
                                                  //         .local_shipping_outlined,
                                                  //     trackingNumber == null
                                                  //         ? "Code Number of Order: Not assigned yet"
                                                  //         : "Code Number of Order: $trackingNumber",
                                                  //   ),
                                                  // ],
                                                  const SizedBox(height: 20),
                                                  const Divider(),
                                                  const SizedBox(height: 14),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      const Text(
                                                        "Total Amount",
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      Text(
                                                        "\$${total.toStringAsFixed(2)}",
                                                        style: TextStyle(
                                                          fontSize: 22,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: statusColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: IconColor),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: TextColor, fontSize: 14)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: CardColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              size: 60,
              color: IconColor,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Orders Found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            "Your placed orders will appear here",
            style: TextStyle(fontSize: 14, color: TextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterButton("All", OrderHistoryFilter.all),
          const SizedBox(width: 10),
          _buildFilterButton("Week", OrderHistoryFilter.week),
          const SizedBox(width: 10),
          _buildFilterButton("Month", OrderHistoryFilter.month),
          const SizedBox(width: 10),
          _buildFilterButton("Year", OrderHistoryFilter.year),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, OrderHistoryFilter filter) {
    final isSelected = _selectedFilter == filter;
    final background = isSelected ? SoftGreen : Colors.white;
    final borderColor = isSelected ? SoftGreen : StrokeCardColor;
    final textColor = isSelected ? Colors.white : TextColor;

    return Material(
      color: Colors.transparent, 
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() => _selectedFilter = filter);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: SoftGreen.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              Text(
                label,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          children: const [
            Icon(
              Icons.filter_alt_off_rounded,
              size: 44,
              color: IconColor,
            ),
            SizedBox(height: 10),
            Text(
              "No orders for the selected period",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: TextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
