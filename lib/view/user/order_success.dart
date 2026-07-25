import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// import 'package:screenshot/screenshot.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/util/api_config.dart';
import 'package:thesisapp/view/main_screen.dart';

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
  static const String _appName = 'សាកលវិទ្យាល័យ សៅស៍អ៊ីសថ៍អេយសៀ';
  static const String _logoAssetPath = 'assets/logo_app.png';
  static const MethodChannel _fileSaverChannel = MethodChannel(
    'university_of_south_east_asia/file_saver',
  );
  // final ScreenshotController _screenshotController = ScreenshotController();
  // bool _isSavingImage = false;
  bool _isSavingPdf = false;
  int? _resolvedDisplayOrderNumber;
  String? _resolvedTrackingNumber;
  // bool _isResolvingDisplayNumber = false;

  @override
  void initState() {
    super.initState();
    _resolvedTrackingNumber = _normalizeTrackingNumber(widget.trackingNumber);
    _resolveDisplayOrderNumber();
    _resolveTrackingNumber();
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  int _displayOrderNumberValue() {
    return _resolvedDisplayOrderNumber ??
        widget.displayOrderNumber ??
        widget.orderId;
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
    if (widget.displayOrderNumber != null) {
      _resolvedDisplayOrderNumber = widget.displayOrderNumber;
      return;
    }

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
          _resolvedDisplayOrderNumber = index + 1;
          _resolvedTrackingNumber ??= trackingNumber;
        });
      } else {
        _resolvedDisplayOrderNumber = index + 1;
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

  double _discountedUnitPrice(Map<String, dynamic> item) {
    final price = _parseDouble(item['price']);
    final discount = _parseDouble(item['discount']);
    if (discount <= 0) return price;
    return price * (1 - (discount / 100));
  }

  double _lineTotal(Map<String, dynamic> item) {
    final qty = _parseInt(item['quantity']);
    return _discountedUnitPrice(item) * qty;
  }

  double _calcSubtotal() {
    double subtotal = 0.0;
    for (final item in widget.items) {
      subtotal += _lineTotal(item);
    }
    return subtotal;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'card':
        return 'Card Payment';
      case 'cash_on_delivery':
        return 'Cash on Delivery';
      default:
        return method;
    }
  }

  String _paymentStatus(String method) {
    return method == 'card' ? 'Paid' : 'Pay on Delivery';
  }

  // String _formatAddress(Address a) {
  //   final parts = <String>[
  //     a.fullName,
  //     a.addressLine1,
  //     if ((a.addressLine2 ?? '').trim().isNotEmpty) a.addressLine2!.trim(),
  //     '${a.city}${a.state == null || a.state!.trim().isEmpty ? '' : ', ${a.state}'}'
  //         '${a.postalCode == null || a.postalCode!.trim().isEmpty ? '' : ' ${a.postalCode}'}',
  //     a.country,
  //     'Phone: ${formatPhone(a.phone)}',
  //   ];
  //   return parts.where((p) => p.trim().isNotEmpty).join('\n');
  // }

  // String _addressText() {
  //   final raw = (widget.addressText ?? '').trim();
  //   if (raw.isNotEmpty) return raw;
  //   if (widget.address != null) return _formatAddress(widget.address!);
  //   return 'N/A';
  // }

  String _money(double value) => '\$${value.toStringAsFixed(2)}';

  String _itemName(Map<String, dynamic> item) {
    return (item['name'] ??
            item['product_name'] ??
            item['productName'] ??
            'Item')
        .toString();
  }

  String? _resolveItemImageUrl(Map<String, dynamic> item) {
    final candidates = [
      item['image'],
      item['product_image'],
      item['productImage'],
      item['image_url'],
      item['product_image_url'],
    ];

    for (final c in candidates) {
      final raw = (c ?? '').toString().trim();
      if (raw.isEmpty) continue;
      final lower = raw.toLowerCase();
      if (lower == 'null' || lower == 'none' || lower == 'undefined') {
        continue;
      }
      if (raw.startsWith('http://') || raw.startsWith('https://')) {
        return raw;
      }
      if (raw.contains('/')) {
        final base = ApiConfig.baseUrl.endsWith('/')
            ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
            : ApiConfig.baseUrl;
        final relative = raw.startsWith('/') ? raw.substring(1) : raw;
        return '$base/$relative';
      }
      return '${ApiConfig.productsUploadsUrl}/$raw';
    }
    return null;
  }

  Future<Uint8List> _buildReceiptPdfBytes() async {
    final logoData = await rootBundle.load(_logoAssetPath);
    final logoBytes = logoData.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    final doc = pw.Document();
    final subtotal = _calcSubtotal();
    final paymentStatus = _paymentStatus(widget.paymentMethod);
    // final addressText = _addressText();
    final displayNumber = _displayOrderNumberValue();
    final trackingNumber = _resolvedTrackingNumber;

    final itemRows = widget.items.map((item) {
      final name = _itemName(item);
      final qty = _parseInt(item['quantity']);
      final unit = _discountedUnitPrice(item);
      final lineTotal = _lineTotal(item);
      return [name, '$qty', _money(unit), _money(lineTotal)];
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 50,
                    height: 50,
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _appName,
                        style: pw.TextStyle(
                          fontSize: 18,
                          
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'University of South-East Asia',
                        style: pw.TextStyle(color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Order #$displayNumber',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    _formatDate(widget.createdAt),
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 12),
          pw.Text(
            'Order Information',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Payment Method: ${_paymentLabel(widget.paymentMethod)}'),
          pw.Text('Payment Status: $paymentStatus'),
          pw.Text(
            'Code Number of Order: ${trackingNumber ?? 'Pending assignment'}',
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Shipping Address',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          // pw.SizedBox(height: 6),
          // pw.Text(addressText),
          pw.SizedBox(height: 16),
          pw.Text('Items', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (itemRows.isEmpty)
            pw.Text('No items found')
          else
            pw.Table.fromTextArray(
              headers: const ['Item', 'Qty', 'Price', 'Total'],
              data: itemRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
              },
            ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Subtotal: ${_money(subtotal)}'),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Grand Total: ${_money(widget.total)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Thank you for shopping with us!',
            style: pw.TextStyle(color: PdfColors.grey700),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // Future<bool> _ensureGalleryPermission() async {
  //   if (Platform.isAndroid) {
  //     final status = await Permission.storage.request();
  //     if (status.isGranted) return true;
  //     final photos = await Permission.photos.request();
  //     return photos.isGranted || photos.isLimited;
  //   }
  //   if (Platform.isIOS) {
  //     final addOnly = await Permission.photosAddOnly.request();
  //     if (addOnly.isGranted || addOnly.isLimited) return true;
  //     final photos = await Permission.photos.request();
  //     return photos.isGranted || photos.isLimited;
  //   }
  //   return true;
  // }
  // 
  // Future<Uint8List> _captureReceiptImage() async {
  //   final theme = Theme.of(context);
  //   final mediaQuery = MediaQuery.of(context);
  //   final content = _buildReceiptContent(showImages: false);
  // 
  //   final bytes = await _screenshotController.captureFromWidget(
  //     MediaQuery(
  //       data: mediaQuery.copyWith(
  //         padding: EdgeInsets.zero,
  //         viewInsets: EdgeInsets.zero,
  //       ),
  //       child: Theme(
  //         data: theme,
  //         child: Material(
  //           color: Colors.white,
  //           child: Padding(padding: const EdgeInsets.all(20), child: content),
  //         ),
  //       ),
  //     ),
  //     pixelRatio: 2.5,
  //   );
  // 
  //   if (bytes == null) {
  //     throw Exception('Failed to capture receipt');
  //   }
  //   return bytes;
  // }

  // Future<void> _saveReceiptImage() async {
  //   if (_isSavingImage) return;
  //   setState(() => _isSavingImage = true);
  //   try {
  //     final allowed = await _ensureGalleryPermission();
  //     if (!allowed) {
  //       Fluttertoast.showToast(msg: 'Permission denied');
  //       return;
  //     }

  //     final bytes = await _captureReceiptImage();
  //     final result = await ImageGallerySaver.saveImage(
  //       bytes,
  //       quality: 100,
  //       name: 'receipt_order_${widget.orderId}',
  //     );

  //     final isSuccess = result is Map
  //         ? (result['isSuccess'] == true || result['success'] == true)
  //         : result == true;

  //     Fluttertoast.showToast(
  //       msg: isSuccess ? 'Saved to gallery' : 'Save failed',
  //     );
  //   } catch (e) {
  //     Fluttertoast.showToast(msg: 'Failed to save image: $e');
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isSavingImage = false);
  //     }
  //   }
  // }

  Future<void> _saveReceiptPdf() async {
    if (_isSavingPdf) return;
    setState(() => _isSavingPdf = true);
    try {
      final bytes = await _buildReceiptPdfBytes();
      final filename = 'receipt_order_${widget.orderId}.pdf';
      String? savedPath;

      if (Platform.isAndroid) {
        try {
          savedPath = await _fileSaverChannel.invokeMethod<String>(
            'savePdfToDownloads',
            {'fileName': filename, 'bytes': bytes},
          );
        } catch (_) {
          // Native plugin not compiled in current app session, fallback to direct file write below
        }
      }

      if (savedPath == null || savedPath.isEmpty) {
        Directory? targetDir;
        if (Platform.isAndroid) {
          final publicDownloadDir = Directory('/storage/emulated/0/Download');
          if (await publicDownloadDir.exists()) {
            targetDir = publicDownloadDir;
          } else {
            try {
              targetDir = await getDownloadsDirectory();
            } catch (_) {}
            targetDir ??= await getExternalStorageDirectory();
          }
        }
        targetDir ??= await getApplicationDocumentsDirectory();

        final file = File('${targetDir.path}/$filename');
        await file.writeAsBytes(bytes, flush: true);
        savedPath = file.path;
      }

      Fluttertoast.showToast(msg: 'Receipt saved to Download folder');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to save PDF: $e');
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
          Text(_money(amount), style: style),
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReceiptContent({required bool showImages}) {
    final subtotal = _calcSubtotal();
    final paymentStatus = _paymentStatus(widget.paymentMethod);
    final trackingNumber = _trackingNumberLabel();

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
                child: Image.asset(
                  _logoAssetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.store_rounded,
                    size: 40,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.paymentMethod == 'card'
                    ? 'Payment Successful'
                    : 'Order Placed',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
        const SizedBox(height: 18),
        _sectionCard(
          title: 'Order Information',
          children: [
            _infoRow('Receipt Date', _formatDate(widget.createdAt)),
            _infoRow('Payment Method', _paymentLabel(widget.paymentMethod)),
            _infoRow('Payment Status', paymentStatus),
            _infoRow('Code Number of Order', trackingNumber),
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
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Items',
          children: [
            if (widget.items.isEmpty)
              const Text('No items found')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.items.length,
                separatorBuilder: (_, __) => const Divider(height: 20),
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final name = _itemName(item);
                  final qty = _parseInt(item['quantity']);
                  final originalUnitPrice = _parseDouble(item['price']);
                  // final unitPrice = _discountedUnitPrice(item);
                  // final discount = _parseDouble(item['discount']);
                  // final lineTotal = _lineTotal(item);
                  // final originalLineTotal = originalUnitPrice * qty;
                  // final hasDiscount =
                  //     discount > 0 && unitPrice < originalUnitPrice;
                  final double totalPricePerItem = originalUnitPrice * qty;
                  final imageUrl = showImages
                      ? _resolveItemImageUrl(item)
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
                              'Qty: $qty - ${_money(originalUnitPrice)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
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
                            _money(totalPricePerItem),
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
          title: 'Total',
          children: [
            // _amountRow('Subtotal', subtotal),
            _amountRow('Grand Total', widget.total, bold: true),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // const BackgroundColor(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
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
                            ? 'Save Receipt'
                            : 'Save Receipt',
                        style: TextStyle(color: Color(0xFFFFFFFF)),
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
                      child: const Text('Continue Shopping'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
