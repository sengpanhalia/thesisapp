/// A book category, as `GET /api/v1/categories.php` returns it.
///
/// These are the catalogue's real categories — original copies, black-and-white
/// photocopies, printed, colour — from `book_stock_categories`, not the empty
/// `year_level` the app used to group by. `bookCount` counts only the books a
/// student may actually buy, so a tile that says eleven opens onto eleven.
///
/// Both names always arrive: many categories carry only a Khmer name, so `name`
/// falls back to it on the server. [nameFor] picks the one for the language the
/// app is in.
class BookCategory {
  const BookCategory({
    required this.id,
    required this.name,
    required this.nameKh,
    required this.bookCount,
  });

  final int id;
  final String name;
  final String nameKh;
  final int bookCount;

  /// The name in the language asked for, falling back to whichever exists.
  String nameFor({required bool khmer}) {
    final kh = nameKh.trim();
    final en = name.trim();

    return khmer ? (kh.isNotEmpty ? kh : en) : (en.isNotEmpty ? en : kh);
  }

  factory BookCategory.fromJson(Map<String, dynamic> json) {
    return BookCategory(
      id: _int(json['id']) ?? 0,
      name: _text(json['name']),
      nameKh: _text(json['name_kh']),
      bookCount: _int(json['book_count']) ?? 0,
    );
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';

  static int? _int(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }
}
