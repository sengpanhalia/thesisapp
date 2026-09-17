import 'package:thesisapp/util/api_config.dart';

/// How the receipt screen reads an order's values.
///
/// These lived on PdfReceiptHelper, beside the code that drew the receipt as a
/// PDF and saved it to Downloads. The receipt is saved to Photos only now, so
/// the PDF half is gone and what the receipt still uses is kept here.
class ReceiptFormat {
  ReceiptFormat._();

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

    for (final candidate in candidates) {
      final resolved = ApiConfig.resolveImageUrl(candidate?.toString());
      if (resolved != null) return resolved;
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

  /// The four names the API accepts, as the receipt should read them.
  static String paymentLabel(String method, {dynamic lang}) {
    if (lang != null) {
      final key = switch (method.trim().toLowerCase()) {
        'cash' => 'payment_cash',
        'khqr' => 'payment_khqr',
        'bakong' => 'payment_bakong',
        'card' => 'payment_card',
        _ => null,
      };
      if (key != null) {
        if (method.trim().toLowerCase() == 'cash') {
          return '${lang.translate('pay_at_the_counter')}';
        }
        return lang.translate(key);
      }
    }
    switch (method) {
      case 'Cash':
        return 'Cash — pay at the book counter';
      case 'KHQR':
        return 'KHQR';
      case 'Bakong':
        return 'Bakong';
      case 'Card':
        return 'Card';
      default:
        return method;
    }
  }

  /// When ordered from mobile, orders start as PENDING payment.
  /// Only after payment confirmation (e.g. counter marks it COLLECTED, or backend
  /// confirms payment as PAID) does it change to PAID.
  /// Cancelled orders are recorded as CANCELLED.
  static String paymentStatus(
    String method, {
    String? orderStatus,
    String? rawPaymentStatus,
    bool? isPaid,
  }) {
    final status = (orderStatus ?? '').trim().toUpperCase();
    if (status == 'CANCELLED' || status == 'CANCEL') {
      return 'CANCELLED';
    }
    if (isPaid == true) {
      return 'PAID';
    }
    final pStatus = (rawPaymentStatus ?? '').trim().toUpperCase();
    if (pStatus == 'PAID' ||
        pStatus == 'COMPLETED' ||
        pStatus == 'SUCCESS' ||
        pStatus == '1' ||
        pStatus == 'TRUE') {
      return 'PAID';
    }
    if (status == 'CONFIRMED' ||
        status == 'READY_FOR_PICKUP' ||
        status == 'READY' ||
        status == 'COLLECTED') {
      return 'PAID';
    }
    return 'PENDING';
  }
}
