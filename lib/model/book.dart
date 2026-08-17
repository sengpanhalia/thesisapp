/// A book a student may buy, as `GET /api/v1/books.php` returns it.
///
/// The API sends raw numbers — `"price": 10` and `"price": 10.5` both occur,
/// because it rounds to two places and JSON drops a trailing `.0`. Formatting
/// belongs here, not on the server, so the money is parsed as a number and
/// turned into text only when it is shown.
///
/// A missing number stays missing. `price` and `availableQty` are null when
/// the catalogue does not say, and null is not zero: a book with no recorded
/// price is not free, and a book whose availability is unknown is not sold out.
class Book {
  const Book({
    required this.id,
    required this.code,
    required this.title,
    required this.titleKh,
    required this.author,
    required this.publisher,
    required this.isbn,
    required this.yearLevel,
    required this.unit,
    required this.price,
    required this.availableQty,
    required this.imageUrl,
  });

  final int id;
  final String code;
  final String title;
  final String titleKh;
  final String author;
  final String publisher;
  final String isbn;

  /// `Year 1`…`Year 4`, `All`, or empty when the catalogue has not said.
  final String yearLevel;

  /// The counting unit — `ក្បាល`, `pcs`. Shown beside a quantity.
  final String unit;

  final double? price;
  final int? availableQty;

  /// Null whenever the catalogue holds no picture, which the app must show as
  /// a placeholder rather than as a broken image.
  final String? imageUrl;

  bool get isOutOfStock => availableQty != null && availableQty! <= 0;

  bool get hasPrice => price != null;

  /// The title in the language asked for, falling back to whichever exists.
  String titleFor({required bool khmer}) {
    final kh = titleKh.trim();
    final en = title.trim();

    return khmer ? (kh.isNotEmpty ? kh : en) : (en.isNotEmpty ? en : kh);
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: _int(json['id']) ?? 0,
      code: _text(json['code']),
      title: _text(json['title']),
      titleKh: _text(json['title_kh']),
      author: _text(json['author']),
      publisher: _text(json['publisher']),
      isbn: _text(json['isbn']),
      yearLevel: _text(json['year_level']),
      unit: _text(json['unit']),
      price: _money(json['price']),
      availableQty: _int(json['available_qty']),
      imageUrl: _nullableText(json['image_url']),
    );
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';

  static String? _nullableText(dynamic value) {
    final text = value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
  }

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
}

/// `$12.50`, or a dash when the catalogue has no price for the row.
String formatMoney(double? amount, {String placeholder = '—'}) {
  if (amount == null) return placeholder;

  return '\$${amount.toStringAsFixed(2)}';
}
