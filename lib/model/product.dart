class Product {
  final int id;
  final String name;
  final String description;
  final String price;
  final String? image;
  final String author;
  final String category;    // text name (kept for display)
  final int categoryId;     // FK: categories.id
  final String pages;
  final String language;
  final String year;
  final int stockQuantity;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    this.author = '',
    this.category = '',
    this.categoryId = 0,
    this.pages = '',
    this.language = '',
    this.year = '',
    this.stockQuantity = 0,
  });

  bool get isOutOfStock => stockQuantity <= 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    int id;
    if (json['id'] is int) {
      id = json['id'];
    } else {
      id = int.tryParse(json['id']?.toString() ?? '') ?? 0;
    }

    final stockQuantity =
        int.tryParse(
          json['stock_quantity']?.toString() ??
              json['stockQuantity']?.toString() ??
              '0',
        ) ??
        0;

    return Product(
      id: id,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      image: json['image']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      category: json['category_name']?.toString() ?? '',
      categoryId: int.tryParse(
        (json['category_id'])?.toString() ?? '0',
      ) ?? 0,
      pages: json['page']?.toString() ?? '',
      language: json['language']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      stockQuantity: stockQuantity,
    );
  }
}
