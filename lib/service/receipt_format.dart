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
  static String paymentLabel(String method) {
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

  /// What the system will have recorded.
  ///
  /// Only a cash sale is booked as PAID. A wallet or card payment is not
  /// settled until the provider confirms it, and this system does not capture
  /// payment at all — so anything else is unpaid until the counter says
  /// otherwise, and the receipt must not claim it is paid.
  static String paymentStatus(String method) {
    return method == 'Cash' ? 'PAID' : 'PENDING';
  }
}
