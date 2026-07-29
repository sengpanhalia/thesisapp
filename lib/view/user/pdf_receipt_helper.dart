import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/util/api_config.dart';

class PdfReceiptHelper {
  static const String appName = 'សាកលវិទ្យាល័យ សៅស៍អ៊ីសថ៍អេយសៀ';
  static const String logoAssetPath = 'assets/logo_app.png';
  static const MethodChannel fileSaverChannel = MethodChannel(
    'haroteybookstoresystem/file_saver',
  );
  static const double pdfReceiptWidth = 595;
  static const double pdfHorizontalPadding = 16;

  final BuildContext context;
  final int orderId;
  final List<Map<String, dynamic>> items;
  final double total;
  final String paymentMethod;
  final DateTime createdAt;
  final String? resolvedTrackingNumber;
  final ScreenshotController screenshotController;
  final String? customerName;
  final String? customerGender;
  final String? customerDob;
  final String? customerPhone;

  PdfReceiptHelper({
    required this.context,
    required this.orderId,
    required this.items,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
    required this.resolvedTrackingNumber,
    required this.screenshotController,
    this.customerName,
    this.customerGender,
    this.customerDob,
    this.customerPhone,
  });

  // ─── Static Helpers (shared with order_success.dart) ───────────────────────

  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int parseInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  static String money(double value) => '\$${value.toStringAsFixed(2)}';

  static String itemName(Map<String, dynamic> item) {
    return (item['name'] ??
            item['product_name'] ??
            item['productName'] ??
            'Item')
        .toString();
  }

