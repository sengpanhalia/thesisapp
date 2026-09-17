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

/// One title within a reservation.
///
/// A student who checks out three books has one [Reservation] with three of
/// these under it, sharing one code and one trip to the counter.
class ReservationLine {
  const ReservationLine({
    required this.id,
    required this.itemId,
    required this.itemCode,
    required this.titleEn,
    required this.titleKh,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  final int id;
  final int itemId;
  final String itemCode;
  final String titleEn;
  final String titleKh;
  final int quantity;
  final double? unitPrice;
  final double? totalPrice;

  /// The title in the language asked for, falling back to whichever exists —
  /// the same rule [Book] follows, because it is the same catalogue row.
  String title({required bool khmer}) {
    final first = khmer ? titleKh : titleEn;

    if (first.trim().isNotEmpty) return first.trim();

    return (khmer ? titleEn : titleKh).trim();
  }

  String get unitPriceLabel => formatMoney(unitPrice);

  String get totalLabel => formatMoney(totalPrice);

  factory ReservationLine.fromJson(Map<String, dynamic> json) {
    return ReservationLine(
      id: Reservation._int(json['id']) ?? 0,
      itemId: Reservation._int(json['item_id']) ?? 0,
      itemCode: Reservation._text(json['item_code']),
      titleEn: Reservation._text(json['title']),
      titleKh: Reservation._text(json['title_kh']),
      quantity: Reservation._int(json['quantity']) ?? 0,
      unitPrice: Reservation._money(json['unit_price']),
      totalPrice: Reservation._money(json['total_price']),
    );
  }
}

/// One reservation, as `/api/v1/orders.php` returns it.
///
/// A reservation holds copies without selling them: availability drops, stock
/// does not, and the sale is recorded when the student collects.
///
/// An order is a **basket**: one code covering every title the student checked
/// out together, in [lines]. It used to be one title — the app posted the cart
/// a line at a time and a student who bought four books walked to the counter
/// with four codes, which is four things for finance to check for one
/// transaction. The flat [title], [quantity] and [unitPrice] below are the
/// first line and the whole basket's totals, kept because most orders are one
/// title and every screen was written against that shape.
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
    this.lines = const [],
    this.rawPaymentStatus,
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
  final String? rawPaymentStatus;

  /// Every title under this one code.
  ///
  /// Empty only when talking to a server old enough not to send them, in which
  /// case [asLines] rebuilds the single line from the flat fields so no screen
  /// has to handle both shapes.
  final List<ReservationLine> lines;

  /// Mobile orders start as unpaid (PENDING).
  /// Once status shows confirmed (or ready for pickup / collected),
  /// or when payment_status is explicitly PAID, payment is marked as PAID.
  /// Cancelled orders are never paid.
  bool get isPaid {
    if (status == ReservationStatus.cancelled) return false;
    final ps = (rawPaymentStatus ?? '').trim().toUpperCase();
    if (ps == 'PAID' ||
        ps == 'COMPLETED' ||
        ps == 'SUCCESS' ||
        ps == '1' ||
        ps == 'TRUE') {
      return true;
    }
    if (status == ReservationStatus.confirmed ||
        status == ReservationStatus.readyForPickup ||
        status == ReservationStatus.collected) {
      return true;
    }
    return false;
  }

  /// True when this order covers more than one title.
  bool get isBasket => lines.length > 1;

  /// The lines to render, whatever the server sent.
  ///
  /// One place decides it, so a screen never has to ask whether it is looking
  /// at a basket or at the older one-title shape.
  List<ReservationLine> get asLines => lines.isNotEmpty
      ? lines
      : [
          ReservationLine(
            id: id,
            itemId: itemId,
            itemCode: itemCode,
            titleEn: title,
            titleKh: '',
            quantity: quantity,
            unitPrice: unitPrice,
            totalPrice: totalPrice,
          ),
        ];

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
      rawPaymentStatus: _text(
        json['payment_status'] ?? json['paymentStatus'] ?? json['is_paid'],
      ),
      lines: (json['lines'] is List)
          ? (json['lines'] as List)
                .whereType<Map>()
                .map((e) => ReservationLine.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
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
