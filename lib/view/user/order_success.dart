import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/model/user_detail.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/user_api.dart';
import 'package:thesisapp/util/api_config.dart';
import 'package:thesisapp/view/main_screen.dart';
import 'package:thesisapp/service/pdf_receipt_helper.dart';

class OrderSuccessScreen extends StatefulWidget {
  final int orderId;
  // final Address? address;
  final String? addressText;
  final List<Map<String, dynamic>> items;
  final double total;
  final String paymentMethod;
  final DateTime createdAt;
  final int? displayOrderNumber;
  final String? trackingNumber;

  OrderSuccessScreen({
    super.key,
    required this.orderId,
    this.addressText,
    required this.items,
    required this.total,
    required this.paymentMethod,
    this.displayOrderNumber,
    this.trackingNumber,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSavingPdf = false;
  String? _resolvedTrackingNumber;
  UserDetail? _userDetail;

  @override
  void initState() {
    super.initState();
    _resolvedTrackingNumber = _normalizeTrackingNumber(widget.trackingNumber);
    _resolveDisplayOrderNumber();
    _resolveTrackingNumber();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final authUser = context.read<AuthProvider>().user;
    if (authUser == null) return;

    try {
      http.Response response;
      try {
        response = await http
            .post(
              Uri.parse(APILocalLoginUrl),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "student_id": authUser.student_id,
                "pwd": authUser.pwd,
              }),
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        response = await http.post(
          Uri.parse(APIStLoginKh),
          body: {'student_id': authUser.student_id, 'pwd': authUser.pwd},
        );
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final userData =
              (decoded['user_data'] as List?) ??
              (decoded['student_users'] as List?) ??
              (decoded['user'] != null ? [decoded['user']] : const []);
          final details = userData
              .whereType<Map<String, dynamic>>()
              .map(UserDetail.fromJson)
              .toList();

          if (mounted && details.isNotEmpty) {
            setState(() {
              _userDetail = details.first;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load user detail in order success: $e');
    }
  }

  PdfReceiptHelper _buildPdfHelper() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final name = (_userDetail?.name_kh.isNotEmpty == true)
        ? _userDetail!.name_kh
        : (user?.name_kh ?? '');

    return PdfReceiptHelper(
      context: context,
      orderId: widget.orderId,
      items: widget.items,
      total: widget.total,
      paymentMethod: widget.paymentMethod,
      createdAt: widget.createdAt,
      resolvedTrackingNumber: _resolvedTrackingNumber,
      screenshotController: _screenshotController,
      customerName: name,
      customerGender: _userDetail?.gender,
      customerDob: _userDetail?.date_of_birth,
      customerPhone: _userDetail?.phone_number,
    );
  }

  String? _normalizeTrackingNumber(dynamic value) {
    final normalized = value?.toString().trim() ?? '';
    if (normalized.isEmpty || normalized.toLowerCase() == 'null') {
      return null;
    }
    return normalized;
  }

  String _trackingNumberLabel() {
    return _resolvedTrackingNumber ??
        _normalizeTrackingNumber(widget.trackingNumber) ??
        'Pending assignment';
  }

  // Future<void> _copyTrackingNumber() async {
  //   final trackingNumber = _resolvedTrackingNumber;
  //   if (trackingNumber == null) return;
  //   await Clipboard.setData(ClipboardData(text: trackingNumber));
  //   Fluttertoast.showToast(msg: 'Code number of order copied');
  // }

  // String _orderNumberLabel() {
  //   if (_resolvedDisplayOrderNumber != null) {
  //     return 'Order #${_resolvedDisplayOrderNumber!}';
  //   }
  //   if (widget.displayOrderNumber != null) {
  //     return 'Order #${widget.displayOrderNumber!}';
  //   }
  //   if (_isResolvingDisplayNumber) {
  //     return 'Order #...';
  //   }
  //   return 'Order #${widget.orderId}';
  // }

  DateTime? _parseOrderDate(Map<String, dynamic> order) {
    final raw =
        order['created_at'] ?? order['order_date'] ?? order['date'] ?? '';
    final value = raw.toString().trim();
    if (value.isEmpty) return null;
    final numeric = int.tryParse(value);
    if (numeric != null) {
      if (value.length >= 13) {
        return DateTime.fromMillisecondsSinceEpoch(numeric);
      }
      return DateTime.fromMillisecondsSinceEpoch(numeric * 1000);
    }
    final normalized = value.contains(' ') && !value.contains('T')
        ? value.replaceFirst(' ', 'T')
        : value;
    return DateTime.tryParse(normalized);
  }

  int? _parseOrderId(Map<String, dynamic> order) {
    final raw = order['id'] ?? order['order_id'];
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  Future<void> _resolveDisplayOrderNumber() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    // setState(() => _isResolvingDisplayNumber = true);

    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/get_orders.php?user_id=${user.student_id}',
      );
      final response = await http.get(url);
      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return;
      final data = Map<String, dynamic>.from(decoded);
      if (data['status'] != 'success') return;

      final rawOrders = data['orders'];
      if (rawOrders is! List) return;

      final orders = rawOrders
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      orders.sort((a, b) {
        final aDate = _parseOrderDate(a);
        final bDate = _parseOrderDate(b);
        if (aDate != null && bDate != null) {
          final dateCompare = bDate.compareTo(aDate);
          if (dateCompare != 0) return dateCompare;
        } else if (aDate == null && bDate != null) {
          return 1;
        } else if (aDate != null && bDate == null) {
          return -1;
        }

        final aId = _parseOrderId(a);
        final bId = _parseOrderId(b);
        if (aId == null && bId == null) return 0;
        if (aId == null) return 1;
        if (bId == null) return -1;
        return bId.compareTo(aId);
      });

      final index = orders.indexWhere(
        (o) => _parseOrderId(o) == widget.orderId,
      );
      if (index == -1) return;

      final trackingNumber = _normalizeTrackingNumber(
        orders[index]['tracking_number'] ?? orders[index]['trackingNumber'],
      );

      if (mounted) {
        setState(() {
          _resolvedTrackingNumber ??= trackingNumber;
        });
      } else {
        _resolvedTrackingNumber ??= trackingNumber;
      }
    } catch (_) {
      // ignore network errors; fall back to orderId
    } finally {
      // if (mounted) {
      //   setState(() => _isResolvingDisplayNumber = false);
      // } else {
      //   _isResolvingDisplayNumber = false;
      // }
    }
  }

  Future<void> _resolveTrackingNumber() async {
    if (_resolvedTrackingNumber != null) return;

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/get_order_details.php?id=${widget.orderId}',
        ),
      );
      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return;

      final data = Map<String, dynamic>.from(decoded);
      if (data['status'] != 'success' || data['order'] is! Map) return;

      final order = Map<String, dynamic>.from(data['order']);
      final trackingNumber = _normalizeTrackingNumber(
        order['tracking_number'] ?? order['trackingNumber'],
      );
      if (trackingNumber == null) return;

      if (mounted) {
        setState(() => _resolvedTrackingNumber = trackingNumber);
      } else {
        _resolvedTrackingNumber = trackingNumber;
      }
    } catch (_) {
      // ignore network errors; the tracking number can still come from widget/get_orders.
    }
  }


  Future<void> _saveReceiptPdf() async {
    if (_isSavingPdf) return;
    setState(() => _isSavingPdf = true);
    try {
      await _buildPdfHelper().saveReceiptPdf();
    } finally {
      if (mounted) {
        setState(() => _isSavingPdf = false);
      }
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, double amount, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 18 : 14,
      fontWeight: bold ? FontWeight.bold : FontWeight.w600,
      color: bold ? Colors.green[700] : Colors.grey[800],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(PdfReceiptHelper.money(amount), style: style),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
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
            style: TextStyle(
              fontFamily: getFontFamily(context),
              fontSize: fontTitle,
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

  Widget _buildReceiptContent({required bool showImages}) {
    final paymentStatus = PdfReceiptHelper.paymentStatus(widget.paymentMethod);
    final trackingNumber = _trackingNumberLabel();
    final lang = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                // decoration: BoxDecoration(
                //   color: Colors.white,
                //   borderRadius: BorderRadius.circular(18),
                //   boxShadow: [
                //     BoxShadow(
                //       color: Colors.black.withOpacity(0.08),
                //       blurRadius: 8,
                //       offset: const Offset(0, 4),
                //     ),
                //   ],
                // ),
                child: Lottie.asset(
                  'assets/Done.json',
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  repeat: true,
                  animate: true,
                ),
              ),
              // const SizedBox(height: 10),
              Text(
                widget.paymentMethod == 'card'
                    ? lang.translate('payment successful')
                    : lang.translate('order placed successfully'),
                style: TextStyle(
                  fontFamily: getFontFamily(context),
                  fontSize: fontHeadTitle,
                  fontWeight: FontWeight.w700,
                  color: TitleColor,
                ),
              ),
              const SizedBox(height: 4),
              // Text(
              //   _orderNumberLabel(),
              //   style: TextStyle(color: Colors.grey[700]),
              // ),
            ],
          ),
        ),
        // _sectionCard(
        //   title: 'ព័ត៌មានអតិថិជន',
        //   children: [
        //     _infoRow(
        //       'ឈ្មោះ',
        //       _userDetail?.name_kh.isNotEmpty == true
        //           ? _userDetail!.name_kh
        //           : (context.watch<AuthProvider>().user?.name_kh ?? ''),
        //     ),
        //     if ((_userDetail?.gender ?? '').isNotEmpty)
        //       _infoRow('ភេទ', _userDetail!.gender),
        //     if ((_userDetail?.date_of_birth ?? '').isNotEmpty)
        //       _infoRow('ថ្ងៃ ខែ ឆ្នាំកំណើត', _userDetail!.date_of_birth),
        //     if ((_userDetail?.phone_number ?? '').isNotEmpty)
        //       _infoRow('លេខទូរសព្ទ', _userDetail!.phone_number),
        //   ],
        // ),
        const SizedBox(height: 16),
        _sectionCard(
          title: lang.translate('order information'),
          children: [
            _infoRow(
              lang.translate('receipt date'),
              PdfReceiptHelper.formatDate(widget.createdAt),
            ),
            _infoRow(
              lang.translate('payment method'),
              PdfReceiptHelper.paymentLabel(widget.paymentMethod),
            ),
            _infoRow(lang.translate('payment status'), paymentStatus),
            _infoRow(lang.translate('code number of order'), trackingNumber),
            // if (_resolvedTrackingNumber != null)
            //   Align(
            //     alignment: Alignment.centerRight,
            //     child: TextButton.icon(
            //       onPressed: _copyTrackingNumber,
            //       icon: const Icon(Icons.copy_rounded, size: 18),
            //       label: const Text('Copy'),
            //     ),
            //   ),
          ],
        ),
        const SizedBox(height: 16),
        // _sectionCard(
        //   title: 'Shipping Address',
        //   children: [
        //     Text(
        //       _addressText(),
        //       style: TextStyle(color: Colors.grey[700], height: 1.4),
        //     ),
        //   ],
        // ),
        // const SizedBox(height: 16),
        _sectionCard(
          title: lang.translate('items'),
          children: [
            if (widget.items.isEmpty)
              Text(lang.translate('no items found'))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.items.length,
                separatorBuilder: (_, __) => const Divider(height: 20),
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final name = PdfReceiptHelper.itemName(item);
                  final qty = PdfReceiptHelper.parseInt(item['quantity']);
                  final originalUnitPrice = PdfReceiptHelper.parseDouble(item['price']);
                  final double totalPricePerItem = originalUnitPrice * qty;
                  final imageUrl = showImages
                      ? PdfReceiptHelper.resolveItemImageUrl(item)
                      : null;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showImages)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl == null
                              ? Container(
                                  width: 54,
                                  height: 54,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image_rounded,
                                    size: 28,
                                    color: Colors.grey,
                                  ),
                                )
                              : Image.network(
                                  imageUrl,
                                  width: 54,
                                  height: 54,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 54,
                                    height: 54,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.broken_image_rounded,
                                      size: 28,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                        ),
                      if (showImages) const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${lang.translate('qty')}: $qty - ${PdfReceiptHelper.money(originalUnitPrice)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: fontText,
                              ),
                            ),
                            // if (hasDiscount)
                            //   Text(
                            //     'Original: ${_money(originalUnitPrice)}',
                            //     style: TextStyle(
                            //       color: Colors.grey[500],
                            //       fontSize: 12,
                            //       decoration: TextDecoration.lineThrough,
                            //     ),
                            //   ),
                            // if (discount > 0)
                            //   Text(
                            //     'Discount: ${discount.toStringAsFixed(0)}%',
                            //     style: TextStyle(
                            //       color: Colors.orange[700],
                            //       fontSize: 12,
                            //     ),
                            //   ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            PdfReceiptHelper.money(totalPricePerItem),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          // if (hasDiscount)
                          //   Text(
                          //     _money(originalLineTotal),
                          //     style: TextStyle(
                          //       color: Colors.grey[500],
                          //       fontSize: 12,
                          //       decoration: TextDecoration.lineThrough,
                          //     ),
                          //   ),
                        ],
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: lang.translate('total'),
          children: [
            // _amountRow('Subtotal', subtotal),
            _amountRow(lang.translate('grand total'), widget.total, bold: true),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(lang.translate('receipt'), style: TextStyle(color: Colors.white)),
      //   backgroundColor: Theme.of(context).primaryColor,
      //   foregroundColor: Colors.white,
      //   iconTheme: const IconThemeData(color: Colors.white),
      //   centerTitle: true,
      // ),
      body: Stack(
        children: [
          // const BackgroundColor(),
          Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReceiptContent(showImages: true),
                    const SizedBox(height: 16),
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: ElevatedButton.icon(
                    //     onPressed: _isSavingImage ? null : _saveReceiptImage,
                    //     icon: _isSavingImage
                    //         ? const SizedBox(
                    //             width: 18,
                    //             height: 18,
                    //             child: CircularProgressIndicator(
                    //               strokeWidth: 2,
                    //               valueColor: AlwaysStoppedAnimation<Color>(
                    //                 Colors.white,
                    //               ),
                    //             ),
                    //           )
                    //         : const Icon(Icons.photo_library_rounded),
                    //     label: Text(
                    //       _isSavingImage
                    //           ? 'Saving to Gallery...'
                    //           : 'Save to Gallery',
                    //     ),
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: const Color(0xFF2D6A4F),
                    //       foregroundColor: Colors.white,
                    //       padding: const EdgeInsets.symmetric(vertical: 14),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(12),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isSavingPdf ? null : _saveReceiptPdf,
                        icon: _isSavingPdf
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.picture_as_pdf_rounded),
                        label: Text(
                          _isSavingPdf
                              ? 'Saving ...'
                              : Platform.isAndroid
                              ? lang.translate('save receipt')
                              : lang.translate('save receipt'),
                          style: TextStyle(
                            fontFamily: getFontFamily(context),
                            fontSize: fontSubtitle,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D6A4F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MainScreen()),
                          (route) => false,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Theme.of(context).primaryColor),
                        ),
                        child: Text(
                          lang.translate('continue shopping'),
                          style: TextStyle(
                            fontFamily: getFontFamily(context),
                            fontSize: fontSubtitle,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