  static String? resolveItemImageUrl(Map<String, dynamic> item) {
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
      if (lower == 'null' || lower == 'none' || lower == 'undefined') continue;
      if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
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

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  static String paymentLabel(String method) {
    switch (method) {
      case 'card':
        return 'KHQR Payment';
      case 'cash_on_delivery':
        return 'pay at store';
      default:
        return method;
    }
  }

  static String paymentStatus(String method) {
    return method == 'card' ? 'Paid' : 'pay at store';
  }

  static double discountedUnitPrice(Map<String, dynamic> item) {
    final price = parseDouble(item['price']);
    final discount = parseDouble(item['discount']);
    if (discount <= 0) return price;
    return price * (1 - (discount / 100));
  }

  static double lineTotal(Map<String, dynamic> item) {
    final qty = parseInt(item['quantity']);
    return discountedUnitPrice(item) * qty;
  }

  static double calcSubtotal(List<Map<String, dynamic>> items) {
    double subtotal = 0.0;
    for (final item in items) {
      subtotal += lineTotal(item);
    }
    return subtotal;
  }

  // ─── PDF Widget Helpers ──────────────────────────────────────────────────────

  Widget _infoLine(String label, String value, String fontFamily) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontFamily: fontFamily, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PDF Measurement ────────────────────────────────────────────────────────

  double _measurePdfTextHeight(
    String text,
    TextStyle style,
    double maxWidth,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter.height;
  }

  double estimatePdfReceiptHeight() {
    final lang = AppLocalizations.of(context)!;
    final fontFamily = getFontFamily(context);
    final contentWidth = pdfReceiptWidth - (pdfHorizontalPadding * 2);
    const totalFlex = 7.0;
    final nameCellWidth = (contentWidth * 3 / totalFlex) - 16;
    final qtyCellWidth = (contentWidth * 1 / totalFlex) - 16;
    final amountCellWidth = (contentWidth * 1.5 / totalFlex) - 16;

    final titleStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
    final infoStyle = TextStyle(fontFamily: fontFamily, fontSize: 11);
    final tableHeaderStyle = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.bold,
      fontSize: 11,
    );
    final tableBodyStyle = TextStyle(fontFamily: fontFamily, fontSize: 10);
    final grandTotalStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    double height = 16; // vertical padding (8 top + 8 bottom)
    height += 50; // Logo & header height
    height += 16 + 16 + 8; // SizedBox 16, Divider 16, SizedBox 8

    // Customer Info Section
    height += _measurePdfTextHeight('ព័ត៌មានអតិថិជន', titleStyle, contentWidth);
    height += 6;
    height += _measurePdfTextHeight('ឈ្មោះ: ${customerName ?? ''}', infoStyle, contentWidth) + 4;
    height += _measurePdfTextHeight('ភេទ: ${customerGender ?? ''}', infoStyle, contentWidth) + 4;
    height += _measurePdfTextHeight('ថ្ងៃ ខែ ឆ្នាំកំណើត: ${customerDob ?? ''}', infoStyle, contentWidth) + 4;
    height += _measurePdfTextHeight('លេខទូរសព្ទ: ${customerPhone ?? ''}', infoStyle, contentWidth) + 4;
    height += 12 + 16 + 8; // SizedBox 12, Divider 16, SizedBox 8

    // Order Information Section
    height += _measurePdfTextHeight(
      lang.translate('order information'),
      titleStyle,
      contentWidth,
    );
    height += 6;
    height += _measurePdfTextHeight(
      '${lang.translate('payment method')}: ${paymentLabel(paymentMethod)}',
      infoStyle,
      contentWidth,
    );
    height += _measurePdfTextHeight(
      '${lang.translate('payment status')}: ${paymentStatus(paymentMethod)}',
      infoStyle,
      contentWidth,
    );
    height += _measurePdfTextHeight(
      '${lang.translate('code number of order')}: ${resolvedTrackingNumber ?? 'Pending assignment'}',
      infoStyle,
      contentWidth,
    );
    height += 16;

    // Items Section
    height += _measurePdfTextHeight(
      lang.translate('items'),
      titleStyle,
      contentWidth,
    );
    height += 8;

    final headerRowHeight =
        [
          _measurePdfTextHeight(
            lang.translate('items'),
            tableHeaderStyle,
            nameCellWidth,
          ),
          _measurePdfTextHeight(
            lang.translate('qty'),
            tableHeaderStyle,
            qtyCellWidth,
          ),
          _measurePdfTextHeight(
            lang.translate('price'),
            tableHeaderStyle,
            amountCellWidth,
          ),
          _measurePdfTextHeight(
            lang.translate('total'),
            tableHeaderStyle,
            amountCellWidth,
          ),
        ].reduce((a, b) => a > b ? a : b) +
        12;
    height += headerRowHeight;

    for (final item in items) {
      final qty = parseInt(item['quantity']);
      final unit = discountedUnitPrice(item);
      final lineTotalVal = lineTotal(item);
      final rowHeight =
          [
            _measurePdfTextHeight(
              itemName(item),
              tableBodyStyle,
              nameCellWidth,
            ),
            _measurePdfTextHeight('$qty', tableBodyStyle, qtyCellWidth),
            _measurePdfTextHeight(
              money(unit),
              tableBodyStyle,
              amountCellWidth,
            ),
            _measurePdfTextHeight(
              money(lineTotalVal),
              tableBodyStyle,
              amountCellWidth,
            ),
          ].reduce((a, b) => a > b ? a : b) +
          12;
      height += rowHeight;
    }

    height += 16 + 16 + 4;
    height += _measurePdfTextHeight(
      '${lang.translate('subtotal')}: ${money(calcSubtotal(items))}',
      infoStyle,
      contentWidth,
    );
    height += 4;
    height += _measurePdfTextHeight(
      '${lang.translate('grand total')}: ${money(total)}',
      grandTotalStyle,
      contentWidth,
    );
    height += 24;
    height += _measurePdfTextHeight(
      lang.translate('thank you for shopping with us!'),
      infoStyle,
      contentWidth,
    );

    // Signature section
    height += 32 + 40 + 4 + 14 + 12;

    // Safety margin to prevent overflow stripes
    height += 30;

    return height.ceilToDouble();
  }

  // ─── PDF Widget ─────────────────────────────────────────────────────────────

