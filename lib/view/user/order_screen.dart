import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/model/reservation.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/service/api_client.dart';
import 'package:thesisapp/service/inventory_api.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/view/user/order_details_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

enum OrderHistoryFilter { all, week, month, year }

class _OrderScreenState extends State<OrderScreen> with WidgetsBindingObserver {
  final InventoryApi _api = InventoryApi();

  /*
   * How often an order still in flight is re-read.
   *
   * The counter moves an order forward on a web screen the student cannot see,
   * so a list read once when the screen opened says "កំពុងរង់ចាំ" long after
   * reception has confirmed the payment — the student is standing at the desk
   * being told their order is still waiting. Fifteen seconds is short enough
   * to feel immediate while they wait at the counter, and one small GET.
   */
  static const Duration _pollEvery = Duration(seconds: 15);

  Timer? _poll;

  List<Reservation> _orders = [];
  bool _isLoading = true;
  String? _loadError;
  OrderHistoryFilter _selectedFilter = OrderHistoryFilter.all;

  /// True while a read is in flight, so a second is not started on top of it.
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchOrders();
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /*
   * Away from the app, nothing is polled; coming back, the list is read at once.
   *
   * A phone in a pocket has no counter to watch, and a timer left running there
   * is battery spent on an answer nobody is reading. Returning to the app is
   * also the moment the list is most likely to be wrong — the student queued,
   * paid, and is looking at the screen again.
   */
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchOrders();
      _schedulePoll();
    } else {
      _poll?.cancel();
      _poll = null;
    }
  }

  /// Polls only while something can still change.
  ///
  /// This is the guard the earlier attempt lacked. An order that has been
  /// collected or cancelled is finished and will never move again, so a list
  /// holding nothing but finished orders is re-read never rather than every
  /// fifteen seconds — which for most students, most of the time, is no
  /// polling at all. The timer is replaced rather than stacked, so two reasons
  /// to refresh arriving together cannot leave two timers running.
  void _schedulePoll() {
    _poll?.cancel();
    _poll = null;

    final live = _orders.any((order) => !order.status.isFinished);

    if (!live || !mounted) return;

    _poll = Timer.periodic(_pollEvery, (_) => _fetchOrders());
  }

  /*
   * didChangeDependencies() used to re-read the list here as well, and that
   * was two mistakes stacked on one another.
   *
   * It fires once on first mount, immediately after initState() has already
   * fetched — so simply opening this screen made two identical requests. And
   * build() below reads `context.watch<AuthProvider>()`, which subscribes this
   * state to that provider: every notifyListeners() anywhere in the app called
   * didChangeDependencies() again, and each one made another request. Signing
   * in, editing a profile field and the provider's own start-up each cost a
   * full read of the order list, for a list nobody had asked to refresh.
   *
   * The intent behind it was sound — the counter moves a reservation forward
   * on the web screens, so a cached list goes stale — and it is already served
   * by two things that were there and did not need help: the list is read in
   * initState() each time the screen is opened, and the RefreshIndicator below
   * gives the student a fresh answer whenever they pull for one. Neither of
   * those fires because an unrelated provider changed.
   */

  Future<void> _fetchOrders() async {
    if (!mounted || _isFetching) return;

    _isFetching = true;

    final user = context.read<AuthProvider>().user;

    if (user == null) {
      _isFetching = false;
      setState(() => _isLoading = false);
      return;
    }

    try {
      final orders = await _api.reservationsFor(user.student_id);
      if (!mounted) return;

      setState(() {
        _orders = orders;
        _loadError = null;
      });

      // What is still in flight has just changed, so the timer is decided
      // again — the last live order being collected stops the polling.
      _schedulePoll();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.message(AppLocalizations.of(context)));
    } finally {
      _isFetching = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '\u2014';

    const months = [
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
    }

    return !date.isBefore(cutoff);
  }

  List<Reservation> _getDisplayOrders() {
    return _orders
        .where((order) => _isWithinSelectedRange(order.createdAt))
        .toList();
  }

  Color _getStatusColor(String status) {
    return Sapphire2;
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          lang.translate('order history'),
          style: TextStyle(
              fontFamily: getFontFamily(context),
              fontSize: fontAppBar,
              color: TitleColor,
            ),
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
                  ? Center(child: Text(lang.translate('please_log_in_first')))
                  : _orders.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _fetchOrders,
                      child: Builder(
                        builder: (context) {
                          final displayOrders = _getDisplayOrders();
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
                              final statusColor = _getStatusColor(
                                order.status.wireName,
                              );
                              // Copies across the whole order — an order is a
                              // basket now, so this is every title's quantity
                              // added up, not the first title's.
                              final orderItemCount = order.quantity;
                              return GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          OrderDetailsScreen(order: order),
                                    ),
                                  );
                                  if (result == true) {
                                    _fetchOrders(); // Refresh if it was cancelled
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
                                            height: 206,
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
                                                        order.code,
                                                        style: TextStyle(
                                                          fontSize: fontSubtitle,
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
                                                              .withValues(
                                                                alpha: 0.12,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                30,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          lang.translate(
                                                            order
                                                                .status
                                                                .translationKey,
                                                          ),
                                                          style: TextStyle(
                                                            color: statusColor,
                                                            fontSize: fontText,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontFamily:
                                                                getFontFamily(
                                                                  context,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 18),
                                                  _buildInfoRow(
                                                    Icons.schedule_rounded,
                                                    _formatDate(order.createdAt),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  // "Title × 2", or "Title
                                                  // and 3 more × 5" — naming
                                                  // the first and counting
                                                  // the rest, because a card
                                                  // that listed four titles
                                                  // would push the status and
                                                  // the total off the screen.
                                                  _buildInfoRow(
                                                    Icons.menu_book_rounded,
                                                    order.isBasket
                                                        ? '${order.title} +${order.lines.length - 1} × $orderItemCount'
                                                        : '${order.title} × $orderItemCount',
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
                                                      Text(
                                                        lang.translate('total'),
                                                        style: TextStyle(
                                                          fontSize: fontSubtitle,
                                                          color: Colors.grey,
                                                          fontFamily:
                                                              getFontFamily(
                                                                context,
                                                              ),
                                                        ),
                                                      ),
                                                      Text(
                                                        order.totalLabel,
                                                        style: TextStyle(
                                                          fontSize: fontSubtitle,
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
        // Expanded + ellipsis: a long item name (e.g. "Investment
        // Management (…)") wraps within the card instead of overflowing
        // the row to the right.
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: TextColor, fontSize: fontText),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final lang = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: CardColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _loadError == null
                    ? Icons.shopping_bag_rounded
                    : Icons.cloud_off_rounded,
                size: 60,
                color: IconColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              // A failed read and an empty list are different things, and a
              // student who is offline should not be told they have no orders.
              _loadError ?? lang.translate('no_orders_found'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSubtitle,
                fontWeight: FontWeight.w600,
                color: TextColor,
                fontFamily: getFontFamily(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final lang = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterButton(lang.translate('all'), OrderHistoryFilter.all),
          const SizedBox(width: 10),
          _buildFilterButton(lang.translate('week'), OrderHistoryFilter.week),
          const SizedBox(width: 10),
          _buildFilterButton(lang.translate('month'), OrderHistoryFilter.month),
          const SizedBox(width: 10),
          _buildFilterButton(lang.translate('year_filter'), OrderHistoryFilter.year),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, OrderHistoryFilter filter) {
    final isSelected = _selectedFilter == filter;
    final background = isSelected ? ButtonColor : Colors.white;
    final borderColor = isSelected ? ButtonColor : StrokeCardColor;
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
                  color: ButtonColor.withOpacity(0.25),
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
                fontSize: fontSubtitle,
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
