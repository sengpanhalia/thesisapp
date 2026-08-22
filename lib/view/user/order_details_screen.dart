import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/localization/app_localizations.dart' show AppLocalizations;
import 'package:thesisapp/model/reservation.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/service/api_client.dart';
import 'package:thesisapp/service/inventory_api.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/view/user/order_success.dart';

/// One reservation, re-read from the server every time it is opened.
///
/// The counter moves a reservation forward on the web screens — confirms it,
/// marks it ready, hands it over — so the status the list screen was showing
/// may already be stale. This polls rather than trusting what it was handed.
class OrderDetailsScreen extends StatefulWidget {
  final Reservation order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final InventoryApi _api = InventoryApi();

  late Reservation _order = widget.order;
  bool _isRefreshing = true;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (mounted) setState(() => _isRefreshing = true);

    try {
      final fresh = await _api.reservation(widget.order.code);
      if (!mounted) return;

      setState(() => _order = fresh);
    } on ApiException catch (error) {
      if (!mounted) return;
      Fluttertoast.showToast(msg: error.message(AppLocalizations.of(context)));
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _cancel() async {
    final lang = AppLocalizations.of(context)!;
    final user = context.read<AuthProvider>().user;

    if (user == null) {
      Fluttertoast.showToast(msg: lang.translate('please_log_in_first'));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          lang.translate('cancel_reservation'),
          style: TextStyle(fontFamily: getFontFamily(context)),
        ),
        content: Text(
          lang.translate('cancel_reservation_message'),
          style: TextStyle(fontFamily: getFontFamily(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(lang.translate('back')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(lang.translate('confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);

    try {
      await _api.cancelReservation(
        code: _order.code,
        studentId: user.student_id,
      );

      if (!mounted) return;
      Fluttertoast.showToast(msg: lang.translate('reservation_cancelled'));

      // The held copies are free again the moment this returns, so leave with
      // a flag that tells the list screen to re-read.
      Navigator.pop(context, true);
      return;
    } on ApiException catch (error) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: error.message(lang),
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  /// The e-invoice, which is the thing finance checks the code against.
  ///
  /// Every line, not the first one. The receipt has always drawn a table from
  /// `items` and was only ever handed one row, so an order of four books
  /// printed a slip for one of them under a code covering all four — a total
  /// that did not add up from the lines above it, which is precisely what a
  /// person reconciling it would query.
  void _openReceipt() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(
          orderId: _order.id,
          items: [
            for (final line in _order.asLines)
              {
                'name': line.titleEn,
                'quantity': line.quantity,
                'price': line.unitPrice,
                'image': null,
              },
          ],
          total: _order.totalPrice ?? 0,
          paymentMethod: _order.paymentMethod,
          createdAt: _order.createdAt,
          trackingNumber: _order.code,
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}  '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _modernCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: getFontFamily(context),
              fontSize: fontSubtitle,
              fontWeight: FontWeight.w700,
              color: TitleColor,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: getFontFamily(context),
              fontSize: fontText,
              color: TextSoftColor,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: getFontFamily(context),
                fontSize: fontText,
                fontWeight: FontWeight.w600,
                color: valueColor ?? TextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final khmer = Localizations.localeOf(context).languageCode == 'km';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang.translate('order details'),
          style: TextStyle(
            fontFamily: getFontFamily(context),
            fontSize: fontAppBar,
            color: TitleColor,
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
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Height20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/tracking_number_icon.png',
                        height: Height20,
                      ),
                      const SizedBox(width: Width10),
                      Text(
                        _order.code,
                        style: TextStyle(
                          fontFamily: getFontFamily(context),
                          fontSize: fontSubtitle,
                          fontWeight: FontWeight.bold,
                          color: GreenColor,
                        ),
                      ),
                      const Spacer(),
                      if (_isRefreshing)
                        const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: Height15),

                  // The one line the student is waiting for: whether it is
                  // ready to collect.
                  if (_order.status == ReservationStatus.readyForPickup)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: GreenColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        lang.translate('ready_for_pickup_message'),
                        style: TextStyle(
                          fontFamily: getFontFamily(context),
                          fontSize: fontText,
                          fontWeight: FontWeight.w600,
                          color: GreenColor,
                        ),
                      ),
                    ),

                  _modernCard(
                    title: lang.translate('order information'),
                    children: [
                      _row(
                        lang.translate('status'),
                        lang.translate(_order.status.translationKey),
                      ),
                      _row(
                        lang.translate('receipt date'),
                        _formatDate(_order.createdAt),
                      ),
                      _row(
                        lang.translate('payment method'),
                        _order.paymentMethod,
                      ),
                      // Only a cash sale is booked as paid, and nothing is
                      // settled in the app — so this says PENDING until the
                      // counter takes the money.
                      _row(
                        lang.translate('payment status'),
                        _order.isPaid ? 'PAID' : 'PENDING',
                        valueColor: _order.isPaid ? GreenColor : TextColor,
                      ),
                      if (_order.note.isNotEmpty)
                        _row(lang.translate('note'), _order.note),
                    ],
                  ),

                  /*
                   * Every title under this code, not just the first.
                   *
                   * This card read `_order.title` and `_order.quantity`, which
                   * was the whole order while an order was one book. One code
                   * now covers everything a student checked out together, and
                   * showing one of four on the screen they check their money
                   * against is worse than showing none.
                   */
                  _modernCard(
                    title: lang.translate('order items'),
                    children: [
                      for (final (index, line) in _order.asLines.indexed) ...[
                        if (index > 0) const Divider(height: 24),
                        _row(lang.translate('book'), line.title(khmer: khmer)),
                        _row(lang.translate('book_code'), line.itemCode),
                        _row(
                          lang.translate('quantity'),
                          line.quantity.toString(),
                        ),
                        _row(lang.translate('price'), line.unitPriceLabel),
                      ],
                    ],
                  ),

                  _modernCard(
                    title: lang.translate('total amount'),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lang.translate('grand total'),
                            style: TextStyle(
                              fontFamily: getFontFamily(context),
                              fontWeight: FontWeight.w600,
                              color: TextColor,
                              fontSize: fontText,
                            ),
                          ),
                          Text(
                            _order.totalLabel,
                            style: TextStyle(
                              fontSize: fontSubtitle,
                              fontWeight: FontWeight.bold,
                              color: Sapphire,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openReceipt,
                      icon: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        lang.translate('view receipt'),
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: getFontFamily(context),
                        ),
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

                  const SizedBox(height: 12),

                  // Cancelling releases the held copies straight away. Offered
                  // only while the reservation can still be called off.
                  if (_order.status.isCancellable)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isCancelling ? null : _cancel,
                        icon: _isCancelling
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.close_rounded, color: RedColor),
                        label: Text(
                          lang.translate('cancel_reservation'),
                          style: TextStyle(
                            color: RedColor,
                            fontFamily: getFontFamily(context),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: RedColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