  Widget buildPdfReceiptWidget() {
    final lang = AppLocalizations.of(context)!;
    final fontFamily = getFontFamilyMool1(context);
    final subtotal = calcSubtotal(items);
    final paymentStatusLabel = paymentStatus(paymentMethod);
    final trackingNumber = resolvedTrackingNumber;

    return Container(
      width: pdfReceiptWidth,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        logoAssetPath,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appName,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'University of South-East Asia',
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatDate(createdAt),
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(thickness: 1, color: Colors.grey),
          const SizedBox(height: 8),
          // ─── Customer Info ───────────────────────────────────────────────
          Text(
            'ព័ត៌មានអតិថិជន',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          _infoLine('ឈ្មោះ', customerName ?? '', fontFamily),
          // _infoLine('ភេទ', customerGender ?? '', fontFamily),
          _infoLine('ថ្ងៃ ខែ ឆ្នាំកំណើត', customerDob ?? '', fontFamily),
          _infoLine('លេខទូរសព្ទ', customerPhone ?? '', fontFamily),
          const SizedBox(height: 12),
          const Divider(thickness: 1, color: Colors.grey),
          const SizedBox(height: 8),
          // ─── Order Info ──────────────────────────────────────────────────
          Text(
            lang.translate('order information'),
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${lang.translate('payment method')}: ${paymentLabel(paymentMethod)}',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
          Text(
            '${lang.translate('payment status')}: $paymentStatusLabel',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
          Text(
            '${lang.translate('code number of order')}: ${trackingNumber ?? 'Pending assignment'}',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            lang.translate('items'),
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.all(color: Colors.grey.shade400),
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade200),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(
                      lang.translate('items'),
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(
                      lang.translate('qty'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(
                      lang.translate('price'),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(
                      lang.translate('total'),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              ...items.map((item) {
                final name = itemName(item);
                final qty = parseInt(item['quantity']);
                final unit = discountedUnitPrice(item);
                final lineTotalVal = lineTotal(item);
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Text(
                        name,
                        style: TextStyle(fontFamily: fontFamily, fontSize: 10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Text(
                        '$qty',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: fontFamily, fontSize: 10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Text(
                        money(unit),
                        textAlign: TextAlign.right,
                        style: TextStyle(fontFamily: fontFamily, fontSize: 10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Text(
                        money(lineTotalVal),
                        textAlign: TextAlign.right,
                        style: TextStyle(fontFamily: fontFamily, fontSize: 10),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(thickness: 1, color: Colors.grey),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${lang.translate('subtotal')}: ${money(subtotal)}',
                    style: TextStyle(fontFamily: fontFamily, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lang.translate('grand total')}: ${money(total)}',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 45),
          // ─── Signature Section ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 50,
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ហត្ថលេខាអតិថិជន',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 10,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 80),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 50,
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ហត្ថលេខាបុគ្គលិក',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 10,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // const SizedBox(height: 12),
          const SizedBox(height: 24),
          Text(
            lang.translate('thank you for shopping with us!'),
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Capture & Build PDF ────────────────────────────────────────────────────

  Future<Uint8List> captureReceiptImage(Size targetSize) async {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final receiptWidget = SizedBox(
      width: targetSize.width,
      child: buildPdfReceiptWidget(),
    );

    final bytes = await screenshotController.captureFromWidget(
      MediaQuery(
        data: mediaQuery.copyWith(
          padding: EdgeInsets.zero,
          viewInsets: EdgeInsets.zero,
        ),
        child: Theme(
          data: theme,
          child: Material(color: Colors.white, child: receiptWidget),
        ),
      ),
      pixelRatio: 3.0,
      targetSize: targetSize,
    );

    return bytes;
  }

  String receiptFileTimestamp(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${value.year}${twoDigits(value.month)}${twoDigits(value.day)}_${twoDigits(value.hour)}${twoDigits(value.minute)}${twoDigits(value.second)}';
  }

  Future<Uint8List> buildReceiptPdfBytes() async {
    final receiptSize = Size(pdfReceiptWidth, estimatePdfReceiptHeight());
    final imageBytes = await captureReceiptImage(receiptSize);
    final pdfImage = pw.MemoryImage(imageBytes);

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) => pw.Align(
          alignment: pw.Alignment.topCenter,
          child: pw.Image(
            pdfImage,
            width: ctx.page.pageFormat.availableWidth,
          ),
        ),
      ),
    );

    return doc.save();
  }

  // ─── Save PDF ────────────────────────────────────────────────────────────────

  Future<void> saveReceiptPdf() async {
    try {
      final bytes = await buildReceiptPdfBytes();
      final filename =
          'receipt_order_${orderId}_${receiptFileTimestamp(DateTime.now())}.pdf';
      String? savedPath;

      if (Platform.isAndroid) {
        try {
          savedPath = await fileSaverChannel.invokeMethod<String>(
            'savePdfToDownloads',
            {'fileName': filename, 'bytes': bytes},
          );
        } catch (_) {
          // Native plugin not available; fall back below
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
    }
  }
}
