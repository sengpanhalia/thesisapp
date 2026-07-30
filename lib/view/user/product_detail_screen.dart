import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:thesisapp/component/card_product.dart';
import 'package:thesisapp/component/cart_provider.dart';
import 'package:thesisapp/component/component_app.dart';
import 'package:thesisapp/component/full_image_view.dart';
import 'package:thesisapp/component/navigation_provider.dart';
import 'package:thesisapp/component/product_spec_row.dart';
import 'package:thesisapp/component/recommended_products_section.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/model/product.dart';
import 'package:thesisapp/provider/auth_provider.dart';
import 'package:thesisapp/theme_color.dart';
import 'package:thesisapp/util/api_config.dart';
import 'package:thesisapp/view/user/product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final String baseUrl;
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.baseUrl,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const String baseUrl = ApiConfig.baseUrl;
  List<Product> relatedProducts = [];
  List<Product> recommendedProducts = [];
  bool _isLoadingRelatedProducts = true;
  bool _isLoadingRecommendedProducts = true;

  @override
  void initState() {
    super.initState();
    _fetchProductsData();
  }

  Future<void> _fetchProductsData() async {
    final url = Uri.parse('$baseUrl/get_products.php');

    try {
      final response = await http.get(url);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'success') {
          final List productsJson = (data['products'] as List?) ?? const [];
          final allOtherProducts = productsJson
              .whereType<Map<String, dynamic>>()
              .map(Product.fromJson)
              .where((product) => product.id != widget.product.id)
              .toList();

          final currentCategory = widget.product.category.trim().toLowerCase();
          final currentAuthor = widget.product.author.trim().toLowerCase();

          final sameCategory = currentCategory.isEmpty
              ? <Product>[]
              : allOtherProducts
                  .where(
                    (product) =>
                        product.category.trim().toLowerCase() ==
                        currentCategory,
                  )
                  .toList();

          final sameAuthor = currentAuthor.isEmpty
              ? <Product>[]
              : allOtherProducts
                  .where(
                    (product) =>
                        product.author.trim().toLowerCase() == currentAuthor,
                  )
                  .toList();

          final related = [
            ...sameCategory,
            ...sameAuthor.where(
              (product) => !sameCategory.any((item) => item.id == product.id),
            ),
            ...allOtherProducts.where(
              (product) =>
                  !sameCategory.any((item) => item.id == product.id) &&
                  !sameAuthor.any((item) => item.id == product.id),
            ),
          ].take(10).toList();

          // Prepare recommended products (random 10 from all other products)
          final recommended = List<Product>.from(allOtherProducts)
            ..shuffle(Random());
          final randomTen = recommended.take(10).toList();

          setState(() {
            relatedProducts = related;
            recommendedProducts = randomTen;
            _isLoadingRelatedProducts = false;
            _isLoadingRecommendedProducts = false;
          });
          return;
        }
      }
    } catch (_) {
      // Ignore error and fall back to empty states
    }

    if (!mounted) return;
    setState(() {
      relatedProducts = [];
      recommendedProducts = [];
      _isLoadingRelatedProducts = false;
      _isLoadingRecommendedProducts = false;
    });
  }

  Future<bool> _addToCart(BuildContext context, {int quantity = 1}) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user == null) {
      Fluttertoast.showToast(msg: 'Please log in first');
      return false;
    }
    if (widget.product.isOutOfStock) {
      Fluttertoast.showToast(msg: 'This product is out of stock');
      return false;
    }

    final url = Uri.parse('${widget.baseUrl}/add_to_cart.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.student_id,
          'student_id': user.student_id,
          'product_id': widget.product.id,
          'quantity': quantity,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          if (!context.mounted) return false;
          final cartProvider = context.read<CartProvider>();
          await cartProvider.fetchCart();
          final lang = AppLocalizations.of(context)!;
          Fluttertoast.showToast(
            msg: '${lang.translate('added to cart')} (x$quantity)',
            backgroundColor: Colors.green,
          );
          return true;
        } else {
          Fluttertoast.showToast(msg: data['message'] ?? 'Failed');
        }
      } else {
        Fluttertoast.showToast(msg: 'Failed to add to cart');
      }
    } catch (e) {
      debugPrint('Add to cart error: $e');
    }
    return false;
  }

  Future<void> _buyNow({int quantity = 1}) async {
    final navigationProvider = context.read<NavigationProvider>();
    final added = await _addToCart(context, quantity: quantity);
    if (!added || !mounted) return;
    navigationProvider.setIndex(2);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<int?> _showQuantityDialog(
    BuildContext context, {
    required int maxQuantity,
  }) {
    final lang = AppLocalizations.of(context)!;
    if (maxQuantity <= 0) {
      Fluttertoast.showToast(msg: 'This product is out of stock');
      return Future.value(null);
    }

    int quantity = 1;
    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                lang.translate('select quantity'),
                style: TextStyle(
                  fontFamily: getFontFamily(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: TitleColor,
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lang.translate('how many would you like to add'),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${lang.translate('available stock')}: $maxQuantity',
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: GreenColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 10,
                    children: [
                      IconButton(
                        onPressed: quantity > 1
                            ? () => setState(() => quantity -= 1)
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                        color: TextColor,
                      ),
                      Container(
                        width: 64,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: CardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.brown[200] ?? Colors.brown,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          quantity.toString(),
                          style: TextStyle(
                            fontFamily: getFontFamilyMool1(context),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: TitleColor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: quantity < maxQuantity
                            ? () => setState(() => quantity += 1)
                            : null,
                        icon: const Icon(Icons.add_rounded),
                        color: TextColor,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    lang.translate('cancel'),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TitleColor,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, quantity),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GText1,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    lang.translate('confirm'),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: GBackground1,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openFullImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FullImageView(imageUrl: imageUrl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double basePrice = double.tryParse(widget.product.price) ?? 0.0;
    final String author = widget.product.author.trim();
    final String pages = widget.product.pages.trim();
    final String language = widget.product.language.trim();
    final String year = widget.product.year.trim();
    final int stockQuantity = widget.product.stockQuantity;
    final bool isOutOfStock = widget.product.isOutOfStock;
    final Color stockColor = isOutOfStock
        ? Colors.redAccent
        : const Color(0xFF2E7D32);
    final String? imageUrl = widget.product.image!.startsWith('http')
        ? widget.product.image
        : '${widget.baseUrl}/uploads/products/${widget.product.image}';
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang.translate('product details'),
          style: TextStyle(
            fontFamily: getFontFamilyMool1(context),
            fontSize: 24,
            color: TitleColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
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
            child: Padding(
              padding: const EdgeInsets.only(
                left: MgPd20,
                right: MgPd20,
                top: MgPd20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(MgPd20),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: CachedNetworkImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: GBackground1,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.broken_image_rounded, size: 48),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: Material(
                            color: GBackground1,
                            elevation: 6,
                            borderRadius: BorderRadius.circular(MgPd10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(MgPd10),
                              onTap: () => _openFullImage(imageUrl),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 6),
                                    Text(
                                      lang.translate('view image'),
                                      style: TextStyle(
                                        fontFamily: getFontFamily(context),
                                        fontSize: 12,
                                        color: TextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Height10),
                  Text(
                    widget.product.name,
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: TitleColor,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: Height5),
                  Text(
                    '${lang.translate('author')}: $author',
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: 14,
                      color: TextColor,
                    ),
                  ),
                  SizedBox(height: Height10),
                  Text(
                    '៛ ${basePrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: 24,
                      color: GText1,
                    ),
                  ),
                  SizedBox(height: Height15),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: stockColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isOutOfStock
                          ? lang.translate('out of stock')
                          : '${lang.translate('in stock')}: $stockQuantity',
                      style: TextStyle(
                        fontFamily: getFontFamily(context),
                        fontSize: 12,
                        color: stockColor,
                      ),
                    ),
                  ),
                  SizedBox(height: Height15),

                  // Spec item row (pages, language, year)
                  ProductSpecRow(
                    pages: pages,
                    language: language,
                    year: year,
                    pagesLabel: lang.translate('pages'),
                    languageLabel: lang.translate('language'),
                    yearLabel: lang.translate('year'),
                  ),

                  SizedBox(height: Height20),
                  Text(
                    lang.translate('product details'),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: GText1,
                    ),
                  ),
                  SizedBox(height: Height10),
                  Container(width: 90, height: 2, color: GText1),
                  SizedBox(height: Height15),
                  Text(
                    widget.product.description,
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: 14,
                      color: TextColor,
                      height: LineHegiht,
                      letterSpacing: 0.7,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  SizedBox(height: Height20),

                  // Related Books Section
                  Text(
                    lang.translate('related books'),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: GText1,
                    ),
                  ),
                  SizedBox(height: Height10),
                  if (_isLoadingRelatedProducts)
                    const SizedBox(
                      height: 260,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (relatedProducts.isEmpty)
                    SizedBox(
                      height: 80,
                      child: Center(
                        child: Text(
                          lang.translate('no related books'),
                          style: TextStyle(
                            fontFamily: getFontFamily(context),
                            fontSize: 14,
                            color: TextSoftColor,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 260,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: relatedProducts.length,
                        itemBuilder: (context, index) {
                          final product = relatedProducts[index];
                          final productImage = (product.image ?? '').trim();
                          final imageUrl = productImage.startsWith('http')
                              ? productImage
                              : '$baseUrl/uploads/products/$productImage';

                          return SizedBox(
                            width: 180,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: BuildCardProduct(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailScreen(
                                        product: product,
                                        baseUrl: widget.baseUrl,
                                      ),
                                    ),
                                  );
                                },
                                productName: product.name,
                                productPrice: product.price,
                                imageUrl: imageUrl,
                                productImage: productImage,
                                author: product.author,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Recommended Products Section
                  if (!_isLoadingRecommendedProducts && recommendedProducts.isNotEmpty) ...[
                    const SizedBox(height: Height20),
                    RecommendedProductsSection(
                      title: lang.translate('recommended products'),
                      products: recommendedProducts,
                      baseUrl: widget.baseUrl,
                      onSeeAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProductScreen(),
                          ),
                        );
                      },
                      onProductTap: (product) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                              product: product,
                              baseUrl: widget.baseUrl,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(MgPd20, 12, MgPd20, 12),
          decoration: const BoxDecoration(
            color: CardColor,
            border: Border(top: BorderSide(color: StrokeSearchBar)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isOutOfStock
                      ? null
                      : () async {
                          final quantity = await _showQuantityDialog(
                            context,
                            maxQuantity: stockQuantity,
                          );
                          if (quantity == null) return;
                          await _addToCart(context, quantity: quantity);
                        },
                  child: Text(
                    lang.translate('add to cart'),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: TitleColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isOutOfStock
                      ? null
                      : () async {
                          final quantity = await _showQuantityDialog(
                            context,
                            maxQuantity: stockQuantity,
                          );
                          if (quantity == null) return;
                          await _buyNow(quantity: quantity);
                        },
                  child: Text(
                    lang.translate('buy now'),
                    style: TextStyle(
                      fontFamily: getFontFamily(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: GBackground3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
