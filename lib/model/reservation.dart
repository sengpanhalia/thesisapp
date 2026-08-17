import 'package:thesisapp/model/book.dart' show formatMoney;

/// Where a reservation has got to.
///
/// The counter moves it forward on the web screens; the app only reads it.
/// `READY_FOR_PICKUP` is the one that matters to a student — that is the cue
/// to go to the book counter.
enum ReservationStatus {
  pending('PENDING'),
  confirmed('CONFIRMED'),
  readyForPickup('READY_FOR_PICKUP'),
  collected('COLLECTED'),
  cancelled('CANCELLED'),
  unknown('');

  const ReservationStatus(this.wireName);

  final String wireName;

  static ReservationStatus parse(String? value) {
    final raw = (value ?? '').trim().toUpperCase();

    return ReservationStatus.values.firstWhere(
      (status) => status.wireName == raw,
      orElse: () => ReservationStatus.unknown,
    );
  }

  /// A student may still call one off up to the moment it is handed over.
  bool get isCancellable =>
      this == ReservationStatus.pending ||
      this == ReservationStatus.confirmed ||
      this == ReservationStatus.readyForPickup;

  bool get isFinished =>
      this == ReservationStatus.collected || this == ReservationStatus.cancelled;

  /// The key `assets/en.json` and `assets/km.json` translate this status with.
  String get translationKey => switch (this) {
    ReservationStatus.pending => 'order_status_pending',
    ReservationStatus.confirmed => 'order_status_confirmed',
    ReservationStatus.readyForPickup => 'order_status_ready',
    ReservationStatus.collected => 'order_status_collected',
    ReservationStatus.cancelled => 'order_status_cancelled',
    ReservationStatus.unknown => 'order_status_unknown',
  };
}

/// One reservation, as `/api/v1/orders.php` returns it.
///
/// A reservation holds copies without selling them: availability drops, stock
/// does not, and the sale is recorded when the student collects. One
/// reservation covers one title — a basket of three books is three of these.
class Reservation {
  const Reservation({
    required this.id,
    required this.code,
    required this.status,
    required this.studentId,
    required this.studentName,
    required this.itemId,
    required this.itemCode,
    required this.title,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.paymentMethod,
    required this.note,
    required this.createdAt,
  });

  final int id;

  /// `ORD-000001` — what the student quotes at the counter.
  final String code;

  final ReservationStatus status;
  final String studentId;
  final String studentName;
  final int itemId;
  final String itemCode;
  final String title;
  final int quantity;

  final double? unitPrice;
  final double? totalPrice;

  final String paymentMethod;
  final String note;
  final DateTime? createdAt;

  /// Anything but cash is unsettled until the provider confirms it, and this
  /// system does not capture payment. Never show it as paid.
  bool get isPaid => paymentMethod.toLowerCase() == 'cash';

  String get totalLabel => formatMoney(totalPrice);

  String get unitPriceLabel => formatMoney(unitPrice);

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: _int(json['id']) ?? 0,
      code: _text(json['code']),
      status: ReservationStatus.parse(json['status']?.toString()),
      studentId: _text(json['student_id']),
      studentName: _text(json['student_name']),
      itemId: _int(json['item_id']) ?? 0,
      itemCode: _text(json['item_code']),
      title: _text(json['title']),
      quantity: _int(json['quantity']) ?? 0,
      unitPrice: _money(json['unit_price']),
      totalPrice: _money(json['total_price']),
      paymentMethod: _text(json['payment_method']),
      note: _text(json['note']),
      createdAt: _dateTime(json['created_at']),
    );
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';

  static double? _money(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString());
  }

  static int? _int(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }

  /// `2026-08-06 06:45:41` — a MySQL datetime, which is a space short of ISO.
  static DateTime? _dateTime(dynamic value) {
    final raw = (value?.toString() ?? '').trim();

    if (raw.isEmpty) return null;

    return DateTime.tryParse(raw.contains('T') ? raw : raw.replaceFirst(' ', 'T'));
  }
}
